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

  Future<void> downloadImage() async {

    final tempDir = await getTemporaryDirectory();

    final name = widget.path.split("/").last;

    final file = File("${tempDir.path}/$name");

    final remote = await widget.ssh.sftp!.open(widget.path);

    final bytes = await remote.readBytes();

    await file.writeAsBytes(bytes);

    setState(() {
      image = file;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Image Viewer"),
        actions: [

          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {

              final file = await widget.ssh.downloadFile(widget.path);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Saved to ${file?.path}")),
              );
            },
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

extension on Object? {
  get path => null;
}
