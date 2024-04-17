import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class video_utils {
  late VideoPlayerController videoPlayerController;
  late ChewieController chewieController;
  final BuildContext context;

  video_utils({required this.context});

  void dispose() {
    videoPlayerController.dispose();
    chewieController.dispose();
  }

  void startInit(String serverURL) {
    // String serverURL = 'http://$host_ip_address:8080/video/stream';
    videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(serverURL));
    chewieController = ChewieController(
      videoPlayerController: videoPlayerController,
      aspectRatio: 16 / 9,
      autoPlay: true,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Chewie(controller: chewieController),
      ),
    );
  }
}
