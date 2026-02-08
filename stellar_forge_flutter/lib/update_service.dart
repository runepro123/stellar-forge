import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart';

class UpdateService extends ChangeNotifier {
  final String githubUser = 'runepro123'; // To be replaced or configured
  final String githubRepo = 'stellar-forge'; // To be replaced or configured

  bool _isChecking = false;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String? _newVersion;
  String? _downloadUrl;
  bool _updateReady = false;

  bool get isChecking => _isChecking;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String? get newVersion => _newVersion;
  bool get updateReady => _updateReady;

  Future<void> checkForUpdates() async {
    if (kIsWeb || _isChecking || _isDownloading || _updateReady) return;

    _isChecking = true;
    notifyListeners();

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$githubUser/$githubRepo/releases/latest'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = (data['tag_name'] as String).replaceAll('v', '');
        
        if (_isVersionNewer(currentVersion, latestVersion)) {
          _newVersion = latestVersion;
          // Look for windows/linux zip assets
          final assets = data['assets'] as List;
          String platformSuffix = Platform.isWindows ? 'windows' : 'linux';
          
          final updateAsset = assets.firstWhere(
            (asset) => (asset['name'] as String).toLowerCase().contains(platformSuffix) && 
                       (asset['name'] as String).endsWith('.zip'),
            orElse: () => null,
          );

          if (updateAsset != null) {
            _downloadUrl = updateAsset['browser_download_url'];
            startDownload();
          }
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  bool _isVersionNewer(String current, String latest) {
    List<int> c = current.split('.').map(int.parse).toList();
    List<int> l = latest.split('.').map(int.parse).toList();
    for (int i = 0; i < c.length && i < l.length; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return l.length > c.length;
  }

  Future<void> startDownload() async {
    if (_downloadUrl == null) return;

    _isDownloading = true;
    _downloadProgress = 0;
    notifyListeners();

    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(_downloadUrl!));
      final response = await client.send(request);
      final contentLength = response.contentLength;

      List<int> bytes = [];
      await response.stream.listen(
        (List<int> newBytes) {
          bytes.addAll(newBytes);
          if (contentLength != null) {
            _downloadProgress = bytes.length / contentLength;
            notifyListeners();
          }
        },
        onDone: () async {
          await _prepareUpdate(bytes);
        },
        onError: (e) {
          throw e;
        },
        cancelOnError: true,
      ).asFuture();
    } catch (e) {
      debugPrint('Download failed: $e');
      _isDownloading = false;
      notifyListeners();
    }
  }

  Future<void> _prepareUpdate(List<int> bytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final updateDir = Directory(p.join(tempDir.path, 'update_temp'));
      if (updateDir.existsSync()) updateDir.deleteSync(recursive: true);
      updateDir.createSync();

      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File(p.join(updateDir.path, filename))
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory(p.join(updateDir.path, filename)).createSync(recursive: true);
        }
      }

      _isDownloading = false;
      _updateReady = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Prepare update failed: $e');
      _isDownloading = false;
      notifyListeners();
    }
  }

  Future<void> applyUpdateAndRestart() async {
    final tempDir = await getTemporaryDirectory();
    final updateDir = p.join(tempDir.path, 'update_temp');
    final appDir = File(Platform.resolvedExecutable).parent.path;

    String script;
    if (Platform.isWindows) {
      final batchPath = p.join(tempDir.path, 'update.bat');
      script = '''
@echo off
timeout /t 2 /nobreak > nul
xcopy /s /y "$updateDir\\*" "$appDir\\"
start "" "${Platform.resolvedExecutable}"
del "%~f0"
''';
      await File(batchPath).writeAsString(script);
      await Process.start('cmd.exe', ['/c', batchPath], mode: ProcessStartMode.detached);
    } else if (Platform.isLinux) {
      final shPath = p.join(tempDir.path, 'update.sh');
      script = '''
#!/bin/bash
sleep 2
cp -r "$updateDir"/* "$appDir/"
"${Platform.resolvedExecutable}" &
rm "\$0"
''';
      await File(shPath).writeAsString(script);
      await Process.start('bash', [shPath], mode: ProcessStartMode.detached);
    }
    
    exit(0);
  }
}
