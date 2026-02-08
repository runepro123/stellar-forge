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
  String _status = '';
  String? _currentOperation = ''; // 'downloading', 'extracting', 'ready'
  http.StreamedResponse? _currentResponse;
  bool _updateCancelled = false;
  String? _releaseNotes;

  bool get isChecking => _isChecking;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String? get newVersion => _newVersion;
  bool get updateReady => _updateReady;
  String get status => _status;
  String? get currentOperation => _currentOperation;
  String? get releaseNotes => _releaseNotes;
  bool get updateCancelled => _updateCancelled;

  Future<void> checkForUpdates() async {
    if (kIsWeb || _isChecking || _isDownloading || _updateReady) return;

    _isChecking = true;
    _status = 'Checking for updates...';
    notifyListeners();

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$githubUser/$githubRepo/releases/latest'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = (data['tag_name'] as String).replaceAll('v', '');
        _releaseNotes = data['body'] ?? 'No release notes available';
        
        if (_isVersionNewer(currentVersion, latestVersion)) {
          _newVersion = latestVersion;
          final assets = data['assets'] as List;
          String platformSuffix = Platform.isWindows ? 'windows' : 'linux';
          
          final updateAsset = assets.firstWhere(
            (asset) => (asset['name'] as String).toLowerCase().contains(platformSuffix) && 
                       (asset['name'] as String).endsWith('.zip'),
            orElse: () => null,
          );

          if (updateAsset != null) {
            _downloadUrl = updateAsset['browser_download_url'];
            _status = 'Update available: v$_newVersion';
            _currentOperation = 'ready';
            notifyListeners();
            startDownload();
          } else {
            _status = 'No compatible update found';
          }
        } else {
          _status = 'You are up to date!';
          _currentOperation = null;
        }
      } else {
        _status = 'Failed to check updates (${response.statusCode})';
      }
    } catch (e) {
      _status = 'Update check failed: $e';
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
    _updateCancelled = false;
    _currentOperation = 'downloading';
    _status = 'Downloading update...';
    notifyListeners();

    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(_downloadUrl!));
      _currentResponse = await client.send(request);
      final contentLength = _currentResponse!.contentLength;

      List<int> bytes = [];
      await _currentResponse!.stream.listen(
        (List<int> newBytes) {
          if (!_updateCancelled) {
            bytes.addAll(newBytes);
            if (contentLength != null && contentLength > 0) {
              _downloadProgress = bytes.length / contentLength;
              _status = 'Downloading: ${(downloadProgress * 100).toStringAsFixed(1)}%';
              notifyListeners();
            }
          }
        },
        onDone: () async {
          if (!_updateCancelled) {
            await _prepareUpdate(bytes);
          } else {
            _isDownloading = false;
            _currentOperation = null;
            _status = 'Update cancelled';
            notifyListeners();
          }
        },
        onError: (e) {
          _status = 'Download error: $e';
          _isDownloading = false;
          _currentOperation = null;
          notifyListeners();
        },
        cancelOnError: true,
      ).asFuture();
    } catch (e) {
      _status = 'Download failed: $e';
      _isDownloading = false;
      _currentOperation = null;
      debugPrint('Download failed: $e');
      notifyListeners();
    }
  }

  void cancelUpdate() {
    _updateCancelled = true;
    _currentResponse?.stream.listen((data) {}).cancel();
    _isDownloading = false;
    _currentOperation = null;
    _status = 'Update cancelled';
    notifyListeners();
  }

  Future<void> _prepareUpdate(List<int> bytes) async {
    try {
      _currentOperation = 'extracting';
      _status = 'Extracting files...';
      _downloadProgress = 0;
      notifyListeners();

      final tempDir = await getTemporaryDirectory();
      final updateDir = Directory(p.join(tempDir.path, 'update_temp'));
      if (updateDir.existsSync()) updateDir.deleteSync(recursive: true);
      updateDir.createSync();

      final archive = ZipDecoder().decodeBytes(bytes);
      int filesExtracted = 0;
      int totalFiles = archive.length;

      for (final file in archive) {
        if (_updateCancelled) break;
        
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File(p.join(updateDir.path, filename))
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory(p.join(updateDir.path, filename)).createSync(recursive: true);
        }
        
        filesExtracted++;
        _downloadProgress = filesExtracted / totalFiles;
        _status = 'Extracting: ${(downloadProgress * 100).toStringAsFixed(0)}%';
        notifyListeners();
      }

      if (!_updateCancelled) {
        _isDownloading = false;
        _updateReady = true;
        _currentOperation = 'ready';
        _status = 'Update ready! Click restart to apply.';
      } else {
        _isDownloading = false;
        _updateReady = false;
        _currentOperation = null;
        _status = 'Update cancelled during extraction';
      }
      notifyListeners();
    } catch (e) {
      _status = 'Extraction failed: $e';
      _isDownloading = false;
      _currentOperation = null;
      debugPrint('Prepare update failed: $e');
      notifyListeners();
    }
  }

  Future<void> applyUpdateAndRestart() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final updateDir = p.join(tempDir.path, 'update_temp');
      final appDir = File(Platform.resolvedExecutable).parent.path;

      if (Platform.isWindows) {
        final batchPath = p.join(tempDir.path, 'update.bat');
        final script = '''@echo off
REM Update script generated by Stellar Forge Updater
timeout /t 2 /nobreak > nul
echo Applying update...
xcopy /s /y "$updateDir\\*" "$appDir\\"
echo Update complete!
start "" "${Platform.resolvedExecutable}"
timeout /t 1 /nobreak > nul
del /q "%~f0"
''';
        await File(batchPath).writeAsString(script);
        await Process.start('cmd.exe', ['/c', batchPath], mode: ProcessStartMode.detached);
      } else if (Platform.isLinux) {
        final shPath = p.join(tempDir.path, 'update.sh');
        final script = '''#!/bin/bash
# Update script generated by Stellar Forge Updater
sleep 2
echo "Applying update..."
cp -r "$updateDir"/* "$appDir/"
echo "Update complete!"
"${Platform.resolvedExecutable}" &
sleep 1
rm "\$0"
''';
        await File(shPath).writeAsString(script);
        await Process.start('bash', [shPath], mode: ProcessStartMode.detached);
      }
      
      exit(0);
    } catch (e) {
      _status = 'Failed to apply update: $e';
      notifyListeners();
    }
  }
}
