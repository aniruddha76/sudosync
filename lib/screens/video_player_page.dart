import 'dart:async';
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../service/ssh_service.dart';

class VideoPlayerPage extends StatefulWidget {
  final SSHService ssh;
  final String remotePath;
  final String fileName;

  const VideoPlayerPage({
    super.key,
    required this.ssh,
    required this.remotePath,
    required this.fileName,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  File? localFile;
  IOSink? _sink;
  StreamSubscription? _sub;

  bool loading = true;
  double progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startStreaming();
  }

  Future<void> _startStreaming() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = "${tempDir.path}/${widget.fileName}";
      localFile = File(filePath);

      if (await localFile!.exists()) {
        await localFile!.delete();
      }

      await localFile!.create(recursive: true);

      final remote = await widget.ssh.sftp!.open(widget.remotePath);

      _sink = localFile!.openWrite();

      int downloaded = 0;

      _sub = remote.read().listen(
        (data) {
          downloaded += data.length;
          _sink?.add(data);

          setState(() {
            progress += 0.02; 
            if (progress > 1.0) progress = 1.0;
          });

          // i kept size to 512 kb so video will start playing faster
          if (_videoController == null && downloaded > 512 * 1024) {
            _initializePlayer();
          }
        },
        onDone: () async {
          await _sink?.flush();
          await _sink?.close();
          _sink = null;
        },
        onError: (e) async {
          await _sink?.close();
        },
        cancelOnError: true,
      );
    } catch (e) {
      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Stream failed: $e")),
      );
    }
  }

  Future<void> _initializePlayer() async {
    if (localFile == null) return;

    _videoController = VideoPlayerController.file(localFile!);
    await _videoController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      showControlsOnInitialize: false,
      allowedScreenSleep: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: const Color(0xFFB6FF00),
        handleColor: const Color(0xFFB6FF00),
        bufferedColor: Colors.grey.withOpacity(0.5),
      ),
    );

    setState(() {
      loading = false;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _sink?.close();
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.fileName),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: loading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFFB6FF00),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Buffering... ${(progress * 100).toInt()}%",
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              )
            : Chewie(controller: _chewieController!),
      ),
    );
  }
}