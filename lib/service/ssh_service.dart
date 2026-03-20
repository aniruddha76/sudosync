import 'package:dartssh2/dartssh2.dart';

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
    final session = await client!.shell(
      pty: SSHPtyConfig(width: 80, height: 24),
    );

    return session;
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

  Future<Object?> downloadFile(String path) async {
    return null;
  }

  Future<void> disconnect() async {
    client?.close();
    client = null;
    sftp = null;
  }
}
