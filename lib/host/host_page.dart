import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:restart_app/restart_app.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
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
  List<DiscoveredPeers> peers = [];
  bool hasPermission = false;
  WifiP2PInfo? wifiP2PInfo;
  // ignore: unused_field
  StreamSubscription<WifiP2PInfo>? _streamWifiInfo;
  // ignore: unused_field
  StreamSubscription<List<DiscoveredPeers>>? _streamPeers;

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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    _flutterP2pConnectionPlugin.removeGroup();
    _flutterP2pConnectionPlugin.unregister();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _flutterP2pConnectionPlugin.unregister();
    } else if (state == AppLifecycleState.resumed) {
      _flutterP2pConnectionPlugin.register();
    }

    // switch (state) {
    //   case AppLifecycleState.resumed:
    //     _flutterP2pConnectionPlugin.register();
    //     break;
    //   case AppLifecycleState.inactive:
    //   case AppLifecycleState.paused:
    //     _flutterP2pConnectionPlugin.unregister();
    //     break;
    //   case AppLifecycleState.hidden:
    //   case AppLifecycleState.detached:
    //     // dispose();
    //     // break;
    // }
  }

  void _init() async {
    await _flutterP2pConnectionPlugin.initialize();
    await _flutterP2pConnectionPlugin.register();
    _streamWifiInfo =
        _flutterP2pConnectionPlugin.streamWifiP2PInfo().listen((event) {
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
      snack("Permission de de chup chap se varna phone hack hoga tera");
    }
    _addressFuture = groupCreation();
  }

  Future<String> groupCreation() async {
    //removing groups if there are any which was formed earlier

    /*
    Below there is a jugaad of introducing a 2 sec delay after each 
    function call, create group and remove group will wait for each
    other.
    */

    //starting group formation
    bool created = await createGroup();

    snack("CREATION1 $created");
    if (!created) {
      await removeGroup();
    }

    await Future.delayed(const Duration(seconds: 2));
    bool createdAgain = await createGroup();
    snack("CREATION2 $createdAgain");

    if (createdAgain) {
      //start socket so that whenever client comes no need to connect it manually
      // bool? discovering = await discover();
      // snack("discovering $discovering");
      discover();
      startSocket();
    }
    String addr = (wifiP2PInfo?.groupOwnerAddress).toString();
    return addr;
  }

  Future<bool> discover() async {
    return await _flutterP2pConnectionPlugin.discover();
  }

  //create group

  Future<bool> createGroup() async {
    bool enabledLocation = await permissions.isLocationEnabled();
    bool? groupFormed = wifiP2PInfo?.groupFormed;
    if (enabledLocation && (groupFormed == null || groupFormed == false)) {
      bool groupDeletion = await _flutterP2pConnectionPlugin.createGroup();
      snack("Creating group $enabledLocation,  $groupFormed, $groupDeletion");
      return groupDeletion;
    } else if (!enabledLocation) {
      snack("Please turn on Location!! $enabledLocation,  $groupFormed");
      permissions.enableLocation();
    } else if (groupFormed != null && groupFormed) {
      snack("Please remove or disconnect earlier group!!");
      return false;
    }
    // snack("Remove old group first!!!");
    return false;
  }

  //remove Group

  Future<bool> removeGroup() async {
    bool enabledLocation = await permissions.isLocationEnabled();
    bool? groupFormed = wifiP2PInfo?.groupFormed;
    if (enabledLocation && (groupFormed != null && groupFormed == true)) {
      bool groupDeletion = await _flutterP2pConnectionPlugin.removeGroup();
      snack("Removing group $enabledLocation,  $groupFormed, $groupDeletion");
      return groupDeletion;
    } else if (!enabledLocation) {
      snack("Please turn on Location!! $enabledLocation,  $groupFormed");
      permissions.enableLocation();
      return false;
    } else if (groupFormed == null || groupFormed == false) {
      snack("No group to remove!!");
      return false;
    }
    // snack("Remove old group first!!!");
    return false;
  }

  Future startSocket() async {
    if (wifiP2PInfo != null) {
      bool started = await _flutterP2pConnectionPlugin.startSocket(
        groupOwnerAddress: wifiP2PInfo!.groupOwnerAddress,
        downloadPath: "/storage/emulated/0/Download/",
        maxConcurrentDownloads: 2,
        deleteOnError: true,
        onConnect: (name, address) {
          snack("$name connected to socket with address: $address");
        },
        transferUpdate: (transfer) {
          if (transfer.completed) {
            snack(
                "${transfer.failed ? "failed to ${transfer.receiving ? "receive" : "send"}" : transfer.receiving ? "received" : "sent"}: ${transfer.filename}");
          }
          print(
              "ID: ${transfer.id}, FILENAME: ${transfer.filename}, PATH: ${transfer.path}, COUNT: ${transfer.count}, TOTAL: ${transfer.total}, COMPLETED: ${transfer.completed}, FAILED: ${transfer.failed}, RECEIVING: ${transfer.receiving}");
        },
        receiveString: (req) async {
          snack(req);
        },
      );
      snack("open socket: $started");
    }
  }

  Future connectToSocket() async {
    if (wifiP2PInfo != null) {
      await _flutterP2pConnectionPlugin.connectToSocket(
        groupOwnerAddress: wifiP2PInfo!.groupOwnerAddress,
        downloadPath: "/storage/emulated/0/Download/",
        maxConcurrentDownloads: 3,
        deleteOnError: true,
        onConnect: (address) {
          snack("connected to socket: $address");
        },
        transferUpdate: (transfer) {
          // if (transfer.count == 0) transfer.cancelToken?.cancel();
          if (transfer.completed) {
            snack(
                "${transfer.failed ? "failed to ${transfer.receiving ? "receive" : "send"}" : transfer.receiving ? "received" : "sent"}: ${transfer.filename}");
          }
          print(
              "ID: ${transfer.id}, FILENAME: ${transfer.filename}, PATH: ${transfer.path}, COUNT: ${transfer.count}, TOTAL: ${transfer.total}, COMPLETED: ${transfer.completed}, FAILED: ${transfer.failed}, RECEIVING: ${transfer.receiving}");
        },
        receiveString: (req) async {
          snack(req);
        },
      );
    }
  }

  Future closeSocketConnection() async {
    bool closed = _flutterP2pConnectionPlugin.closeSocket();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "closed: $closed",
        ),
      ),
    );
  }

  Future sendMessage() async {
    _flutterP2pConnectionPlugin.sendStringToSocket(msgText.text);
  }

  Future sendFile(bool phone) async {
    // String? filePath = await FilesystemPicker.open(
    //   context: context,
    //   rootDirectory: Directory(phone ? "/storage/emulated/0/" : "/storage/"),
    //   fsType: FilesystemType.file,
    //   fileTileSelectMode: FileTileSelectMode.wholeTile,
    //   showGoUp: true,
    //   folderIconColor: Colors.blue,
    // );
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) {
      snack("Please select a File");
      return;
    }
    PlatformFile file = result.files.first;
    if (file.path == null) {
      return;
    }
    snack("File Name: ${file.name}");
    snack("File Path: ${file.path}");
    // if (filePath == null) return;
    List<TransferUpdate>? updates =
        await _flutterP2pConnectionPlugin.sendFiletoSocket(
      [
        (file.path).toString(),
        // "/storage/emulated/0/Download/Likee_7100105253123033459.mp4",
        // "/storage/0E64-4628/Download/Adele-Set-Fire-To-The-Rain-via-Naijafinix.com_.mp3",
        // "/storage/0E64-4628/Flutter SDK/p2p_plugin.apk",
        // "/storage/emulated/0/Download/03 Omah Lay - Godly (NetNaija.com).mp3",
        // "/storage/0E64-4628/Download/Adele-Set-Fire-To-The-Rain-via-Naijafinix.com_.mp3",
      ],
    );
    print(updates);
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
                        SizedBox(
                            height:
                                20), // Add some space between text and loading animation
                        CircularProgressIndicator(),
                      ],
                    );
                  } else if (snapshot.hasError ||
                      snapshot.data == null ||
                      snapshot.data == "null") {
                    // If snapshot has error or data is null, show alert and restart the app
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      showDialog(
                        context: context,
                        barrierDismissible:
                            false, // Prevent dismissing dialog by tapping outside
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Error'),
                            content: const Text(
                                'Please restart your WiFi and open the app again.'),
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
                          style: TextStyle(fontSize: 24),
                        ),
                      ],
                    );
                  }
                },
              ),
              ElevatedButton(
                  onPressed: () async {
                    FilePickerResult? result =
                        await FilePicker.platform.pickFiles();
                    if (result != null) {
                      PlatformFile file = result.files.first;
                      print("File Name: ${file.name}\nFile Path: ${file.path}");
                      logger.d(
                          "File Name: ${file.name}\nFile Path: ${file.path}");
                      snack("File Name: ${file.name}");
                      snack("File Path: ${file.path}");
                    }
                  },
                  child: const Text("File Select"))
            ],
          ),
        ));
  }
}
