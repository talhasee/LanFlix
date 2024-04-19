import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:streamer/utils/permissions.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';

class p2p_utils {
  final FlutterP2pConnection p2pObj;
  final BuildContext context;
  final Permissions permissions;
  WifiP2PInfo? wifiP2PInfo;

  p2p_utils({required this.p2pObj, required this.context, required this.permissions, required this.wifiP2PInfo});

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

  Future<bool> discover() async {
    return await p2pObj.discover();
  }

  var logger = Logger(
    printer: PrettyPrinter(),
  );

  Future<bool> createGroup() async {
    bool enabledLocation = await permissions.isLocationEnabled();
    bool? groupFormed = wifiP2PInfo?.groupFormed;
    if (enabledLocation && (groupFormed == null || groupFormed == false)) {
      bool groupDeletion = await p2pObj.createGroup();
      // snack("Creating group $enabledLocation,  $groupFormed, $groupDeletion");
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

  Future<bool> removeGroup() async {
    bool enabledLocation = await permissions.isLocationEnabled();
    bool? groupFormed = wifiP2PInfo?.groupFormed;
    if (enabledLocation && (groupFormed != null && groupFormed == true)) {
      bool groupDeletion = await p2pObj.removeGroup();
      // snack("Removing group $enabledLocation,  $groupFormed, $groupDeletion");
      return groupDeletion;
    } else if (!enabledLocation) {
      snack("Please turn on Location!!");
      permissions.enableLocation();
      return false;
    } else if (groupFormed == null || groupFormed == false) {
      snack("No group to remove!!");
      return false;
    }
    // snack("Remove old group first!!!");
    return false;
  }

  Future<void> startSocket() async {
    if (wifiP2PInfo == null) logger.d("wifip2p is null");
    if (wifiP2PInfo != null) {
      logger.d("Starting socket.....");
      bool started = await p2pObj.startSocket(
        groupOwnerAddress: wifiP2PInfo!.groupOwnerAddress,
        downloadPath: "/storage/emulated/0/Download/",
        maxConcurrentDownloads: 2,
        deleteOnError: true,
        onConnect: (name, address) {
          logger.d("$name connected to socket with address: $address");
          // snack("$name connected to socket with address: $address");
        },
        transferUpdate: (transfer) {
          // if (transfer.completed) {
          //   snack("${transfer.failed ? "failed to ${transfer.receiving ? "receive" : "send"}" : transfer.receiving ? "received" : "sent"}: ${transfer.filename}");
          // }
          // print(
          //     "ID: ${transfer.id}, FILENAME: ${transfer.filename}, PATH: ${transfer.path}, COUNT: ${transfer.count}, TOTAL: ${transfer.total}, COMPLETED: ${transfer.completed}, FAILED: ${transfer.failed}, RECEIVING: ${transfer.receiving}");
        },
        receiveString: (req) async {
          // snack(req);
        },
      );
      // snack("open socket: $started");
    }
  }

  Future connectToSocket() async {
    if (wifiP2PInfo != null) {
      await p2pObj.connectToSocket(
        groupOwnerAddress: wifiP2PInfo!.groupOwnerAddress,
        downloadPath: "/storage/emulated/0/Download/",
        maxConcurrentDownloads: 3,
        deleteOnError: true,
        onConnect: (address) {
          snack("connected to socket: $address");
        },
        transferUpdate: (transfer) {
          // if (transfer.count == 0) transfer.cancelToken?.cancel();
          // if (transfer.completed) {
          //   snack("${transfer.failed ? "failed to ${transfer.receiving ? "receive" : "send"}" : transfer.receiving ? "received" : "sent"}: ${transfer.filename}");
          // }
          // print(
          //     "ID: ${transfer.id}, FILENAME: ${transfer.filename}, PATH: ${transfer.path}, COUNT: ${transfer.count}, TOTAL: ${transfer.total}, COMPLETED: ${transfer.completed}, FAILED: ${transfer.failed}, RECEIVING: ${transfer.receiving}");
        },
        receiveString: (req) async {
          // snack(req);
        },
      );
    }
  }

  Future closeSocketConnection() async {
    bool closed = p2pObj.closeSocket();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "closed: $closed",
        ),
      ),
    );
  }
}
