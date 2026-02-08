import 'dart:convert';
import 'dart:io';
import 'package:games_services/games_services.dart' as gs;
import 'package:path_provider/path_provider.dart';
import 'game_models.dart';

class CloudSaveService {
  static const String _saveFileName = 'stellar_forge_save';

  static Future<bool> login() async {
    try {
      // First check if already signed in
      try {
        bool isAlreadySignedIn = await gs.GamesServices.isSignedIn;
        if (isAlreadySignedIn) {
          print('CloudSave: Already signed in');
          return true;
        }
      } catch (e) {
        // Some devices or plugin states may throw when querying sign-in status.
        // Don't abort — attempt an interactive sign-in anyway.
        print('CloudSave: Failed to check sign-in status: $e');
        print('CloudSave: Proceeding to attempt interactive sign-in.');
      }
      
      print('CloudSave: Not signed in, attempting sign-in...');
      print('CloudSave: Please complete the Google Play Games sign-in process');
      
      // Request sign-in - this will show the Google Play Games dialog
      try {
        await gs.GamesServices.signIn();
        print('CloudSave: Sign-in method called successfully');
      } catch (signInError) {
        print('CloudSave: Sign-in threw exception: $signInError');
        return false;
      }
      
      // Wait longer for sign-in to complete and persist
      await Future.delayed(const Duration(seconds: 3));
      
      bool signedIn = await gs.GamesServices.isSignedIn;
      print('CloudSave: After sign-in, isSignedIn = $signedIn');
      
      if (!signedIn) {
        print('CloudSave: Sign-in dialog was dismissed or user clicked back');
        print('CloudSave: Verify Google Play Games is installed on your device');
        return false;
      }
      
      print('CloudSave: Successfully signed in to Google Play Games!');
      return true;
    } catch (e) {
      print('CloudSave: Unexpected error during sign in: $e');
      return false;
    }
  }

  static Future<bool> saveGame(GameState state) async {
    try {
      final Map<String, dynamic> data = {
        'currentWorld': state.currentWorld,
        'unlockedWorlds': state.unlockedWorlds,
        'unlockedAchievements': state.unlockedAchievements,
        'logs': state.logs,
        'clicks': state.clicks,
        'cometsClicked': state.cometsClicked,
        'prestigeCount': state.prestigeCount,
        'resources': state.resources.map((key, value) => MapEntry(key, value.toJson())),
        'upgrades': state.upgrades.map((u) => u.toJson()).toList(),
        'playTime': state.playTime,
        'lastSave': DateTime.now().millisecondsSinceEpoch,
      };

      final String encoded = jsonEncode(data);

      // Try to save to cloud first if signed in, otherwise save locally
      bool signedIn = false;
      try {
        signedIn = await gs.GamesServices.isSignedIn;
      } catch (e) {
        signedIn = false;
      }

      if (signedIn) {
        try {
          await gs.GamesServices.saveGame(data: encoded, name: _saveFileName);
          print('CloudSave: Game saved to cloud successfully');
          // also save a local copy as backup
          await _saveLocalCopy(encoded);
          return true;
        } catch (e) {
          print('CloudSave: Cloud save failed, falling back to local: $e');
          return await _saveLocalCopy(encoded);
        }
      } else {
        // Not signed in - save locally
        return await _saveLocalCopy(encoded);
      }
    } catch (e) {
      print('CloudSave: Save failed: $e');
      return false;
    }
  }

  static Future<bool> _saveLocalCopy(String encoded) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_saveFileName.json');
      await file.writeAsString(encoded);
      print('CloudSave: Game saved locally at ${file.path}');
      return true;
    } catch (e) {
      print('CloudSave: Local save failed: $e');
      return false;
    }
  }

  static Future<GameState?> loadGame() async {
    try {
      // Try cloud load if signed in, otherwise fall back to local copy
      bool signedIn = false;
      try {
        signedIn = await gs.GamesServices.isSignedIn;
      } catch (e) {
        signedIn = false;
      }

      String? data;
      if (signedIn) {
        try {
          data = await gs.GamesServices.loadGame(name: _saveFileName);
        } catch (e) {
          print('CloudSave: Cloud load failed: $e');
          data = null;
        }
      }

      // If no cloud data, try local file
      if (data == null || data.isEmpty) {
        try {
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/$_saveFileName.json');
          if (await file.exists()) {
            data = await file.readAsString();
            print('CloudSave: Loaded local save from ${file.path}');
          }
        } catch (e) {
          print('CloudSave: Local load failed: $e');
        }
      }

      if (data != null && data.isNotEmpty) {
        final Map<String, dynamic> parsed = jsonDecode(data);
        
        final GameState newState = getInitialState();
        
        newState.currentWorld = parsed['currentWorld'];
        newState.unlockedWorlds = List<String>.from(parsed['unlockedWorlds']);
        newState.unlockedAchievements = List<String>.from(parsed['unlockedAchievements']);
        newState.logs = List<Map<String, dynamic>>.from(parsed['logs']);
        newState.clicks = parsed['clicks'];
        newState.cometsClicked = parsed['cometsClicked'];
        newState.prestigeCount = parsed['prestigeCount'];
        newState.playTime = (parsed['playTime'] as num).toDouble();
        
        final Map<String, dynamic> resMap = parsed['resources'];
        resMap.forEach((key, value) {
          if (newState.resources.containsKey(key)) {
            newState.resources[key] = Resource.fromJson(value);
          }
        });
        
        final List<dynamic> upList = parsed['upgrades'];
        for (var uData in upList) {
          final String id = uData['id'];
          final int level = uData['level'];
          final upgrade = newState.upgrades.firstWhere((u) => u.id == id, orElse: () => newState.upgrades.first);
          if (upgrade.id == id) {
            upgrade.level = level;
          }
        }
        
        print('CloudSave: Game loaded successfully');
        return newState;
      } else {
        print('CloudSave: No save data found');
      }
    } catch (e) {
      print('CloudSave: Load failed: $e');
    }
    return null;
  }

  static Future<void> unlockAchievement(String achievementId) async {
    try {
      bool signedIn = await gs.GamesServices.isSignedIn;
      if (signedIn) {
        final googlePlayId = AppConfig.achievementIds[achievementId] ?? achievementId;
        await gs.GamesServices.unlock(
            achievement: gs.Achievement(androidID: googlePlayId));
        print('CloudSave: Unlocked achievement $googlePlayId on Google Play');
      }
    } catch (e) {
      print('CloudSave: Failed to unlock achievement on Google Play: $e');
    }
  }

  static Future<void> showAchievements() async {
    try {
      bool signedIn = await gs.GamesServices.isSignedIn;
      if (signedIn) {
        await gs.GamesServices.showAchievements();
      } else {
        await login();
        if (await gs.GamesServices.isSignedIn) {
          await gs.GamesServices.showAchievements();
        }
      }
    } catch (e) {
      print('CloudSave: Failed to show achievements: $e');
    }
  }
}
