import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:streamer/client/video_utils.dart';
import 'package:streamer/utils/permissions.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';

class p2p_utils {
  final FlutterP2pConnection p2pObj;
  final BuildContext context;
  final Permissions permissions;
  // WifiP2PInfo? wifiP2PInfo;
  video_utils player;
  String hostIpAddress = "";

  p2p_utils({required this.p2pObj, required this.context, required this.permissions, required this.player});

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

  Future<void> discover() async {
    await p2pObj.discover();
  }

  Future<void> connectToHost(String deviceAddress) async {
    await p2pObj.connect(deviceAddress);
    logger.d("Connecting to host via a socket");
  }

  Future<void> disconnectFromHost() async {
    await p2pObj.removeGroup();
  }

  // Future<void> connectToSocket(String )

  Future<void> startSocket(String? groupOwnerAddress) async {
    if (groupOwnerAddress != null) {
      bool started = await p2pObj.startSocket(
        groupOwnerAddress: groupOwnerAddress,
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
    } else {
      logger.d("Connecting to socket...${groupOwnerAddress ?? "empty"}");
    }
  }

  Future<void> connectToSocket(String? groupOwnerAddress) async {
    if (groupOwnerAddress != null) {
      await p2pObj.connectToSocket(
        // groupOwnerAddress: wifiP2PInfo!.groupOwnerAddress,
        groupOwnerAddress: groupOwnerAddress,
        downloadPath: "/storage/emulated/0/Download/",
        maxConcurrentDownloads: 3,
        deleteOnError: true,
        onConnect: (address) {
          logger.d("connected to socket: $address");
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
          String msg = req;
          if (msg.startsWith("&VIDEO")) {
            List<String> videoData = msg.substring(6).split('|');
            hostIpAddress = videoData[0];
            int startAt = int.parse(videoData[1]);
            logger.d("MESSAGE - $hostIpAddress");
            player.startInit("http://$hostIpAddress/", startAt);
          }
        },
      );
    } else {
      logger.d("Connecting to socket...${groupOwnerAddress ?? "empty"}");
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
