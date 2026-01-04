import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/logger.dart';

class PermissionService {
  static const String _keyPermissionGranted = 'storage_permission_granted';

  /// Check if permission was previously granted (cached)
  Future<bool> isPermissionGranted() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getBool(_keyPermissionGranted) ?? false;

    if (cached) {
      // Double-check with system to ensure it's still valid
      final systemStatus = await _checkSystemPermission();
      if (!systemStatus) {
        // Permission was revoked, update cache
        await prefs.setBool(_keyPermissionGranted, false);
        return false;
      }
      return true;
    }
    return false;
  }

  /// Check system permission status without requesting
  Future<bool> _checkSystemPermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      PermissionStatus status;

      if (androidInfo.version.sdkInt >= 33) {
        status = await Permission.audio.status;
      } else {
        status = await Permission.storage.status;
      }

      return status.isGranted;
    }
    return true;
  }

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      Logger.info('Requesting storage/audio permission...');
      final deviceInfo = DeviceInfoPlugin();

      Logger.info('Getting android info (with timeout)...');
      final androidInfo = await deviceInfo.androidInfo.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          Logger.error('DeviceInfoPlugin: androidInfo timed out after 5s');
          throw Exception('DeviceInfo timeout');
        },
      );

      Logger.info('Android SDK version: ${androidInfo.version.sdkInt}');

      PermissionStatus status;

      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+
        Logger.info('Requesting Permission.audio...');
        status = await Permission.audio.request().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            Logger.error('Permission.audio: request timed out after 10s');
            return PermissionStatus.denied;
          },
        );
      } else {
        // Android < 13
        Logger.info('Requesting Permission.storage...');
        status = await Permission.storage.request().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            Logger.error('Permission.storage: request timed out after 10s');
            return PermissionStatus.denied;
          },
        );
      }

      final granted = status.isStatusGranted;
      Logger.info('Permission request result: $status (granted: $granted)');

      // Persist permission state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPermissionGranted, granted);

      return granted;
    }
    return true;
  }

  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt >= 33) {
        final status = await Permission.notification.request();
        if (status.isStatusGranted) {
          Logger.info('Notification permission granted');
          return true;
        } else {
          Logger.warning('Notification permission denied: $status');
          return false;
        }
      }
    }
    return true;
  }
}

extension on PermissionStatus {
  bool get isStatusGranted => this == PermissionStatus.granted;
}
