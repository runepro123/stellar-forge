import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:galactic/l10n/generated/app_localizations.dart';
import 'package:games_services/games_services.dart' as gs;
import 'game_models.dart';
import 'widgets/resource_card.dart';
import 'widgets/upgrade_card.dart';
import 'widgets/galaxy_map.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/ascension_dialog.dart';
import 'widgets/admin_panel.dart';
import 'crazy_games_service.dart';
import 'cloud_service.dart';
import 'language_provider.dart';
import 'update_service.dart';
import 'widgets/update_progress_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => UpdateService()),
      ],
      child: const GalacticApp(),
    ),
  );
}

class GalacticApp extends StatelessWidget {
  const GalacticApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return MaterialApp(
      onGenerateTitle: (context) {
        final loc = AppLocalizations.of(context);
        return loc?.appTitle ?? 'Stellar Forge';
      },
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF020617),
        fontFamily: 'Inter',
      ),
      locale: languageProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: languageProvider.supportedLocales,
      home: const GameController(),
    );
  }
}

class GameController extends StatefulWidget {
  const GameController({super.key});

  @override
  State<GameController> createState() => _GameControllerState();
}

class _GameControllerState extends State<GameController> with WidgetsBindingObserver {
  late GameState _state;
  Timer? _gameTimer;
  String _scene = 'boot';
  String _activeTab = 'upgrades';
  int _buyMode = 1;
  bool _isCloudSignedIn = false;
  bool _autoSignInTried = false;
  final List<Map<String, dynamic>> _toasts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _state = getInitialState();
    _startBootSequence();
    // Attempt to load saved progress (cloud or local) on startup
    _initializeCloudAndLoad();

    // Check for updates on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UpdateService>().checkForUpdates();
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // Auto-save when the app is backgrounded or closed
      _autoSave();
    }
    if (state == AppLifecycleState.resumed) {
      // Re-check sign-in status and auto-load if necessary
      _checkSignInAndMaybeLoad();
    }
  }

  Future<void> _initializeCloudAndLoad() async {
    try {
      if (kIsWeb) {
        // Add a timeout to prevent web builds from hanging on load
        GameState? loaded = await CrazyGamesService.loadGame().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            print('CrazyGames load timed out');
            return null;
          },
        );
        if (loaded != null) {
          setState(() => _state = loaded);
          _showToast('CRAZYGAMES LOAD', 'Progress restored automatically');
        }
        return;
      }

      bool signedIn = false;
      try {
        signedIn = await gs.GamesServices.isSignedIn;
      } catch (e) {
        signedIn = false;
      }
      if (signedIn) {
        setState(() => _isCloudSignedIn = true);
      } else {
        // Attempt an automatic sign-in once on startup.
        if (!_autoSignInTried) {
          _autoSignInTried = true;
          bool ok = await CloudSaveService.login();
          if (ok) {
            setState(() => _isCloudSignedIn = true);
          }
        }
      }

      GameState? loaded = await CloudSaveService.loadGame();
      if (loaded != null) {
        setState(() {
          _state = loaded;
          _isCloudSignedIn = true; // If we loaded from cloud, we must be signed in
        });
        _showToast('CLOUD LOAD', 'Progress restored automatically');
      }
      // Poll briefly in case silent/automatic sign-in completes shortly after start
      for (int i = 0; i < 6 && !_isCloudSignedIn; i++) {
        await Future.delayed(const Duration(seconds: 1));
        try {
          bool nowSigned = await gs.GamesServices.isSignedIn;
          if (nowSigned) {
            setState(() => _isCloudSignedIn = true);
            if (loaded == null) {
              GameState? reload = await CloudSaveService.loadGame();
              if (reload != null) {
                setState(() => _state = reload);
                _showToast('CLOUD LOAD', 'Progress synced after sign-in');
              }
            }
            break;
          }
        } catch (_) {}
      }
    } catch (e) {
      print('Init load failed: $e');
    }
  }

  Future<void> _checkSignInAndMaybeLoad() async {
    try {
      bool signedIn = false;
      try {
        signedIn = await gs.GamesServices.isSignedIn;
      } catch (e) {
        signedIn = false;
      }
      if (signedIn != _isCloudSignedIn) {
        setState(() => _isCloudSignedIn = signedIn);
      }
      // If not signed in, try automatic sign-in once more on resume
      if (!signedIn && !_autoSignInTried) {
        _autoSignInTried = true;
        bool ok = await CloudSaveService.login();
        if (ok) {
          setState(() => _isCloudSignedIn = true);
          GameState? loaded = await CloudSaveService.loadGame();
          if (loaded != null) {
            setState(() => _state = loaded);
            _showToast('CLOUD LOAD', 'Progress restored after sign-in');
          }
        }
      }
      if (signedIn) {
        GameState? loaded = await CloudSaveService.loadGame();
        if (loaded != null) {
          setState(() => _state = loaded);
          _showToast('CLOUD LOAD', 'Progress restored after resume');
        }
      }
    } catch (e) {
      print('Sign-in check failed: $e');
    }
  }

  Future<void> _autoSave() async {
    try {
      bool ok;
      if (kIsWeb) {
        ok = await CrazyGamesService.saveGame(_state);
      } else {
        ok = await CloudSaveService.saveGame(_state);
      }

      if (ok) {
        _addLog('AUTO-SAVE: progress saved', 'info');
      } else {
        _addLog('AUTO-SAVE: failed to save', 'warning');
      }
    } catch (e) {
      print('Auto-save exception: $e');
    }
  }

  void _startBootSequence() {
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _scene = 'title';
        });
      }
    });
  }

  void _startGameLoop() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _tick();
    });
    // Check sign-in status periodically when game is running
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_scene.contains('game')) {
        timer.cancel();
        return;
      }
      if (!_isCloudSignedIn) {
        try {
          bool signedIn = await gs.GamesServices.isSignedIn;
          if (signedIn) {
            setState(() => _isCloudSignedIn = true);
            _loadFromCloud(); // Auto-load if we just discovered we are signed in
          }
        } catch (_) {}
      }
    });
  }

  void _tick() {
    setState(() {
      const double delta = 0.1;
      _state.playTime += delta;

      double prestigeMultiplier = 1.0 + (_state.prestigeCount * 0.1);

      for (var u in _state.upgrades) {
        if (u.type == 'passive') {
          double prod = u.effectFormula(u.level) * delta * prestigeMultiplier;
          if (prod > 0) {
            var res = _state.resources[u.targetResource];
            if (res != null) {
              res.amount += prod;
              res.totalEarned += prod;
            }
          }
        }
      }

      for (var ach in achievements) {
        if (!_state.unlockedAchievements.contains(ach.id) && ach.condition(_state)) {
          _unlockAchievement(ach);
        }
      }
    });
  }

  void _unlockAchievement(Achievement ach) {
    _state.unlockedAchievements.add(ach.id);
    _showToast('Achievement Unlocked!', ach.name);
    _addLog('ACHIEVEMENT: ${ach.name} - ${ach.description}', 'success');
    if (!kIsWeb) {
      CloudSaveService.unlockAchievement(ach.id);
    }
  }

  void _showToast(String title, String message) {
    var id = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _toasts.add({'id': id, 'title': title, 'message': message});
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _toasts.removeWhere((t) => t['id'] == id);
        });
      }
    });
  }

  void _addLog(String text, String type) {
    _state.logs.add({'id': DateTime.now().millisecondsSinceEpoch, 'text': text, 'type': type});
    if (_state.logs.length > 50) {
      _state.logs.removeAt(0);
    }
  }

  void _handleForgeClick() {
    setState(() {
      _state.clicks++;
      var currentWorldDef = worlds.firstWhere((w) => w.id == _state.currentWorld);
      var clickUpgrade = _state.upgrades.firstWhere(
        (u) => u.type == 'click' && u.worldId == _state.currentWorld,
        orElse: () => _state.upgrades.first,
      );
      double prestigeMultiplier = 1.0 + (_state.prestigeCount * 0.1);
      double clickPower = clickUpgrade.effectFormula(clickUpgrade.level) * prestigeMultiplier;

      var res = _state.resources[currentWorldDef.primaryResource];
      if (res != null) {
        res.amount += clickPower;
        res.totalEarned += clickPower;
      }
    });
  }

  void _buyUpgrade(Upgrade u) {
    var res = _state.resources[u.resourceType];
    if (res == null) return;

    int countToBuy = _buyMode == -1 ? _calculateMaxBuy(u, res.amount) : _buyMode;

    if (countToBuy > 0) {
      double totalCost = 0;
      for (int i = 0; i < countToBuy; i++) {
        totalCost += u.getCost(u.level + i);
      }

      if (res.amount >= totalCost) {
        setState(() {
          res.amount -= totalCost;
          u.level += countToBuy;
        });
        _addLog('TECH UPGRADED: ${u.name} (LV.${u.level})', 'info');
      }
    }
  }

  int _calculateMaxBuy(Upgrade u, double available) {
    int count = 0;
    double cost = 0;
    while (true) {
      double nextCost = u.getCost(u.level + count);
      if (cost + nextCost <= available) {
        cost += nextCost;
        count++;
      } else {
        break;
      }
      if (count >= 1000) break;
    }
    return count;
  }

  void _switchWorld(String worldId) {
    setState(() {
      _state.currentWorld = worldId;
      if (!_state.unlockedWorlds.contains(worldId)) {
        final world = worlds.firstWhere((w) => w.id == worldId);
        final res = _state.resources[world.unlockResource]!;
        res.amount -= world.unlockAmount;
        _state.unlockedWorlds.add(worldId);
        _addLog('REALM DISCOVERED: ${world.name}', 'success');
      } else {
        _addLog('WARP DRIVE ACTIVE: Destination $worldId', 'info');
      }
    });
    Navigator.pop(context);
  }

  void _performPrestige() {
    int potential = _calculatePrestigePotential();
    if (potential <= 0) return;

    setState(() {
      _state.prestigeCount += potential;
      _state.currentWorld = 'prime';
      _state.unlockedWorlds = ['prime'];
      _state.clicks = 0;
      _state.playTime = 0;
      
      for (var res in _state.resources.values) {
        res.amount = 0;
        res.totalEarned = 0;
      }
      
      for (var u in _state.upgrades) {
        u.level = 0;
      }
      
      _addLog('UNIVERSE REBORN: Prestige Level ${_state.prestigeCount}', 'warning');
    });
    Navigator.pop(context);
    _showToast('UNIVERSE REBORN', 'Ascended to Level ${_state.prestigeCount}');
  }

  int _calculatePrestigePotential() {
    double totalLifetime = _state.resources.values.fold(0.0, (sum, r) => sum + r.totalEarned);
    if (totalLifetime < 1000000) return 0;
    int potential = (sqrt(totalLifetime / 1000000)).floor();
    return max(0, potential - _state.prestigeCount);
  }

  void _wipeSave() {
    setState(() {
      _state = getInitialState();
      _scene = 'boot';
      _gameTimer?.cancel();
      _startBootSequence();
    });
  }

  Future<void> _connectCloud() async {
    _showToast('CLOUD SYNC', 'Connecting to Google Play Games...');
    bool success = await CloudSaveService.login();
    if (mounted) {
      if (success) {
        setState(() => _isCloudSignedIn = true);
        _showToast('CLOUD SYNC', 'Connected to Google Play Games');
        _addLog('CLOUD: Successfully connected to Play Games', 'success');
      } else {
        setState(() => _isCloudSignedIn = false);
        _showToast('CLOUD SYNC', 'Sign-in failed or cancelled');
        _addLog('CLOUD: Sign-in failed - check Play Games app installed', 'warning');
        // Offer retry and setup instructions
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Cloud Sign-In Failed'),
            content: const Text('Sign-in failed or was cancelled. You can retry or view setup instructions for Google Play Games.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _connectCloud();
                },
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showPlaySetupInstructions();
                },
                child: const Text('Show Setup'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showPlaySetupInstructions() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Play Console Setup'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('To enable Google Play Games for this app, do the following:'),
              const SizedBox(height: 8),
              const Text('- Open Google Play Console and select your app.'),
              const SizedBox(height: 6),
              const Text('- Create an OAuth 2.0 client for Android using the package name and SHA1 fingerprint.'),
              const SizedBox(height: 12),
              const Text('Package name:'),
              const SizedBox(height: 4),
              const SelectableText('com.stellarforge.galactic', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Get your debug SHA1 (Windows):'),
              const SizedBox(height: 4),
              const SelectableText('keytool -list -v -keystore %USERPROFILE%\\.android\\debug.keystore -alias androiddebugkey -storepass android -keypass android'),
              const SizedBox(height: 12),
              const Text('After configuring, publish an internal test or install an APK signed with the configured key to test sign-in.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: 'Package: com.stellarforge.galactic\nkeytool -list -v -keystore %USERPROFILE%\\.android\\debug.keystore -alias androiddebugkey -storepass android -keypass android'));
              Navigator.pop(context);
            },
            child: const Text('COPY INFO'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
        ],
      ),
    );
  }

  Future<void> _saveToCloud() async {
    bool success;
    if (kIsWeb) {
      success = await CrazyGamesService.saveGame(_state);
    } else {
      success = await CloudSaveService.saveGame(_state);
    }

    if (success) {
      _showToast('SAVE', 'Progress saved successfully');
    } else {
      _showToast('SAVE', 'Failed to save progress');
    }
  }

  Future<void> _loadFromCloud() async {
    GameState? loadedState;
    if (kIsWeb) {
      loadedState = await CrazyGamesService.loadGame();
    } else {
      loadedState = await CloudSaveService.loadGame();
    }

    if (loadedState != null) {
      setState(() => _state = loadedState!);
      _showToast('LOAD', 'Progress restored successfully');
    } else {
      _showToast('LOAD', 'No save found or load failed');
    }
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (_) => CloudSettingsDialog(
        isCloudSignedIn: _isCloudSignedIn,
        onConnect: _connectCloud,
        onSave: _saveToCloud,
        onLoad: _loadFromCloud,
        onWipe: _wipeSave,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_scene == 'boot') {
      content = _buildBootScreen();
    } else if (_scene == 'title') {
      content = _buildTitleScreen();
    } else if (_scene == 'menu') {
      content = _buildMenuScreen();
    } else {
      content = _buildGameScreen();
    }

    return Scaffold(
      body: Column(
        children: [
          const UpdateProgressBar(),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildBootScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_city, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            const Text('DEV CITY', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4)),
            Text('STUDIO', style: TextStyle(fontSize: 18, color: Colors.blue.shade300, letterSpacing: 8)),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleScreen() {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          setState(() {
            _scene = 'menu';
          });
        },
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF020617)],
              radius: 0.8,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('STELLAR',
                  style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2)),
              const Text('FORGE',
                  style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.blue)),
              const SizedBox(height: 60),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(l10n.tapToInitialize,
                    style: const TextStyle(color: Colors.blue, letterSpacing: 2)),
              ),
              const SizedBox(height: 100),
              Text('Build v${AppConfig.version}',
                  style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuScreen() {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: min(400, 800) == 400 ? MainAxisSize.min : MainAxisSize.max, // dummy to avoid unused import error
            children: [
              Text(l10n.commandDeck,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(width: 40, height: 4, color: Colors.blue),
              const SizedBox(height: 40),
              _menuButton('SHOW GOOGLE PLAY AWARDS', Icons.emoji_events, () {
                CloudSaveService.showAchievements();
              }),
              _menuButton(l10n.backToGame, Icons.play_arrow, () async {
                // Auto-load on resume
                if (kIsWeb) {
                  GameState? loaded = await CrazyGamesService.loadGame();
                  if (loaded != null) {
                    setState(() => _state = loaded);
                  }
                } else {
                  GameState? loaded = await CloudSaveService.loadGame();
                  if (loaded != null) {
                    setState(() {
                      _state = loaded;
                      _isCloudSignedIn = true;
                    });
                  }
                }

                setState(() {
                  _scene = 'game';
                  _startGameLoop();
                });
                CrazyGamesService.signalGameplayStart();
              }),
              _menuButton('System Params', Icons.settings, _openSettings),
              _menuButton('Wipe Memory', Icons.warning, _wipeSave),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuButton(String label, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.withOpacity(0.1),
          side: const BorderSide(color: Colors.blue),
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    var currentWorldDef = worlds.firstWhere((w) => w.id == _state.currentWorld);

    return Scaffold(
      drawer: AppConfig.devMode
          ? AdminPanel(
              state: _state,
              onStateChanged: () => setState(() {}),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 800;

          return Stack(
            children: [
              Column(
                children: [
                  _buildHeader(currentWorldDef),
                  Expanded(
                    child: isMobile
                        ? Column(
                            children: [
                              Expanded(flex: 2, child: _buildForgeArea(currentWorldDef)),
                              Expanded(flex: 3, child: _buildSidebar(isMobile: true)),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: _buildForgeArea(currentWorldDef)),
                              _buildSidebar(isMobile: false),
                            ],
                          ),
                  ),
                ],
              ),
              _buildToasts(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(World world) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.8),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: world.visibleResources.length,
        itemBuilder: (context, index) {
          final resId = world.visibleResources[index];
          final res = _state.resources[resId]!;
          double rate = _state.upgrades
              .where((u) => u.targetResource == resId && u.type == 'passive')
              .fold(0.0, (sum, u) => sum + u.effectFormula(u.level));
          rate *= (1.0 + (_state.prestigeCount * 0.1));

          return ResourceCard(
            resource: res,
            rate: rate,
            formattedAmount: _formatNumber(res.amount),
            formattedRate: _formatNumber(rate),
          );
        },
      ),
    );
  }

  Widget _buildForgeArea(World world) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [Colors.blue.withOpacity(0.2), const Color(0xFF020617)],
          radius: 1.0,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(world.name.toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(world.description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: _handleForgeClick,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade900],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 40, spreadRadius: 10),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.auto_awesome, size: 50, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Column(
              children: [
                if (AppConfig.devMode) ...[
                  Builder(builder: (context) {
                    return _circularIconButton(
                        Icons.admin_panel_settings, Colors.redAccent, () {
                      Scaffold.of(context).openDrawer();
                    });
                  }),
                  const SizedBox(height: 12),
                ],
                _circularIconButton(Icons.public, Colors.blue, () {
                  showDialog(
                      context: context,
                      builder: (_) => GalaxyMapDialog(state: _state, onWorldSelected: _switchWorld, formatNumber: _formatNumber));
                }),
                const SizedBox(height: 12),
                _circularIconButton(Icons.bolt, Colors.purple, () {
                  showDialog(
                      context: context,
                      builder: (_) => AscensionDialog(
                          prestigeCount: _state.prestigeCount,
                          potentialGain: _calculatePrestigePotential(),
                          onAscend: _performPrestige,
                          formatNumber: _formatNumber));
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circularIconButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          border: Border.all(color: color.withOpacity(0.5)),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildSidebar({required bool isMobile}) {
    return Container(
      width: isMobile ? double.infinity : 380,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.9),
        border: Border(
          left: isMobile ? BorderSide.none : const BorderSide(color: Colors.white10),
          top: isMobile ? const BorderSide(color: Colors.white10) : BorderSide.none,
        ),
      ),
      child: Column(
        children: [
          _buildTabs(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        _tabButton('upgrades', Icons.trending_up, l10n.energy.toUpperCase()),
        _tabButton('stats', Icons.analytics, l10n.data.toUpperCase()),
        _tabButton('achievements', Icons.emoji_events, l10n.reward.toUpperCase()),
        _tabButton('nexus', Icons.settings, l10n.settings.toUpperCase()),
      ],
    );
  }

  Widget _tabButton(String id, IconData icon, String label) {
    bool active = _activeTab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: active ? Colors.blue.withOpacity(0.05) : Colors.transparent,
            border: Border(bottom: BorderSide(color: active ? Colors.blue : Colors.transparent, width: 2)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: active ? Colors.blue : Colors.grey),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: active ? Colors.blue : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    final l10n = AppLocalizations.of(context)!;
    if (_activeTab == 'upgrades') return _buildUpgradesTab();
    if (_activeTab == 'achievements') return _buildAchievementsTab();
    if (_activeTab == 'stats') return _buildStatsTab();
    if (_activeTab == 'nexus') {
      return Center(
          child: _menuButton(l10n.settings, Icons.settings, _openSettings));
    }
    return const Center(child: Text('SYSTEMS ONLINE'));
  }

  Widget _buildUpgradesTab() {
    final l10n = AppLocalizations.of(context)!;
    var availableUpgrades =
        _state.upgrades.where((u) => u.worldId == _state.currentWorld).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.upgradeQueue,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              Row(
                children: [1, 10, -1].map((mode) {
                  bool active = _buyMode == mode;
                  return GestureDetector(
                    onTap: () => setState(() => _buyMode = mode),
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: active ? Colors.blue : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(mode == -1 ? 'MAX' : '${mode}X', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: availableUpgrades.length,
            itemBuilder: (context, index) {
              var u = availableUpgrades[index];
              var res = _state.resources[u.resourceType]!;
              bool unlocked = res.totalEarned >= u.unlockedAt;
              int countToBuy = _buyMode == -1 ? _calculateMaxBuy(u, res.amount) : _buyMode;
              double totalCost = 0;
              for (int i = 0; i < countToBuy; i++) {
                totalCost += u.getCost(u.level + i);
              }
              bool canBuy = countToBuy > 0 && res.amount >= totalCost;

              return UpgradeCard(
                upgrade: u,
                resource: res,
                unlocked: unlocked,
                canBuy: canBuy,
                countToBuy: countToBuy,
                totalCost: totalCost,
                outputGain: u.effectFormula(u.level + countToBuy) - u.effectFormula(u.level),
                onTap: () => _buyUpgrade(u),
                formatNumber: _formatNumber,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        var ach = achievements[index];
        bool unlocked = _state.unlockedAchievements.contains(ach.id);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: unlocked ? Colors.green.withOpacity(0.05) : Colors.black.withOpacity(0.2),
            border: Border.all(color: unlocked ? Colors.green.withOpacity(0.3) : Colors.white10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(ach.name, style: TextStyle(fontWeight: FontWeight.bold, color: unlocked ? Colors.white : Colors.grey)),
                  if (unlocked) const Icon(Icons.check_circle, size: 16, color: Colors.green),
                ],
              ),
              const SizedBox(height: 4),
              Text(ach.description, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
                child: Text('REWARD: ${ach.reward}', style: const TextStyle(fontSize: 9, color: Colors.amber)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsTab() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10)),
            child: ListView.builder(
              itemCount: _state.logs.length,
              itemBuilder: (context, index) {
                var log = _state.logs[index];
                Color color = log['type'] == 'success'
                    ? Colors.greenAccent
                    : log['type'] == 'warning'
                        ? Colors.amberAccent
                        : Colors.blueAccent;
                return Text('> ${log['text']}',
                    style: TextStyle(
                        fontSize: 10, color: color, fontFamily: 'monospace'));
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.universeMetrics,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue)),
          const Divider(color: Colors.white10),
          _statRow('Simulation Age', '${_state.playTime.toInt()}s'),
          _statRow('Manual Clicks', _formatNumber(_state.clicks.toDouble())),
          _statRow('Prestige Level', '${_state.prestigeCount}'),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildToasts() {
    return Positioned(
      top: 100,
      right: 20,
      child: Column(
        children: _toasts.map((t) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              border: Border.all(color: Colors.blue.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(t['message'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatNumber(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }
}
