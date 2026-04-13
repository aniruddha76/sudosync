import 'dart:typed_data';
import 'dart:async';
import 'package:dartssh2/dartssh2.dart';
import 'dart:io';

class SSHService {
  SSHClient? client;
  SftpClient? sftp;

  Future<void> connect(String ip, String user, String pass) async {
    final socket = await SSHSocket.connect(ip, 22);
    client = SSHClient(socket, username: user, onPasswordRequest: () => pass);
    sftp = await client!.sftp();
  }

  Future<String> runCommand(String command) async {
    final result = await client!.run(command);
    return String.fromCharCodes(result);
  }

  Future<SSHSession> startShell() async {
    return await client!.shell(pty: SSHPtyConfig(width: 80, height: 24));
  }

  Future<List<SftpName>> listDir(String path) async {
    final list = await sftp!.listdir(path);
    return list.where((file) {
      final name = file.filename;
      if (name == "." || name == "..") return false;
      if (name.startsWith(".")) return false;
      return true;
    }).toList();
  }

  Future<String> run(String s) async {
    return await runCommand(s);
  }

  Future<void> downloadFile({
    required String remotePath,
    required String localPath,
    required Function(double progress) onProgress,
    required Function() isCancelled,
  }) async {
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
  }

  Future<void> uploadFile({
    required String localPath,
    required String remotePath,
    required Function(double progress) onProgress,
    required Function() isCancelled,
  }) async {
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

    try {
      final stream = file.openRead().map((chunk) {
        if (isCancelled()) {
          throw Exception("Upload cancelled");
        }

        sent += chunk.length;

        if (totalSize != 0) {
          onProgress(sent / totalSize);
        }

        return Uint8List.fromList(chunk);
      });

      await remoteFile.write(stream);
    } catch (e) {
      // delete partial file if failed or cancelled
      try {
        await sftp!.remove(remotePath);
      } catch (_) {}

      rethrow; // important for UI handling
    } finally {
      await remoteFile.close();
    }
  }

  Future<void> _createRemoteDirs(String path) async {
  final parts = path.split("/");
  String current = "";

  for (final part in parts) {
    if (part.isEmpty) continue;

    current += "/$part";

    try {
      await sftp!.mkdir(current);
    } catch (_) {
    }
  }
}

  Future<void> uploadFolder({
  required String localDirPath,
  required String remoteDirPath,
  required Function(double progress) onProgress,
  required Function() isCancelled,
}) async {
  final directory = Directory(localDirPath);

  if (!await directory.exists()) {
    throw Exception("Local directory does not exist");
  }

  final files = directory
      .listSync(recursive: true)
      .whereType<File>()
      .toList();

  if (files.isEmpty) return;

  int totalFiles = files.length;
  int completedFiles = 0;

  for (final file in files) {
    if (isCancelled()) {
      throw Exception("Upload cancelled");
    }

    final relativePath = file.path
        .replaceFirst(localDirPath, "")
        .replaceAll("\\", "/");

    final remotePath = "$remoteDirPath$relativePath";

    final dirPath = remotePath.substring(0, remotePath.lastIndexOf("/"));

    await _createRemoteDirs(dirPath);

    await uploadFile(
      localPath: file.path,
      remotePath: remotePath,
      onProgress: (_) {},
      isCancelled: isCancelled,
    );

    completedFiles++;
    onProgress(completedFiles / totalFiles);
  }
}
  Future<void> disconnect() async {
    client?.close();
    client = null;
    sftp = null;
  }
}
