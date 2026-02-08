import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'game_models.dart';

@JS('window.crazyGames.saveData')
external JSPromise<JSBoolean> _jsSaveData(JSString data);

@JS('window.crazyGames.loadData')
external JSPromise<JSString?> _jsLoadData();

@JS('window.crazyGames.gameplayStart')
external void _jsGameplayStart();

@JS('window.crazyGames.gameplayStop')
external void _jsGameplayStop();

class CrazyGamesService {
  static void signalGameplayStart() {
    try {
      _jsGameplayStart();
    } catch (e) {
      print('CrazyGames: gameplayStart failed: $e');
    }
  }

  static void signalGameplayStop() {
    try {
      _jsGameplayStop();
    } catch (e) {
      print('CrazyGames: gameplayStop failed: $e');
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
      final dynamic resultObj = await _jsSaveData(encoded.toJS).toDart;
      if (resultObj is JSBoolean) {
        return resultObj.toDart;
      }
      return resultObj == true;
    } catch (e) {
      print('CrazyGamesSave: Save failed: $e');
      return false;
    }
  }

  static Future<GameState?> loadGame() async {
    try {
      final dynamic jsDataObj = await _jsLoadData().toDart;
      String? data;
      if (jsDataObj is JSString) {
        data = jsDataObj.toDart;
      } else if (jsDataObj is String) {
        data = jsDataObj;
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
        
        print('CrazyGamesSave: Game loaded successfully');
        return newState;
      }
    } catch (e) {
      print('CrazyGamesSave: Load failed: $e');
    }
    return null;
  }
}
