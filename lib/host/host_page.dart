// import 'dart:ffi';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:restart_app/restart_app.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:streamer/host/p2p_utils.dart';
import '../utils/permissions.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
// import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
// import 'package:path/path.dart' as p;

void main() {
  runApp(const HostPage());
}

class HostPage extends StatefulWidget {
  const HostPage({super.key});

  @override
  State<HostPage> createState() => _HostPageState();
}

class _HostPageState extends State<HostPage> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final TextEditingController msgText = TextEditingController();
  final _flutterP2pConnectionPlugin = FlutterP2pConnection();
  late final Permissions permissions;
  late final p2p_utils p2p_util_obj;
  List<DiscoveredPeers> peers = [];
  bool hasPermission = false;
  WifiP2PInfo? wifiP2PInfo;
  String serverAddress = "";
  // ignore: unused_field
  StreamSubscription<WifiP2PInfo>? _streamWifiInfo;
  // ignore: unused_field
  StreamSubscription<List<DiscoveredPeers>>? _streamPeers;

  String videoPath = "";
  HttpServer? server;

  late Future<String> _addressFuture = Future.value("Creating....");
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  void _restartApp() {
    dispose();
    // Restart the app
    Restart.restartApp();
  }

  @override
  void dispose() {
    closeServer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    _flutterP2pConnectionPlugin.removeGroup();
    _flutterP2pConnectionPlugin.unregister();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // _flutterP2pConnectionPlugin.unregister();
    } else if (state == AppLifecycleState.resumed) {
      _flutterP2pConnectionPlugin.register();
    }
  }

  void _init() async {
    await _flutterP2pConnectionPlugin.initialize();
    await _flutterP2pConnectionPlugin.register();
    _streamWifiInfo = _flutterP2pConnectionPlugin.streamWifiP2PInfo().listen((event) {
      setState(() {
        wifiP2PInfo = event;
      });
    });
    _streamPeers = _flutterP2pConnectionPlugin.streamPeers().listen((event) {
      setState(() {
        peers = event;
      });
    });

    permissions =
        // ignore: use_build_context_synchronously
        Permissions(p2pObj: _flutterP2pConnectionPlugin, context: context);
    //check location, wifi and Storage permission
    bool hasPermission = await permissions.checkPermissions();
    if (!hasPermission) {
      snack("Don't have the required permissions to run the app.");
    }
    p2p_util_obj = p2p_utils(
        p2pObj: _flutterP2pConnectionPlugin,
        // ignore: use_build_context_synchronously
        context: context,
        permissions: permissions,
        wifiP2PInfo: wifiP2PInfo);
    _addressFuture = groupCreation();
  }

  Future<String> groupCreation() async {
    //removing groups if there are any which was formed earlier

    /*
    Below there is a jugaad of introducing a 2 sec delay after each 
    function call, create group and remove group will wait for each
    other.
    // TODO: Reduce delay time to milisecs
    */

    //starting group formation
    bool created = await p2p_util_obj.createGroup();

    snack("CREATION1 $created");
    if (!created) {
      await p2p_util_obj.removeGroup();
    }

    await Future.delayed(const Duration(seconds: 2));
    bool createdAgain = await p2p_util_obj.createGroup();
    snack("CREATION2 $createdAgain");

    if (createdAgain || created) {
      //start socket so that whenever client comes no need to connect it manually
      // bool? discovering = await discover();
      // snack("discovering $discovering");
      p2p_util_obj.discover();
      p2p_util_obj.startSocket();
    }
    String addr = (wifiP2PInfo?.groupOwnerAddress).toString();
    return addr;
  }

  // Future<bool> discover() async {
  //   return await _flutterP2pConnectionPlugin.discover();
  // }

  // Future<shelf.Response> _handleRequest(shelf.Request request) async {
  //   logger.d("INSIDE HANDLER REQUEST ${request.url.path}");

  //   if (request.url.path == 'video/stream') {
  //     // Assuming videoFilePath is the path to the selected video file
  //     String videoFilePath = videoPath;

  //     logger.d("Video File path - $videoFilePath");

  //     // Get the directory of the video file
  //     String videoDirectory = p.dirname(videoFilePath);
  //     String outputDirectory = p.join(videoDirectory, 'hls_output'); // Output directory within the video directory

  //     Directory(outputDirectory).createSync(recursive: true); // Create the output directory if it doesn't exist

  //     // Generate HLS content using flutter_ffmpeg
  //     var ffmpeg = FlutterFFmpeg();

  //     try {
  //       // Use a faster preset and higher bitrate for better performance
  //       await ffmpeg.execute(
  //         '-i $videoFilePath -c:v libx264 -preset veryfast -b:v 2500k -r 30 -vf scale=1280:-1 -f hls -hls_time 6 -hls_list_size 10 -hls_segment_filename $outputDirectory/%03d.ts $outputDirectory/index.m3u8',
  //       );
  //     } catch (e) {
  //       logger.d("Error in ffmpeg - $e");
  //       return shelf.Response.internalServerError(body: 'Error processing video');
  //     }

  //     // Serve the HLS files from the output directory
  //     var file = File(p.join(outputDirectory, 'index.m3u8'));
  //     return shelf.Response.ok(await file.readAsString(), headers: {'Content-Type': 'application/vnd.apple.mpegurl'});
  //   } else {
  //     return shelf.Response.notFound('Not Found');
  //   }
  // }

  // Future<shelf.Response> _handleRequest(shelf.Request request) async {
  //   logger.d("INSIDE HANDLER REQUEST ${request.url.path}");
  //   if (request.url.path == 'video/stream') {
  //     // Assuming videoFilePath is the path to the selected video file
  //     String videoFilePath = videoPath;
  //     logger.d("Video File path - $videoFilePath");

  //     // Get the directory of the video file
  //     String videoDirectory = p.dirname(videoFilePath);
  //     String outputDirectory = p.join(videoDirectory,
  //         'hls_output'); // Output directory within the video directory
  //     Directory(outputDirectory).createSync(
  //         recursive: true); // Create the output directory if it doesn't exist

  //     // Generate HLS content using flutter_ffmpeg
  //     var ffmpeg = FlutterFFmpeg();
  //     try {
  //       //   await ffmpeg.execute(
  //       //   '-i $videoFilePath -c:v libx264 -g 32 -sc_threshold 0 '
  //       //   '-b:v 2500k -b:a 128k -ac 2 -ar 44100 -f hls -hls_time 10 -hls_list_size 0 '
  //       //   '-hls_segment_filename $outputDirectory/%03d.ts $outputDirectory/index.m3u8',
  //       // );
  //       await ffmpeg.execute(
  //   '-i $videoFilePath -c:v libx264 -b:v 1000k -r 30 -vf scale=1280:-1 -preset slow -f hls -hls_time 10 -hls_list_size 0 -hls_segment_filename $outputDirectory/%03d.ts $outputDirectory/index.m3u8',
  // );

  //     } catch (e) {
  //       logger.d("Error in ffmpeg - $e");
  //       return shelf.Response.internalServerError(
  //           body: 'Error processing video');
  //     }

  //     // Serve the HLS files from the output directory
  //     var file = File(p.join(outputDirectory, 'index.m3u8'));
  //     return shelf.Response.ok(await file.readAsString(),
  //         headers: {'Content-Type': 'application/vnd.apple.mpegurl'});
  //   } else {
  //     return shelf.Response.notFound('Not Found');
  //   }
  // }

  // void createShelfHandler() async {
  //   var handler = const shelf.Pipeline().addMiddleware(shelf.logRequests()).addHandler(_handleRequest);

  //   // logger.d("${InternetAddress.anyIPv4}");

  //   String? ip = await _flutterP2pConnectionPlugin.getIPAddress();
  //   logger.d("FLUTTER IP - $ip");
  //   sendDataAsMessage("&HOST_IP$ip");

  //   try {
  //     // Bind the handler to a port
  //     server = await shelf_io.serve(handler, ip.toString(), 8080);
  //     logger.d('HTTP Server listening on port 8080');
  //   } catch (e) {
  //     logger.d('Error starting HTTP server: $e');
  //     // Handle the error, log it, or take appropriate action
  //   }
  // }

  void closeServer() {
    if (server != null) {
      server?.close();
      logger.d("SERVER IS CLOSED");
    }
  }

  void selectVideoFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) {
      snack("Please select a File");
      return;
    }
    PlatformFile file = result.files.first;
    if (file.path == null) {
      return;
    }

    videoPath = (file.path).toString();
  }
  // //create group

  // Future<bool> createGroup() async {
  //   bool enabledLocation = await permissions.isLocationEnabled();
  //   bool? groupFormed = wifiP2PInfo?.groupFormed;
  //   if (enabledLocation && (groupFormed == null || groupFormed == false)) {
  //     bool groupDeletion = await _flutterP2pConnectionPlugin.createGroup();
  //     snack("Creating group $enabledLocation,  $groupFormed, $groupDeletion");
  //     return groupDeletion;
  //   } else if (!enabledLocation) {
  //     snack("Please turn on Location!! $enabledLocation,  $groupFormed");
  //     permissions.enableLocation();
  //   } else if (groupFormed != null && groupFormed) {
  //     snack("Please remove or disconnect earlier group!!");
  //     return false;
  //   }
  //   // snack("Remove old group first!!!");
  //   return false;
  // }

  // //remove Group

  // Future<bool> removeGroup() async {
  //   bool enabledLocation = await permissions.isLocationEnabled();
  //   bool? groupFormed = wifiP2PInfo?.groupFormed;
  //   if (enabledLocation && (groupFormed != null && groupFormed == true)) {
  //     bool groupDeletion = await _flutterP2pConnectionPlugin.removeGroup();
  //     snack("Removing group $enabledLocation,  $groupFormed, $groupDeletion");
  //     return groupDeletion;
  //   } else if (!enabledLocation) {
  //     snack("Please turn on Location!! $enabledLocation,  $groupFormed");
  //     permissions.enableLocation();
  //     return false;
  //   } else if (groupFormed == null || groupFormed == false) {
  //     snack("No group to remove!!");
  //     return false;
  //   }
  //   // snack("Remove old group first!!!");
  //   return false;
  // }

  // Future startSocket() async {
  //   if (wifiP2PInfo != null) {
  //     bool started = await _flutterP2pConnectionPlugin.startSocket(
  //       groupOwnerAddress: wifiP2PInfo!.groupOwnerAddress,
  //       downloadPath: "/storage/emulated/0/Download/",
  //       maxConcurrentDownloads: 2,
  //       deleteOnError: true,
  //       onConnect: (name, address) {
  //         snack("$name connected to socket with address: $address");
  //       },
  //       transferUpdate: (transfer) {
  //         if (transfer.completed) {
  //           snack("${transfer.failed ? "failed to ${transfer.receiving ? "receive" : "send"}" : transfer.receiving ? "received" : "sent"}: ${transfer.filename}");
  //         }
  //         print(
  //             "ID: ${transfer.id}, FILENAME: ${transfer.filename}, PATH: ${transfer.path}, COUNT: ${transfer.count}, TOTAL: ${transfer.total}, COMPLETED: ${transfer.completed}, FAILED: ${transfer.failed}, RECEIVING: ${transfer.receiving}");
  //       },
  //       receiveString: (req) async {
  //         snack(req);
  //       },
  //     );
  //     snack("open socket: $started");
  //   }
  // }

  // Future connectToSocket() async {
  //   if (wifiP2PInfo != null) {
  //     await _flutterP2pConnectionPlugin.connectToSocket(
  //       groupOwnerAddress: wifiP2PInfo!.groupOwnerAddress,
  //       downloadPath: "/storage/emulated/0/Download/",
  //       maxConcurrentDownloads: 3,
  //       deleteOnError: true,
  //       onConnect: (address) {
  //         snack("connected to socket: $address");
  //       },
  //       transferUpdate: (transfer) {
  //         // if (transfer.count == 0) transfer.cancelToken?.cancel();
  //         if (transfer.completed) {
  //           snack("${transfer.failed ? "failed to ${transfer.receiving ? "receive" : "send"}" : transfer.receiving ? "received" : "sent"}: ${transfer.filename}");
  //         }
  //         print(
  //             "ID: ${transfer.id}, FILENAME: ${transfer.filename}, PATH: ${transfer.path}, COUNT: ${transfer.count}, TOTAL: ${transfer.total}, COMPLETED: ${transfer.completed}, FAILED: ${transfer.failed}, RECEIVING: ${transfer.receiving}");
  //       },
  //       receiveString: (req) async {
  //         snack(req);
  //       },
  //     );
  //   }
  // }

  // Future closeSocketConnection() async {
  //   bool closed = _flutterP2pConnectionPlugin.closeSocket();
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(
  //         "closed: $closed",
  //       ),
  //     ),
  //   );
  // }

  // Future sendMessage() async {
  //   _flutterP2pConnectionPlugin.sendStringToSocket(msgText.text);
  // }

  Future sendDataAsMessage(String mssg) async {
    _flutterP2pConnectionPlugin.sendStringToSocket(mssg);
  }

  // Future sendFile(bool phone) async {
  //   // String? filePath = await FilesystemPicker.open(
  //   //   context: context,
  //   //   rootDirectory: Directory(phone ? "/storage/emulated/0/" : "/storage/"),
  //   //   fsType: FilesystemType.file,
  //   //   fileTileSelectMode: FileTileSelectMode.wholeTile,
  //   //   showGoUp: true,
  //   //   folderIconColor: Colors.blue,
  //   // );
  //   FilePickerResult? result = await FilePicker.platform.pickFiles();
  //   if (result == null) {
  //     snack("Please select a File");
  //     return;
  //   }
  //   PlatformFile file = result.files.first;
  //   if (file.path == null) {
  //     return;
  //   }
  //   snack("File Name: ${file.name}");
  //   // if (filePath == null) return;
  //   List<TransferUpdate>? updates = await _flutterP2pConnectionPlugin.sendFiletoSocket(
  //     [
  //       (file.path).toString(),
  //       // "/storage/emulated/0/Download/Likee_7100105253123033459.mp4",
  //       // "/storage/0E64-4628/Download/Adele-Set-Fire-To-The-Rain-via-Naijafinix.com_.mp3",
  //       // "/storage/0E64-4628/Flutter SDK/p2p_plugin.apk",
  //       // "/storage/emulated/0/Download/03 Omah Lay - Godly (NetNaija.com).mp3",
  //       // "/storage/0E64-4628/Download/Adele-Set-Fire-To-The-Rain-via-Naijafinix.com_.mp3",
  //     ],
  //   );
  //   print(updates);
  // }

  void snack(String msg) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(
          msg,
        ),
      ),
    );
  }

  var logger = Logger(
    printer: PrettyPrinter(),
  );

  static const platform = MethodChannel('http.server');

  Future<void> _startSerer(String filePath) async {
    try {
      String addr = await platform.invokeMethod('startVideoStream', {'videoPath': filePath}) as String;
      logger.d("Started video stream at $addr");
      setState(() {
        serverAddress = addr;
      });
    } on PlatformException catch (e) {
      logger.d("Error in platform channel");
      logger.e(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.green[300],
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 5, 197, 78),
          title: const Text('Flutter p2p connection plugin'),
        ),
        // ignore: prefer_const_constructors
        body: Center(
          // ignore: prefer_const_constructors
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            // ignore: prefer_const_literals_to_create_immutables
            children: [
              FutureBuilder<String>(
                future: _addressFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Fetching group owner address...',
                          style: TextStyle(fontSize: 24),
                        ),
                        SizedBox(height: 20), // Add some space between text and loading animation
                        CircularProgressIndicator(),
                      ],
                    );
                  } else if (snapshot.hasError || snapshot.data == null || snapshot.data == "null") {
                    // If snapshot has error or data is null, show alert and restart the app
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      showDialog(
                        context: context,
                        barrierDismissible: false, // Prevent dismissing dialog by tapping outside
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Error'),
                            content: const Text('Please restart your WiFi and open the app again.'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _restartApp();
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    });
                    return Container();
                  } else {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Group Owner Address',
                          style: TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '${snapshot.data}',
                          style: const TextStyle(fontSize: 24),
                        ),
                      ],
                    );
                  }
                },
              ),
              ElevatedButton(
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles();
                    if (result != null) {
                      PlatformFile file = result.files.first;
                      logger.d("File Name: ${file.name}\nFile Path: ${file.path.toString()}");
                      await _startSerer(file.path.toString());
                    }
                  },
                  child: const Text("File Select")),
              // ElevatedButton(onPressed: selectVideoFile, child: Text("Select Video File")),
              // ElevatedButton(onPressed: createShelfHandler, child: Text("Start Video server")),
              Text(
                serverAddress,
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
        ));
  }
}
