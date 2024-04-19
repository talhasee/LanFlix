import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:video_player/video_player.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';

class VideoPlayerPage extends StatefulWidget {
  // final ChewieController chewieController;

  final video_utils player;

  const VideoPlayerPage({Key? key, required this.player}) : super(key: key);

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  bool isFullScreen = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    BackButtonInterceptor.add(myInterceptor);
    widget.player.chewieController?.addListener(_onFullScreenChanged);
  }

  @override
  void dispose() {
    widget.player.chewieController?.removeListener(_onFullScreenChanged);
    if (widget.player.chewieController != null && widget.player.videoPlayerController != null) {
      widget.player.dispose();
    }
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  var logger = Logger(
    printer: PrettyPrinter(),
  );

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    logger.d("BACK BUTTON!");
    // if (mounted) {
    //   Navigator.pop(context);
    // }

    // If the video player is in full-screen mode
    logger.d("FUllscreen - $isFullScreen, mounted - $mounted");
    // if (!mounted) mounted = true;
    if (isFullScreen) {
      // Exit full-screen mode
      // widget.player.chewieController?.exitFullScreen();
      // setState(() {
      //   isFullScreen = false;
      // });

      // Prevent the default back button behavior
      return false;
    }
    // Dispose of the video player and Chewie controller
    // if (widget.player.chewieController != null && widget.player.videoPlayerController != null) {
    //   widget.player.dispose();
    // }
    // Pop the current page and go back to the previous page
    logger.d("Here");
    logger.d(mounted);
    if (mounted) {
      logger.d("Here inside");
      Navigator.of(context).pop();
    }
    return true;
  }

  void _onFullScreenChanged() {
    setState(() {
      isFullScreen = widget.player.chewieController?.isFullScreen ?? false;
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Player'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Page Two'),
            PopScope(
              canPop: true,
              onPopInvoked: (bool didPop) {
                // _showBackDialog();
                logger.d("Back button is clicked");
              },
              child: Expanded(
                child: Container(
                  // Set explicit constraints for Chewie
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height,
                    maxWidth: MediaQuery.of(context).size.width,
                  ),
                  child: Chewie(
                    controller: widget.player.chewieController!,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class video_utils {
  VideoPlayerController? videoPlayerController;
  ChewieController? chewieController;
  final BuildContext context;

  video_utils({required this.context});

  var logger = Logger(
    printer: PrettyPrinter(),
  );

  void dispose() {
    logger.d("DISPOSED PLAYER");
    if (videoPlayerController != null) {
      videoPlayerController?.dispose();
    }
    if (chewieController != null) {
      chewieController?.dispose();
    }
  }

  void startInit(String serverURL, int startAt) {
    videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(serverURL));
    chewieController = ChewieController(
      videoPlayerController: videoPlayerController!,
      isLive: true, // live rakhna hai ya ni
      startAt: Duration(seconds: startAt),
      showOptions: false,
      autoPlay: true,
    );

    // clientPageRoute = ModalRoute.of(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoPlayerPage(
          player: this,
        ),
      ),
    );
  }

  void startInitFromLocal(String videoPath, int startAt) {
    videoPlayerController = VideoPlayerController.file(File(videoPath));
    chewieController = ChewieController(
      videoPlayerController: videoPlayerController!,
      isLive: true,
      startAt: Duration(seconds: startAt),
      showOptions: false,
      autoPlay: true,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoPlayerPage(
          player: this,
        ),
      ),
    );
  }
}
