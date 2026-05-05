import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sudosync/screens/app_dialog.dart';
import '../service/ssh_service.dart';

class ImageViewer extends StatefulWidget {

  final SSHService ssh;
  final String path;

  const ImageViewer({
    super.key,
    required this.ssh,
    required this.path,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  File? image;
  double progress = 0;
  bool isDownloading = true;
  bool isCancelled = false;
  bool isUIVisible = true;
  String? error;

  late String fileName;

  @override
  void initState() {
    super.initState();
    fileName = widget.path.split("/").last;
    loadImage();
  }

  Future<void> loadImage() async {
    try {
      final dir = await getTemporaryDirectory();
      final localPath = "${dir.path}/$fileName";
      final file = File(localPath);

      //Implementing a simple cache mechanism if the file already exists, use it instead of downloading again
      if (file.existsSync()) {
        setState(() {
          image = file;
          isDownloading = false;
        });
        return;
      }

      await widget.ssh.downloadFile(
        remotePath: widget.path,
        localPath: localPath,
        onProgress: (p) {
          if (!mounted) return;
          setState(() {
            progress = p;
          });
        },
        isCancelled: () => isCancelled,
      );

      if (isCancelled) return;

      setState(() {
        image = file;
        isDownloading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = "Failed to load image";
        isDownloading = false;
      });
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

  void retry() {
    setState(() {
      progress = 0;
      isDownloading = true;
      error = null;
      isCancelled = false;
    });
    loadImage();
  }

  @override
  void dispose() {
    isCancelled = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: isUIVisible
          ? AppBar(
              backgroundColor: Colors.black,
              title: Text(fileName),
              actions: [

                if (isDownloading)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        isCancelled = true;
                      });
                      Navigator.pop(context);
                    },
                  ),

                IconButton(
                  icon: const Icon(Icons.download_for_offline_rounded),
                  onPressed: () => downloadFile(widget.path),
                ),

                IconButton(
                  icon: const Icon(Icons.info),
                  onPressed: () {
                    AppDialog.show(
                      context: context,
                      title: "File Info",
                      message: "Name: $fileName\n\nPath: ${widget.path}\n\nSize: ${image?.lengthSync() ?? 'Unknown'} bytes",
                      actions: [
                        AppDialog.action(
                          "Close",
                          () => Navigator.pop(context),
                        ),
                      ],
                    );
                  },
                ),
              ],
            )
          : null,

      body: GestureDetector(
        onTap: () {
          setState(() {
            isUIVisible = !isUIVisible;
          });
        },

        child: Center(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {

    if (error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 40),
          const SizedBox(height: 10),
          Text(error!, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: retry,
            child: const Text("Retry"),
          ),
        ],
      );
    }

    if (isDownloading || image == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(value: progress),
          const SizedBox(height: 12),
          Text(
            "${(progress * 100).toStringAsFixed(0)}%",
            style: const TextStyle(color: Colors.white),
          ),
        ],
      );
    }

    return InteractiveViewer(
      minScale: 1,
      maxScale: 5,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Image.file(image!, fit: BoxFit.contain),
      ),
    );
  }
}