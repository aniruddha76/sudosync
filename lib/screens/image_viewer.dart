import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
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

  @override
  void initState() {
    super.initState();
    downloadImage();
  }

bool isDownloadCancelled = false;

Future<void> downloadImage() async {
  Directory tempDir = await getTemporaryDirectory();
    
    final localPath = "${tempDir.path}/${widget.path.split("/").last}";

    await widget.ssh.downloadFile(
      remotePath: widget.path,
      localPath: localPath,
      onProgress: (p) {

      },
      isCancelled: () => false,
    );

    setState(() {
      image = File(localPath);
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.path.split("/").last),
        actions: [

          IconButton(
            icon: const Icon(Icons.download),
            onPressed: null
          ),

          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("File Info"),
                  content: Text(widget.path),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    )
                  ],
                ),
              );

            },
          ),

        ],
      ),

      body: Center(

        child: image == null
            ? const CircularProgressIndicator()
            : Image.file(image!),
      ),
    );
  }
}