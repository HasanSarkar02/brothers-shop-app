import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

class UpdateService {
  final Dio _dio = Dio();

  static const String _versionUrl =
      'https://raw.githubusercontent.com/HasanSarkar02/brothers-app-update/refs/heads/main/app-version.json';

  // ── Version check ──────────────────────────────────
  Future<void> checkForUpdate(
    Function(String downloadUrl) onUpdateAvailable,
  ) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      print('📱 Current version: $currentVersion');

      final response = await _dio.get(
        _versionUrl,
        options: Options(
          headers: {'Cache-Control': 'no-cache'},
          responseType: ResponseType.plain,
        ),
      );

      final Map<String, dynamic> data = json.decode(response.data as String);

      final latestVersion = data['latest_version']?.toString() ?? '';
      final apkUrl = data['apk_url']?.toString() ?? '';

      if (latestVersion.isEmpty || apkUrl.isEmpty) {
        return;
      }

      if (_isNewerVersion(latestVersion, currentVersion)) {
        onUpdateAvailable(apkUrl);
      } else {}
    } catch (e) {}
  }

  // ── Version comparison ─────────────────────────────
  // "1.0.2" > "1.0.1" → true
  bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();

      // List কে same length করো
      while (latestParts.length < 3) latestParts.add(0);
      while (currentParts.length < 3) currentParts.add(0);

      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (e) {
      return latest != current;
    }
  }

  // ── Download & Install ─────────────────────────────
  Future<void> downloadAndInstallUpdate({
    required String apkUrl,
    required Function(int progress) onProgress,
    required Function() onDownloadComplete,
    required Function(String error) onError,
  }) async {
    try {
      // ১. Storage permission চাও
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          // Android 13+ এ storage permission দরকার নেই
          // শুধু install permission check করো
        }

        // Install unknown apps permission
        final installStatus = await Permission.requestInstallPackages.status;
        if (!installStatus.isGranted) {
          await Permission.requestInstallPackages.request();
        }
      }

      // Save path
      Directory? dir;
      if (Platform.isAndroid) {
        dir =
            await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final savePath = '${dir.path}/brothers_update.apk';

      await _dio.download(
        apkUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = ((received / total) * 100).toInt();
            onProgress(progress);
          }
        },
        options: Options(receiveTimeout: const Duration(minutes: 10)),
      );
      onDownloadComplete();

      //  Install
      await Future.delayed(const Duration(milliseconds: 500));
      final result = await OpenFilex.open(
        savePath,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done) {
        onError('Failed to open installer: ${result.message}');
      }
    } catch (e) {
      onError(e.toString());
    }
  }
}

// ── Provider ───────────────────────────────────────
final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});
