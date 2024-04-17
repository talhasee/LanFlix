import 'package:flutter/material.dart';
import 'package:streamer/client/video_utils.dart';
import 'package:streamer/utils/permissions.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';

class p2p_utils {
  final FlutterP2pConnection p2pObj;
  final BuildContext context;
  final Permissions permissions;
  final WifiP2PInfo? wifiP2PInfo;
  video_utils player;
  String hostIpAddress = "";

  p2p_utils({required this.p2pObj, required this.context, required this.permissions, required this.wifiP2PInfo, required this.player});

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

  Future<bool?> connectToHost(String deviceAddress) async {
    bool? isConnected = await p2pObj.connect(deviceAddress);
    if (isConnected != null && isConnected) {
      connectToSocket();
    }
  }

  Future<void> startSocket() async {
    if (wifiP2PInfo != null) {
      bool started = await p2pObj.startSocket(
        groupOwnerAddress: wifiP2PInfo!.groupOwnerAddress,
        downloadPath: "/storage/emulated/0/Download/",
        maxConcurrentDownloads: 2,
        deleteOnError: true,
        onConnect: (name, address) {
          snack("$name connected to socket with address: $address");
        },
        transferUpdate: (transfer) {
          if (transfer.completed) {
            snack("${transfer.failed ? "failed to ${transfer.receiving ? "receive" : "send"}" : transfer.receiving ? "received" : "sent"}: ${transfer.filename}");
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

  Future<void> connectToSocket() async {
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
          if (transfer.completed) {
            snack("${transfer.failed ? "failed to ${transfer.receiving ? "receive" : "send"}" : transfer.receiving ? "received" : "sent"}: ${transfer.filename}");
          }
          print(
              "ID: ${transfer.id}, FILENAME: ${transfer.filename}, PATH: ${transfer.path}, COUNT: ${transfer.count}, TOTAL: ${transfer.total}, COMPLETED: ${transfer.completed}, FAILED: ${transfer.failed}, RECEIVING: ${transfer.receiving}");
        },
        receiveString: (req) async {
          snack(req);
          String mssg = req;
          if (mssg.startsWith("&HOST_ADDR")) {
            hostIpAddress = mssg.substring(10);
            player.startInit("http://$hostIpAddress/");
          }
        },
      );
    }
  }

  Future<void> closeSocketConnection() async {
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
