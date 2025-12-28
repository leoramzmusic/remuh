import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/utils/logger.dart';

class PermissionService {
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      PermissionStatus status;

      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+
        status = await Permission.audio.request();
      } else {
        // Android < 13
        status = await Permission.storage.request();
      }

      if (status.isGranted) {
        Logger.info('Storage/Audio permission granted');
        return true;
      } else {
        Logger.warning('Storage/Audio permission denied: $status');
        return false;
      }
    }
    return true; // iOS usually requires info.plist changes only, simpler for now
  }
}
