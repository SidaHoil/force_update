import 'dart:async';
import 'package:flutter/services.dart';

const MethodChannel _kChannel =
MethodChannel('plugins.flutter.io/package_info');
class AppInfo {
  static AppInfo _appInfo;
  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;
  
  AppInfo({
    this.version,
    this.buildNumber,
    this.appName,
    this.packageName,
  });
  
  static Future<AppInfo> info() async {
    if (_appInfo != null) {
      return _appInfo;
    }

    final Map<String, dynamic> map =
    await _kChannel.invokeMapMethod<String, dynamic>('getAll');
    _appInfo = AppInfo(
      appName: map["appName"],
      packageName: map["packageName"],
      version: map["version"],
      buildNumber: map["buildNumber"],
    );
    return _appInfo;
  }

  
}
