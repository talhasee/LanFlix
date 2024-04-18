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
import 'package:streamer/client/client_page.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerPage extends StatefulWidget {
  // final ChewieController chewieController;
  final video_utils player;

  const VideoPlayerPage({Key? key, required this.player}) : super(key: key);

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
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

  void _showBackDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text(
            'Are you sure you want to leave this page?',
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Nevermind'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Leave'),
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                // if (widget.player.clientPageRoute != null) {
                //   Navigator.popUntil(context, (route) => route == widget.player.clientPageRoute);
                //   logger.d("Going to Client Page");
                // } else {
                //   Navigator.pop(context); // Fallback to popping the current page if clientPageRoute is null
                //   logger.d("Going to Home Page");
                // }
              },
            ),
          ],
        );
      },
    );
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
