import 'dart:io';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';

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
  List<DiscoveredPeers> peers = [];
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flutterP2pConnectionPlugin.unregister();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _flutterP2pConnectionPlugin.unregister();
    } else if (state == AppLifecycleState.resumed) {
      _flutterP2pConnectionPlugin.register();
    }
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

    //check location, wifi and Storage permission
    checkPermissions();

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
    bool? created = await createGroup();

    snack("CREATION1 $created");
    await Future.delayed(const Duration(seconds: 2));
    if (created != null && !created) {
      bool? removed = await removeGroup();
    }

    await Future.delayed(const Duration(seconds: 2));
    bool? createdAgain = await createGroup();
    snack("CREATION2 $createdAgain");
    await Future.delayed(const Duration(seconds: 2));

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

  //Check Location Enabled
  Future<bool> isLocationEnabled() async {
    return (await _flutterP2pConnectionPlugin.checkLocationEnabled());
  }

  //Check Wifi Enabled
  Future<bool> isWifiEnabled() async {
    return (await _flutterP2pConnectionPlugin.checkWifiEnabled());
  }

  //Ask Location Permssion

  Future<bool> askLocationPermission() async {
    return (await _flutterP2pConnectionPlugin.askLocationPermission());
  }

  //Ask Storage Permission

  Future<bool> askStoragePermission() async {
    return (await _flutterP2pConnectionPlugin.askStoragePermission());
  }

  //Enable Location

  Future<bool> enableLocation() async {
    //First check Location Permission and it is enabled or not
    return (await _flutterP2pConnectionPlugin.enableLocationServices());
  }

  //Enable Wifi

  Future<bool> enableWifi() async {
    //First check if it is enabled or not
    return (await _flutterP2pConnectionPlugin.enableWifiServices());
  }

  Future<bool> locationPermission() async {
    bool location = false;
    await askLocationPermission().then((locationPermission) async {
      if (!locationPermission) {
        snack("Please provide Location Permission to continue");
      } else {
        await isLocationEnabled().then((locationEnabled) async {
          //if location not Enabled ask user to turn it on
          if (!locationEnabled) {
            await enableLocation().then((locationOn) {
              if (!locationOn) {
                snack("Please turn on the location to continue");
              } else {
                location = locationOn;
              }
            });
          } else {
            location = locationEnabled;
          }
        });
      }
    }).catchError((error) {
      throw Exception('Error in Location: $error');
    });
    return location;
  }

  Future<bool> wifiPermission() async {
    bool wifi = false;
    await isWifiEnabled().then((wifiEnabled) async {
      if (!wifiEnabled) {
        await enableWifi().then((wifiOn) {
          if (!wifiOn) {
            snack("Please turn on Wifi to continue....");
          } else {
            // snack("wifi is on");
            wifi = wifiOn;
          }
        });
      } else {
        wifi = wifiEnabled;
      }
    }).catchError((error) {
      throw Exception('Error in Wifi: $error');
    });

    return wifi;
  }

  Future<bool> storagePermission() async {
    bool storage = false;
    await askStoragePermission().then((storageEnabled) {
      if (!storageEnabled) {
        snack("Please give storage permission for selecting video files");
      } else {
        storage = storageEnabled;
      }
    }).catchError((error) {
      throw Exception("Storage Error: $error");
    });

    return storage;
  }

  Future<bool> checkPermissions() async {
    //checking location permission
    bool location = await locationPermission();
    bool wifi = await wifiPermission();
    bool storage = await storagePermission();
    snack("$location, $wifi, $storage");
    return location && wifi && storage;
  }

  //Get Clients
  List getClients() {
    List clientsList = [];
    if (wifiP2PInfo != null) {
      for (var clients in wifiP2PInfo!.clients) {
        clientsList.add(clients.deviceName);
      }
      return clientsList;
    } else {
      return [];
    }
  }

  //create group

  Future<bool> createGroup() async {
    bool location = await askLocationPermission();
    bool wifi = await isWifiEnabled();

    if (location && wifi) {
      bool enabledLocation = await isLocationEnabled();
      bool? groupFormed = wifiP2PInfo?.groupFormed;
      if (enabledLocation && (groupFormed == null || groupFormed == false)) {
        bool groupDeletion = await _flutterP2pConnectionPlugin.createGroup();
        snack("Creating group $enabledLocation,  $groupFormed, $groupDeletion");
        return groupDeletion;
      } else if (!enabledLocation) {
        snack("Please turn on Location!! $enabledLocation,  $groupFormed");
        enableLocation();
      } else if (groupFormed != null && groupFormed) {
        snack("Please remove or disconnect earlier group!!");
        return false;
      }
    } else {
      if (!location) {
        askLocationPermission();
        bool enabledLocation = await isLocationEnabled();
        if (!enabledLocation) {
          snack("Please enable Location first!!!");
          enableLocation();
          return false;
        }
      }
      if (!wifi) {
        snack("Please enable Wifi!!");
        enableWifi();
      }
      return false;
    }
    // snack("Remove old group first!!!");
    return false;
  }

  //remove Group

  Future<bool> removeGroup() async {
    bool location = await askLocationPermission();
    bool wifi = await isWifiEnabled();

    if (location && wifi) {
      bool enabledLocation = await isLocationEnabled();
      bool? groupFormed = wifiP2PInfo?.groupFormed;
      if (enabledLocation && (groupFormed != null && groupFormed == true)) {
        bool groupDeletion = await _flutterP2pConnectionPlugin.removeGroup();
        snack("Removing group $enabledLocation,  $groupFormed, $groupDeletion");
        return groupDeletion;
      } else if (!enabledLocation) {
        snack("Please turn on Location!! $enabledLocation,  $groupFormed");
        enableLocation();
        return false;
      } else if (groupFormed == null || groupFormed == false) {
        snack("No group to remove!!");
        return false;
      }
    } else {
      if (!location) {
        askLocationPermission();
        bool enabledLocation = await isLocationEnabled();
        if (!enabledLocation) {
          snack("Please enable Location first!!!");
          enableLocation();
        }
      }
      if (!wifi) {
        snack("Please enable Wifi!!");
        enableWifi();
      }
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
    String? filePath = await FilesystemPicker.open(
      context: context,
      rootDirectory: Directory(phone ? "/storage/emulated/0/" : "/storage/"),
      fsType: FilesystemType.file,
      fileTileSelectMode: FileTileSelectMode.wholeTile,
      showGoUp: true,
      folderIconColor: Colors.blue,
    );
    if (filePath == null) return;
    List<TransferUpdate>? updates =
        await _flutterP2pConnectionPlugin.sendFiletoSocket(
      [
        filePath,
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
                  } else if (snapshot.hasError) {
                    return Text(
                        style: TextStyle(fontSize: 24),
                        'Error during group creation: ${snapshot.error}');
                  } else {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Group Owner Address',
                          style: TextStyle(fontSize: 24),
                        ),
                        const SizedBox(
                            height:
                                20),
                         Text(
                          '${snapshot.data}',
                          style: TextStyle(fontSize: 24),
                        ),
                      ],
                    );
                  }
                },
              ),

              // Text("Host Ip: ${groupCreation()}"),
              // // ignore: prefer_const_constructors
              // Text("Device Name: ${wifiP2PInfo?.groupOwnerAddress}"),
            ],
          ),
        ));
  }
}
