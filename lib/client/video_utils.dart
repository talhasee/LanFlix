// import 'package:chewie/chewie.dart';
// import 'package:flutter/material.dart';
// import 'package:logger/logger.dart';
// import 'package:video_player/video_player.dart';

// class video_utils {
//   VideoPlayerController? videoPlayerController;
//   ChewieController? chewieController;
//   final BuildContext context;

//   video_utils({required this.context});

//    var logger = Logger(
//     printer: PrettyPrinter(),
//   );

//   void dispose() {
//    logger.d("DISPOSED PLAYER");
//     if (videoPlayerController != null) {
//       videoPlayerController?.dispose();
//     }
//     if (chewieController != null) {
//       chewieController?.dispose();
//     }
//   }

//   void startInit(String serverURL) {
//     // String serverURL = 'http://$host_ip_address:8080/video/stream';
//     videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(serverURL));
//     chewieController = ChewieController(
//       videoPlayerController: videoPlayerController!,
//       aspectRatio: 16 / 9,
//       autoPlay: true,
//     );
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => Chewie(controller: chewieController!),
//       ),
//     );
//   }
// }

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
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    BackButtonInterceptor.add(myInterceptor);
  }

  @override
  void dispose() {
    if (widget.player.chewieController != null && widget.player.videoPlayerController != null) {
      widget.player.dispose();
    }
    super.dispose();
  }

  var logger = Logger(
    printer: PrettyPrinter(),
  );

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    logger.d("BACK BUTTON!");
    if(mounted){
      Navigator.pop(context);
    }
    return true;
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
  Route? clientPageRoute;

  video_utils({required this.context, this.clientPageRoute});

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

  void startInit(String serverURL) {
    videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(serverURL));
    chewieController = ChewieController(
      videoPlayerController: videoPlayerController!,
      aspectRatio: 16 / 9,
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
}
