library forceupdate;

import 'package:forceupdate/app_Info.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';

class AppVersionStatus {
  bool canUpdate;
  String localVersion;
  String storeVersion;
  AppVersionStatus({this.canUpdate, this.localVersion, this.storeVersion});
}

class CheckVersion {
  BuildContext context;
  String androidId;
  String iOSId;

  CheckVersion({this.androidId, this.iOSId, @required this.context})
      : assert(context != null);

  Future<AppVersionStatus> getVersionStatus(
      {bool checkInNotEqual = true, bool checkInBigger = false}) async {
    AppInfo packageInfo = await AppInfo.info();
    AppVersionStatus versionStatus = AppVersionStatus(
      localVersion: packageInfo.version,
    );
    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
        final id = iOSId ?? packageInfo.packageName;
        versionStatus = await getiOSAtStoreVersion(id, versionStatus);
        break;
      case TargetPlatform.android:
        final id = androidId ?? packageInfo.packageName;
        versionStatus = await getAndroidAtStoreVersion(id, versionStatus);
        break;
      default:
        print("This platform is not yet supported by this package.");
    }
    if (versionStatus == null) {
      return null;
    }
    List storeVersion = versionStatus.storeVersion.split(".");
    List currentVersion = versionStatus.localVersion.split(".");
    if(storeVersion.length < currentVersion.length){
      int missValues = currentVersion.length - storeVersion.length;
      for(int i = 0 ; i<missValues; i++){
        storeVersion[storeVersion.length] = 0;
      }
    }
    else if(storeVersion.length > currentVersion.length){
      int missValues = storeVersion.length - currentVersion.length;
      for(int i = 0 ; i<missValues; i++){
        currentVersion[currentVersion.length] = 0;
      }
    }

    if (checkInBigger) {
      for(int i = 0;i<storeVersion.length;i++){
        if(storeVersion[i] > currentVersion[i]){
          versionStatus.canUpdate = true;
          return versionStatus;
        }
      }
    }
    versionStatus.canUpdate =
        versionStatus.storeVersion != versionStatus.localVersion;
    return versionStatus;
  }

  alertIfAvailable() async {
    AppVersionStatus versionStatus = await getVersionStatus();
    if (versionStatus != null && versionStatus.canUpdate) {
      showUpdateDialog(versionStatus: versionStatus);
    }
  }
  getiOSAtStoreVersion(String appId /**app id in apple store not app bundle id*/,
      AppVersionStatus versionStatus) async {
    final response = await http.get('http://itunes.apple.com/lookup?bundleId=$appId');
    if (response.statusCode != 200) {
      print('The app with id: $appId is not found in app store');
      return null;
    }
    final jsonObj = jsonDecode(response.body);
    versionStatus.storeVersion = jsonObj['results'][0]['version'];
    return versionStatus;
  }

  getAndroidAtStoreVersion(
      String applicationId /**application id, generally stay in build.gradle*/,
      AppVersionStatus versionStatus) async {
    final response = await http.get('https://play.google.com/store/apps/details?id=$applicationId');
    if (response.statusCode != 200) {
      print('The app with application id: $applicationId is not found in play store');
      return null;
    }
    final document = parse(response.body);
    final elements = document.getElementsByClassName('hAyfc');
    final versionElement = elements.firstWhere(
      (elm) => elm.querySelector('.BgcNfc').text == 'Current Version',
    );
    versionStatus.storeVersion = versionElement.querySelector('.htlgb').text;
    return versionStatus;
  }

  void showUpdateDialog({
    AppVersionStatus versionStatus,
    String message = "You can now update this app from store.",
    String titleText = 'Update Available',
    String dismissText = 'Later',
    String updateText = 'Update Now',
  }) async {
    Text title = Text(titleText);
    final content = Text(message);
    Text dismiss = Text(dismissText);
    final dismissAction = () => Navigator.pop(context);
    Text update = Text(updateText);
    final updateAction = () {
      _launchAppStore();
      Navigator.pop(context);
    };
    final platform = Theme.of(context).platform;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return platform == TargetPlatform.android
            ? AlertDialog(
                title: title,
                content: content,
                actions: <Widget>[
                  FlatButton(
                    child: dismiss,
                    onPressed: dismissAction,
                  ),
                  FlatButton(
                    child: update,
                    onPressed: updateAction,
                  ),
                ],
              )
            : CupertinoAlertDialog(
                title: title,
                content: content,
                actions: <Widget>[
                  CupertinoDialogAction(
                    child: dismiss,
                    onPressed: dismissAction,
                  ),
                  CupertinoDialogAction(
                    child: update,
                    onPressed: updateAction,
                  ),
                ],
              );
      },
    );
  }

  void _launchAppStore() async {
    OpenAppstore.launch();
  }
}

class OpenAppstore {
  static const MethodChannel _channel =
      const MethodChannel('flutter.moum.open_appstore');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static void launch() async {
    await _channel.invokeMethod('openappstore', {
      'android_id': "com.bronx.membership.davane",
      'ios_id': "id1517061508"
    });
  }
}
