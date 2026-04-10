import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

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

  double downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    loadFiles(currentPath);
  }

  Future<void> loadFiles(String path) async {
    final list = await widget.ssh.listDir(path);

    list.sort((a, b) {
      if (isDirectory(a) && !isDirectory(b)) return -1;
      if (!isDirectory(a) && isDirectory(b)) return 1;
      return a.filename.compareTo(b.filename);
    });

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
    return n.endsWith(".jpg") ||
        n.endsWith(".jpeg") ||
        n.endsWith(".png") ||
        n.endsWith(".webp");
  }

  bool isVideo(String name) {
    final n = name.toLowerCase();
    return n.endsWith(".mp4") ||
        n.endsWith(".mkv") ||
        n.endsWith(".mov") ||
        n.endsWith(".avi");
  }

  IconData getIcon(String name) {
    final lower = name.toLowerCase();

    if (lower.endsWith(".pdf") || lower.endsWith(".txt")) {
      return Icons.description;
    }

    return Icons.insert_drive_file;
  }

  Future<Uint8List?> getImageThumb(String path) async {
    try {
      final file = await widget.ssh.sftp!.open(path);
      final bytes = await file.readBytes();
      await file.close();
      return bytes;
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List?> getVideoThumb(String path) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = "${tempDir.path}/temp_video";

      final file = await widget.ssh.sftp!.open(path);
      final bytes = await file.readBytes();
      await file.close();

      final local = File(tempPath);
      await local.writeAsBytes(bytes);

      final thumb = await VideoThumbnail.thumbnailData(
        video: tempPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 128,
        quality: 75,
      );

      return thumb;
    } catch (e) {
      return null;
    }
  }

  Widget leadingWidget(SftpName file) {
    final path = "$currentPath/${file.filename}";

    if (isDirectory(file)) {
      return const Icon(Icons.folder, size: 35, color: Color(0xFFB6FF00));
    }

    if (isImage(file.filename)) {
      return FutureBuilder(
        future: getImageThumb(path),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Icon(Icons.image, size: 35, color: Color(0xFFB6FF00));
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.memory(
              snap.data!,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          );
        },
      );
    }

    if (isVideo(file.filename)) {
      return FutureBuilder(
        future: getVideoThumb(path),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Icon(
              Icons.video_file,
              size: 35,
              color: Color(0xFFB6FF00),
            );
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.memory(
              snap.data!,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          );
        },
      );
    }

    return Icon(
      getIcon(file.filename),
      size: 35,
      color: const Color(0xFFB6FF00),
    );
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

  void showFileInfo(SftpName file) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: const Text("File Info", style: TextStyle(color: Colors.white)),
          content: Text(
            "Name: ${file.filename}\n\n"
            "Type: ${isDirectory(file) ? "Folder" : "File"}\n\n"
            "Details:\n${file.longname}",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Future<void> requestPermission() async {
    await Permission.manageExternalStorage.request();
  }

  bool isDownloadCancelled = false;

  Future<void> downloadFile(String remotePath) async {
    double progress = 0;

    late StateSetter setDialogState;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            setDialogState = setState;

            return AlertDialog(
              backgroundColor: const Color(0xFF1C1C1E),
              title: const Text(
                "Downloading...",
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 10),
                  Text(
                    "${(progress * 100).toStringAsFixed(0)}%",
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    isDownloadCancelled = true;
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
              ],  
            );
          },
        );
      },
    );

    try {
      final name = remotePath.split("/").last;

      final remoteFile = await widget.ssh.sftp!.open(remotePath);
      final stat = await remoteFile.stat();
      final totalSize = stat.size ?? 0;

      Directory downloadsDir;

      if (Platform.isAndroid) {
        downloadsDir = Directory("/storage/emulated/0/Download");
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      String filePath = "${downloadsDir.path}/$name";
      File localFile = File(filePath);

      // Handle duplicate
      if (await localFile.exists()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        filePath = "${downloadsDir.path}/${timestamp}_$name";
        localFile = File(filePath);
      }

      final sink = localFile.openWrite();

      int received = 0;

      final stream = remoteFile.read();

      await for (final chunk in stream) {
        if (isDownloadCancelled) {
          await sink.close();
          await remoteFile.close();

          if (await localFile.exists()) {
            await localFile.delete();
          }

          Navigator.pop(context);

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Download cancelled")));
          return;
        }

        received += chunk.length;
        sink.add(chunk);

        if (totalSize != 0) {
          progress = received / totalSize;

          setDialogState(() {});
        }
      }

      await sink.close();
      await remoteFile.close();

      Navigator.pop(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Downloaded: $filePath")));
    } catch (e) {
      Navigator.pop(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Download failed: $e")));
    }
  }

  Future<void> uploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result == null) return;

      final file = File(result.files.single.path!);
      final name = result.files.single.name;

      final remotePath = "$currentPath/$name";

      final remoteFile = await widget.ssh.sftp!.open(
        remotePath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write,
      );

      await remoteFile.write(
        file.openRead().map((data) => Uint8List.fromList(data)),
      );

      await remoteFile.close();

      await loadFiles(currentPath);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("File uploaded")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }
  }

  Future<void> uploadFolder() async {
    try {
      String? dir = await FilePicker.platform.getDirectoryPath();

      if (dir == null) return;

      final directory = Directory(dir);
      final entities = directory.listSync(recursive: true);

      for (var entity in entities) {
        if (entity is File) {
          final relative = entity.path.replaceFirst(dir, "");
          final remotePath = "$currentPath$relative";

          try {
            await widget.ssh.sftp!.mkdir(
              remotePath.substring(0, remotePath.lastIndexOf("/")),
            );
          } catch (_) {}

          final remoteFile = await widget.ssh.sftp!.open(
            remotePath,
            mode: SftpFileOpenMode.create | SftpFileOpenMode.write,
          );

          await remoteFile.write(
            entity.openRead().map((data) => Uint8List.fromList(data)),
          );
          await remoteFile.close();
        }
      }

      await loadFiles(currentPath);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Folder uploaded")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Folder upload failed: $e")));
    }
  }

  Widget deviceCard({required SftpName file}) {
    return GestureDetector(
      onTap: () async {
        final path = "$currentPath/${file.filename}";

        if (isDirectory(file) || isImage(file.filename)) {
          openItem(file);
          return;
        }

        // if file then show popup dialog
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1C1C1E),
              title: Text(
                file.filename,
                style: const TextStyle(color: Colors.white),
              ),
              content: const Text(
                "Choose an action",
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    isDownloadCancelled = false;
                    await downloadFile(path);
                  },
                  child: const Text("Download"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showFileInfo(file);
                  },
                  child: const Text("Info"),
                ),
              ],
            );
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            leadingWidget(file),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                file.filename,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void openUploadMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: 160,
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                leading: const Icon(
                  Icons.upload_file,
                  color: Color(0xFFB6FF00),
                ),
                title: const Text(
                  "Upload File",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  uploadFile();
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                leading: const Icon(
                  Icons.create_new_folder,
                  color: Color(0xFFB6FF00),
                ),
                title: const Text(
                  "Upload Folder",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  uploadFolder();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: currentPath == "/home",
      onPopInvokedWithResult: (didPop, result) async {
        if (currentPath != "/home") {
          final parent = currentPath.substring(0, currentPath.lastIndexOf("/"));
          await loadFiles(parent.isEmpty ? "/" : parent);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 40, right: 20),
          child: SizedBox(
            width: 54,
            height: 54,
            child: FloatingActionButton(
              hoverElevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              onPressed: openUploadMenu,
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              child: const Icon(Icons.add, color: Colors.black, size: 28),
            ),
          ),
        ),
        appBar: AppBar(
          title: const Text("My Files"),
          backgroundColor: Colors.black,
        ),
        body: Column(
          children: [
            if (downloadProgress > 0 && downloadProgress < 1)
              LinearProgressIndicator(value: downloadProgress),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    return deviceCard(file: files[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
