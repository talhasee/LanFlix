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

  Future sendDataAsMessage(String mssg) async {
    _flutterP2pConnectionPlugin.sendStringToSocket(mssg);
  }

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
              Text(
                serverAddress,
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
        ));
  }
}
