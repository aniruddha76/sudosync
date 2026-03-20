import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/ssh_service.dart';
import 'image_viewer.dart';

class FileExplorer extends StatefulWidget {
  final SSHService ssh;

  const FileExplorer({super.key, required this.ssh});

  @override
  State<FileExplorer> createState() => _FileExplorerState();
}

class _FileExplorerState extends State<FileExplorer> {
  List<SftpName> files = [];
  String currentPath = "/home";

  @override
  void initState() {
    super.initState();
    loadFiles(currentPath);
  }

  Future<void> loadFiles(String path) async {
    final list = await widget.ssh.listDir(path);

    setState(() {
      currentPath = path;
      files = list;
    });
  }

  bool isDirectory(SftpName file) {
    return file.longname.startsWith("d");
  }

  bool isImage(String name) {
    final n = name.toLowerCase();
    return n.endsWith(".jpg") || n.endsWith(".png") || n.endsWith(".jpeg");
  }

  IconData getIcon(String name) {
    final lower = name.toLowerCase();

    if (lower.endsWith(".jpg") || lower.endsWith(".png")) {
      return Icons.image;
    }

    if (lower.endsWith(".mp4") || lower.endsWith(".mkv")) {
      return Icons.video_file;
    }

    if (lower.endsWith(".pdf") || lower.endsWith(".txt")) {
      return Icons.description;
    }

    return Icons.insert_drive_file;
  }

  void openItem(SftpName file) {
    final path = "$currentPath/${file.filename}";

    if (isDirectory(file)) {
      loadFiles(path);
      return;
    }

    if (isImage(file.filename)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImageViewer(ssh: widget.ssh, path: path),
        ),
      );
    }
  }

  Future<void> downloadFile(SftpName file) async {
    final path = "$currentPath/${file.filename}";

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Downloading file...")));

    final downloaded = await widget.ssh.downloadFile(path);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Saved to ${(downloaded as dynamic)?.path ?? 'Downloads'}",
        ),
      ),
    );
  }

  Widget deviceCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),

        // decoration: BoxDecoration(
        //   color: Colors.white,
        //   borderRadius: BorderRadius.circular(16),
        // ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 35,
              // color: const Color.fromARGB(255, 219, 215, 215),
              // color: const Color.fromARGB(255, 71, 130, 219),
              color: Color(0xFFB6FF00),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  // fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),

            // const Icon(Icons.chevron_right)
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: currentPath == "/home",
      onPopInvokedWithResult: (didPop, result) async {
        if (currentPath != "/home") {
          // final parent = currentPath.substring(0, currentPath.lastIndexOf("/"));

          // await loadFiles(parent.isEmpty ? "/" : parent);
          final parent = currentPath.substring(0, currentPath.lastIndexOf("/"));
          await loadFiles(parent.isEmpty ? "/" : parent);
        }
      },

      child: Scaffold(
        backgroundColor: Colors.black,

        appBar: AppBar(
          title: Text(
            "My Files",
            style: GoogleFonts.lobsterTwo(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false,
        ),

        body: Padding(
          padding: const EdgeInsets.all(12),

          child: ListView.builder(
            itemCount: files.length,

            itemBuilder: (context, index) {
              final file = files[index];

              return deviceCard(
                title: file.filename,

                icon: isDirectory(file) ? Icons.folder : getIcon(file.filename),

                onTap: () {
                  openItem(file);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
