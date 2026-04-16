import 'dart:typed_data';
import 'dart:async';
import 'package:dartssh2/dartssh2.dart';
import 'dart:io';

class SSHService {
  SSHClient? client;
  SftpClient? sftp;

  Timer? _keepAliveTimer;

  String? _ip;
  String? _user;
  String? _pass;

  bool get isConnected =>
      client != null && !client!.isClosed && sftp != null;

  Future<void> connect(String ip, String user, String pass) async {
    _ip = ip;
    _user = user;
    _pass = pass;

    final socket = await SSHSocket.connect(ip, 22);
    client = SSHClient(socket, username: user, onPasswordRequest: () => pass);
    sftp = await client!.sftp();

    _startKeepAlive();
  }

  Future<void> reconnect() async {
    await disconnect();

    if (_ip == null || _user == null || _pass == null) {
      throw Exception("Missing credentials");
    }

    await connect(_ip!, _user!, _pass!);
  }

  void _startKeepAlive() {
    _keepAliveTimer?.cancel();

    _keepAliveTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        if (client == null || client!.isClosed) {
          timer.cancel();
          return;
        }
        await client!.ping();
      } catch (_) {
        timer.cancel();
      }
    });
  }

  Future<T> _safe<T>(Future<T> Function() fn) async {
    try {
      if (!isConnected) {
        await reconnect();
      }
      return await fn().timeout(const Duration(seconds: 15));
    } catch (_) {
      await reconnect();
      return await fn().timeout(const Duration(seconds: 15));
    }
  }

  Future<String> runCommand(String command) async {
    final result = await _safe(() => client!.run(command));
    return String.fromCharCodes(result);
  }

  Future<String> run(String s) async {
    return await runCommand(s);
  }

  Future<SSHSession> startShell() async {
    return await _safe(() => client!.shell(pty: SSHPtyConfig(width: 80, height: 24)));
  }

  Future<List<SftpName>> listDir(String path) async {
    final list = await _safe(() => sftp!.listdir(path));
    return list.where((file) {
      final name = file.filename;
      if (name == "." || name == "..") return false;
      if (name.startsWith(".")) return false;
      return true;
    }).toList();
  }

  Future<void> downloadFile({
    required String remotePath,
    required String localPath,
    required Function(double progress) onProgress,
    required Function() isCancelled,
  }) async {
    await _safe(() async {
      final remoteFile = await sftp!.open(remotePath);
      final stat = await remoteFile.stat();
      final totalSize = stat.size ?? 0;

      final file = File(localPath);
      final sink = file.openWrite();

      int received = 0;

      await for (final chunk in remoteFile.read()) {
        if (isCancelled()) {
          await sink.close();
          await remoteFile.close();
          if (await file.exists()) {
            await file.delete();
          }
          return;
        }

        received += chunk.length;
        sink.add(chunk);

        if (totalSize != 0) {
          onProgress(received / totalSize);
        }
      }

      await sink.close();
      await remoteFile.close();
    });
  }

  Future<void> createDirIfNotExists(String path) async {
    await _safe(() async {
      try {
        await sftp!.stat(path);
      } catch (_) {
        await _createRemoteDirs(path);
      }
    });
  }

  Future<void> resetSftp() async {
    try {
      sftp?.close();
    } catch (_) {}

    try {
      sftp = await client!.sftp();
    } catch (_) {}
  }

  Future<void> uploadFile({
    required String localPath,
    required String remotePath,
    required Function(double progress) onProgress,
    required Function() isCancelled,
  }) async {
    await _safe(() async {
      final file = File(localPath);
      final totalSize = await file.length();

      final remoteFile = await sftp!.open(
        remotePath,
        mode:
            SftpFileOpenMode.create |
            SftpFileOpenMode.write |
            SftpFileOpenMode.truncate,
      );

      int sent = 0;
      int lastUpdate = 0;

      final controller = StreamController<Uint8List>();

      try {
        final writeFuture = remoteFile.write(controller.stream);
        final stream = file.openRead();

        await for (final chunk in stream) {
          if (isCancelled()) {
            await controller.close();
            await remoteFile.close();
            throw Exception("Upload cancelled");
          }

          final data = Uint8List.fromList(chunk);
          controller.add(data);

          sent += data.length;

          final now = DateTime.now().millisecondsSinceEpoch;

          if (now - lastUpdate > 100) {
            lastUpdate = now;
            if (totalSize != 0) {
              onProgress(sent / totalSize);
            }
          }

          await Future.delayed(const Duration(milliseconds: 1));
        }

        await controller.close();
        await writeFuture.timeout(const Duration(seconds: 30));
      } catch (e) {
        try {
          await controller.close();
        } catch (_) {}

        try {
          await remoteFile.close();
        } catch (_) {}

        try {
          await sftp!.remove(remotePath);
        } catch (_) {}

        await resetSftp();
        rethrow;
      } finally {
        try {
          await remoteFile.close();
        } catch (_) {}
      }
    });
  }

  Future<void> _createRemoteDirs(String path) async {
    final parts = path.split("/");
    String current = "";

    for (final part in parts) {
      if (part.isEmpty) continue;
      current += "/$part";
      try {
        await sftp!.mkdir(current);
      } catch (_) {}
    }
  }

  Future<void> disconnect() async {
    _keepAliveTimer?.cancel();
    try {
      client?.close();
    } catch (_) {}
    client = null;
    sftp = null;
  }
}