import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'client/client_page.dart';
import 'host/host_page.dart';

void main() {
 runApp(const MyApp());
}

class MyApp extends StatefulWidget {
 const MyApp({super.key});

 @override
 State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
 static const platform = MethodChannel('com.example.videostreamer');

 Future<void> hostPageDirect() async {
    // Navigate to host stream page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HostPage()),
    );
 }

 Future<void> clientPageDirect() async {
    // Navigate to receive stream page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ClientPage()),
    );
 }

 Future<void> streamVideo(String videoPath) async {
    try {
      await platform.invokeMethod('streamVideo', {'videoPath': videoPath});
    } on PlatformException catch (e) {
      logger.d("Failed to stream video: '${e.message}'.");
    }
 }

   var logger = Logger(
    printer: PrettyPrinter(),
  );

 @override
 Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter p2p connection plugin'),
        ),
        body: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => streamVideo('/path/to/video.mp4'), // Example path
                child: Container(
                 color: Colors.green[700],
                 child: const Center(
                    child: Text(
                      "Host",
                      style: TextStyle(color: Colors.white, fontSize: 44),
                    ),
                 ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: clientPageDirect,
                child: Container(
                 color: Colors.amber[700],
                 child: const Center(
                    child: Text(
                      "Client",
                      style: TextStyle(color: Colors.white, fontSize: 44),
                    ),
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
