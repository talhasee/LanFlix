import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';

class Permissions {
  final FlutterP2pConnection p2pObj;
  final BuildContext context;

  Permissions({required this.p2pObj, required this.context});

  Future<String?> getAndroidVersion() async {
    AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
    return androidInfo.version.release;
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

  //Check Location Enabled
  Future<bool> isLocationEnabled() async {
    return (await p2pObj.checkLocationEnabled());
  }

  //Enable Location
  Future<bool> enableLocation() async {
    //First check Location Permission and it is enabled or not
    return (await p2pObj.enableLocationServices());
  }

  //Ask Location Permssion
  Future<bool> askLocationPermission() async {
    return (await p2pObj.askLocationPermission());
  }

  //Check Wifi Enabled
  Future<bool> isWifiEnabled() async {
    return (await p2pObj.checkWifiEnabled());
  }

  //Enable Wifi
  Future<bool> enableWifi() async {
    //First check if it is enabled or not
    return (await p2pObj.enableWifiServices());
  }

  //Ask Storage Permission
  Future<bool> askStoragePermission() async {
    return (await p2pObj.askStoragePermission());
  }

  //Enable enarby devices
  Future<bool> enableNearbyDevices() async {
    return (await Permission.nearbyWifiDevices.request().isGranted);
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
    bool location = await locationPermission() &&
        (await isLocationEnabled() ? true : await enableLocation());
    bool wifi = await wifiPermission() &&
        (await isWifiEnabled() ? true : await enableWifi());
    bool storage = await storagePermission();
    bool nearbyDevices = int.parse(await getAndroidVersion() ?? '0') >= 12
        ? await enableNearbyDevices()
        : true;
    snack(
        "location $location,wifi $wifi, storage $storage, nearby $nearbyDevices");
    return location && wifi && storage && nearbyDevices;
  }
}
