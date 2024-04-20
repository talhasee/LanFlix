// import 'dart:ffi';
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:restart_app/restart_app.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:streamer/client/video_utils.dart';
import 'package:streamer/host/p2p_utils.dart';
import 'package:streamer/utils/permissions.dart';

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
  String pin = "----";
  String showPinTxt = "";
  final ListOfWidgets = <Widget>[Text("Private"), Text("Public")];
  final List<bool> _selectedToggle = <bool>[false, true];
  // String netState =
  // ignore: unused_field
  StreamSubscription<WifiP2PInfo>? _streamWifiInfo;
  // ignore: unused_field
  StreamSubscription<List<DiscoveredPeers>>? _streamPeers;
  late final video_utils player;
  String fileName = "";

  String videoPath = "";
  HttpServer? server;

  late Future<String> _addressFuture = Future.value(" Creating....");
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    player = video_utils(context: context);
    _init();
  }

  void _restartApp() {
    dispose();
    // Restart the app
    Restart.restartApp();
  }

  @override
  void dispose() {
    _streamWifiInfo?.cancel();
    _streamPeers?.cancel();
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
        // logger.d("Setting state of wifip2pinfo");
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
    // if (!hasPermission) {
    //   // snack("Don't have the required permissions to run the app.");
    // }
    if (wifiP2PInfo == null) {
      logger.d("yes its null");
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

    // snack("CREATION1 $created");
    if (!created) {
      await p2p_util_obj.removeGroup();
    }

    await Future.delayed(const Duration(seconds: 2));
    bool createdAgain = await p2p_util_obj.createGroup();
    // snack("CREATION2 $createdAgain");

    if (createdAgain || created) {
      //start socket so that whenever client comes no need to connect it manually
      // bool? discovering = await discover();
      // snack("discovering $discovering");
      if (wifiP2PInfo == null) {
        logger.d("Inside wifip2pinfo is null");
      }
      p2p_util_obj.wifiP2PInfo = wifiP2PInfo;
      logger.d("Group created!!");
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
      logger.d("PIN -> $pin......server - $serverAddress");
      sendDataAsMessage("&VIDEO$serverAddress|8|$pin"); // add duration here
    } on PlatformException catch (e) {
      logger.d("Error in platform channel");
      logger.e(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: Image.asset("lib/assets/images/logo.png"),
        ),
        // ignore: prefer_const_constructors
        body: Center(
          // ignore: prefer_const_constructors
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            // ignore: prefer_const_literals_to_create_immutables
            children: [
              Column(
                children: [
                  FutureBuilder<String>(
                    future: _addressFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Fetching address...',
                              style: TextStyle(fontSize: 24),
                            ),
                            SizedBox(height: 14), // Add some space between text and loading animation
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
                              '  HOST IP\n ADDRESS',
                              style: TextStyle(fontSize: 42),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '${snapshot.data?.substring(1)}',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
              Column(
                children: [
                  ToggleButtons(
                    direction: Axis.horizontal,
                    onPressed: (int index) {
                      setState(() {
                        // The button that is tapped is set to true, and the others to false.
                        for (int i = 0; i < _selectedToggle.length; i++) {
                          _selectedToggle[i] = i == index;
                          if (index == 0) {
                            setState(() {
                              pin = (1000 + Random().nextInt(9000)).toString();
                              showPinTxt = "PIN:  $pin";
                            });
                          } else {
                            setState(() {
                              pin == "----";
                              showPinTxt = "";
                            });
                          }
                        }
                      });
                      logger.d("PIN - $pin....PIN TEXT - $showPinTxt");
                    },
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    selectedBorderColor: Colors.red[700],
                    selectedColor: Colors.white,
                    fillColor: Color(0xffff5c00),
                    color: Color(0xffff5c00),
                    constraints: const BoxConstraints(
                      minHeight: 40.0,
                      minWidth: 80.0,
                    ),
                    isSelected: _selectedToggle,
                    children: ListOfWidgets,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Text(
                    showPinTxt,
                    style: TextStyle(fontSize: 22),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    'SELECT MEDIA TO STREAM',
                    style: TextStyle(fontSize: 22),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Color(0xffff5c00), shape: BeveledRectangleBorder()),
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles();
                      if (result != null) {
                        PlatformFile file = result.files.first;
                        logger.d("File Name: ${file.name}\nFile Path: ${file.path.toString()}");
                        setState(() {
                          fileName = file.name;
                        });
                        await _startSerer(file.path.toString());
                        //Start video on host side
                        String videoPath = file.path.toString();
                        try {
                          player.startInitFromLocal(videoPath, 0);
                        } catch (e) {
                          logger.d("error in playing video $e");
                        }
                      }
                    },
                    child: const Text(
                      "UPLOAD",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  SizedBox(
                    height: 22,
                  ),
                  Text(
                    fileName,
                    style: TextStyle(fontSize: 16),
                  )
                ],
              ),
            ],
          ),
        ));
  }
}
