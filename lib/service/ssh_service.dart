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

  Future<String> run(String s) async {
    return await runCommand(s);
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

  Future<void> createDirIfNotExists(String path) async {
    try {
      await sftp!.stat(path);
    } catch (_) {
      await _createRemoteDirs(path);
    }
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
    int lastUpdate = 0;

    try {
      final stream = file.openRead();

      await for (final chunk in stream) {
        if (isCancelled()) {
          throw Exception("Upload cancelled");
        }

        final data = Uint8List.fromList(chunk);

        await remoteFile.write(Stream.value(data), offset: sent);

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
    } catch (e) {
      try {
        await sftp!.remove(remotePath);
      } catch (_) {}

      rethrow;
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
        // ignore if exists
      }
    }
  }

  Future<void> uploadFolder({
    required String localDirPath,
    required String remoteDirPath,
    required Function(double progress) onProgress,
    required Function() isCancelled,
  }) async {
    final directory = Directory(localDirPath + (localDirPath.endsWith("/") ? "" : "/"));
    final entities = await directory.list(recursive: true).toList();

    print("This is entities: ${entities}");

    print("Checking local directory: $localDirPath");

    if (!await directory.exists()) {
      throw Exception("Local directory does not exist");
    }

    await _createRemoteDirs(remoteDirPath);

    print(remoteDirPath);
    print(localDirPath);

    var files = entities.whereType<File>().toList();
    print("This is files: ${files}");

    print("Total entities: ${entities}");
    
    print("Found ${files.length} files to upload");
    print(files);

    if (files.isEmpty) {
      return; // folder exists already
    }

    int totalFiles = files.length;
    int completedFiles = 0;

    for (var file in files) {
      print("-----------------------------------------------------------------This is loop");
      if (isCancelled()) {
        throw Exception("Upload cancelled");
      }

      final relativePath = file.path
          .substring(localDirPath.length)
          .replaceAll("\\", "/");

      final remotePath = "$remoteDirPath$relativePath";

      final dirPath = remotePath.substring(0, remotePath.lastIndexOf("/"));

      await _createRemoteDirs(dirPath);

      print("----------------------------------------------------------------------------This is file path to upload PLEASE CHECK THIS: ${file.path}");

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
