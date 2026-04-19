import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

import '../service/ssh_service.dart';
import 'image_viewer.dart';

import './app_dialog.dart';

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

  bool isUploading = false;
  bool isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    loadFiles(currentPath);
  }

  Future<void> loadFiles(String path) async {
    try {
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
    } catch (e) {
      await widget.ssh.reconnect();
    }
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
    } catch (_) {
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
    } catch (_) {
      return null;
    }
  }

  Widget leadingWidget(SftpName file) {
    final path = "$currentPath/${file.filename}";

    if (isDirectory(file)) {
      return const Icon(Icons.folder, size: 40, color: Color(0xFFB6FF00));
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
                    if (Navigator.canPop(context)) Navigator.pop(context);
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

      Directory downloadsDir = Platform.isAndroid
          ? Directory("/storage/emulated/0/Download")
          : await getApplicationDocumentsDirectory();

      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      String filePath = "${downloadsDir.path}/$name";
      File localFile = File(filePath);

      if (await localFile.exists()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        filePath = "${downloadsDir.path}/${timestamp}_$name";
      }

      await widget.ssh.downloadFile(
        remotePath: remotePath,
        localPath: filePath,
        onProgress: (p) {
          progress = p;
          setDialogState(() {});
        },
        isCancelled: () => isDownloadCancelled,
      );

      if (Navigator.canPop(context)) Navigator.pop(context);

      if (isDownloadCancelled) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Download cancelled")));
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Downloaded: $filePath")));
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Download failed: $e")));
    }
  }

  bool isFileUploadCancelled = false;

  Future<void> uploadFile() async {
    if (isUploading) return;

    isFileUploadCancelled = false;

    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (!mounted) return;
      if (result == null || result.files.isEmpty) return;

      await widget.ssh.reconnect();

      isUploading = true;
      isDialogOpen = true;

      final pickedFiles = result.files;

      double progress = 0;
      int lastUpdate = 0;
      int totalFiles = pickedFiles.length;
      int completedFiles = 0;

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
                  "Uploading...",
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
                      isFileUploadCancelled = true;
                      if (Navigator.canPop(context)) Navigator.pop(context);
                      isDialogOpen = false;
                    },
                    child: const Text("Cancel"),
                  ),
                ],
              );
            },
          );
        },
      );

      await widget.ssh.createDirIfNotExists(currentPath);

      for (var picked in pickedFiles) {
        if (picked.path == null || isFileUploadCancelled) break;

        final file = File(picked.path!);
        final remotePath = "$currentPath/${picked.name}";

        await widget.ssh.uploadFile(
          localPath: file.path,
          remotePath: remotePath,
          onProgress: (p) {
            final now = DateTime.now().millisecondsSinceEpoch;
            if (now - lastUpdate > 100) {
              lastUpdate = now;
              progress = (completedFiles + p) / totalFiles;
              if (isDialogOpen && mounted) setDialogState(() {});
            }
          },
          isCancelled: () => isFileUploadCancelled,
        );

        completedFiles++;
        progress = completedFiles / totalFiles;

        if (isDialogOpen && mounted) setDialogState(() {});
      }

      if (Navigator.canPop(context)) Navigator.pop(context);
      isDialogOpen = false;

      if (isFileUploadCancelled) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Upload cancelled")));
        isUploading = false;
        return;
      }

      await loadFiles(currentPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$completedFiles file(s) uploaded")),
      );
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      isDialogOpen = false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      isUploading = false;
    }
  }

  Widget deviceCard({required SftpName file}) {
    var fileType = "";
        if (file.attr.size! < 1024) {
          fileType = "Size: ${file.attr.size!} Bytes";
        } else if (file.attr.size! < 1024 * 1024) {
          fileType = "Size: ${(file.attr.size! / 1024).toStringAsFixed(2)} KB";
        } else if (file.attr.size! < 1024 * 1024 * 1024) {
          fileType = "Size: ${(file.attr.size! / (1024 * 1024)).toStringAsFixed(2)} MB";
        } else {
          fileType = "Size: ${(file.attr.size! / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
        }

    return GestureDetector(
      onLongPress: () => AppDialog.show(
        context: context,
        title: file.filename,
        message: fileType,
        type: DialogType.info,
        actions: [
          AppDialog.action("Close", () {
            Navigator.pop(context);
          }),
        ],
      ),

      onTap: () async {
        final path = "$currentPath/${file.filename}";

        if (isDirectory(file) || isImage(file.filename)) {
          openItem(file);
          return;
        }

        AppDialog.show(
          context: context,
          title: file.filename,
          message: fileType,
          type: DialogType.info,
          actions: [
            AppDialog.action("Download", () {
              Navigator.pop(context);
              downloadFile(path);
            }),
            AppDialog.action("Details", () {
              Navigator.pop(context);
              AppDialog.show(
                context: context,
                title: "File Info",
                message:
                    "Name: ${file.filename}\n\nType: ${isDirectory(file) ? "Folder" : "File"}\n\nDetails:\n${file.longname}",
                type: DialogType.info,
                actions: [
                  AppDialog.action("Close", () => Navigator.pop(context)),
                ],
              );
            }),
          ],
        );
      },
      child: ListTile(
        leading: leadingWidget(file),
        title: Text(
          file.filename, 
          style: const TextStyle(color: Colors.white, fontSize: 18,),
          ),
        subtitle: Text(
          "${file.attr.size} bytes",
          style: const TextStyle(color: Colors.white70, fontSize: 12),
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
          height: 120,
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: const Icon(
                  Icons.upload_file,
                  color: Color(0xFFB6FF00),
                ),
                title: const Text(
                  "Upload File",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (!mounted) return;
                  uploadFile();
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
      canPop: currentPath == "/home" && !isUploading,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (isUploading) return;
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
              child: ListView.builder(
                itemCount: files.length,
                itemBuilder: (context, index) {
                  return deviceCard(file: files[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
