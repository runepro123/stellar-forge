import 'game_models.dart';

abstract class CrazyGamesService {
  static void signalGameplayStart() {}
  static void signalGameplayStop() {}
  static Future<bool> saveGame(GameState state) async => false;
  static Future<GameState?> loadGame() async => null;
}
