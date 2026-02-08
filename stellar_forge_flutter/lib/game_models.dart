import 'dart:math';

class AppConfig {
  static const String version = '2.2.0-void-edition';
  static const bool isDemo = false;
  static const String githubRepo = 'devcitystudio/stellar-forge';
  static const bool devMode = false; // TOGGLE THIS FOR DEV MODE

  // GOOGLE PLAY ACHIEVEMENT IDS
  // Replace these with the IDs from the Google Play Console (e.g. 'CgkIu-7-3...')
  static const Map<String, String> achievementIds = {
    'spark_genesis': 'CgkI6OSPk9MMEAIQAg',
    'matter_weaver': 'CgkI6OSPk9MMEAIQAw',
    'data_hoarder': 'CgkI6OSPk9MMEAIQBA',
    'dedicated_captain': 'CgkI6OSPk9MMEAIQBQ',
    'click_frenzy': 'CgkI6OSPk9MMEAIQBg',
    'void_walker': 'CgkI6OSPk9MMEAIQBw',
  };
}

enum WorldColor { blue, purple, emerald, cyan, red }

class Resource {
  final String id;
  final String name;
  final String symbol;
  double amount;
  double totalEarned;

  Resource({
    required this.id,
    required this.name,
    required this.symbol,
    this.amount = 0,
    this.totalEarned = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'symbol': symbol,
    'amount': amount,
    'totalEarned': totalEarned,
  };

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'],
      name: json['name'],
      symbol: json['symbol'],
      amount: (json['amount'] as num).toDouble(),
      totalEarned: (json['totalEarned'] as num).toDouble(),
    );
  }
}

class Upgrade {
  final String id;
  final String worldId;
  final String name;
  final String description;
  final double baseCost;
  final double costMultiplier;
  int level;
  final String type; // 'click' or 'passive'
  final String resourceType;
  final String targetResource;
  final double unlockedAt;
  final double Function(int level) effectFormula;

  Upgrade({
    required this.id,
    required this.worldId,
    required this.name,
    required this.description,
    required this.baseCost,
    required this.costMultiplier,
    this.level = 0,
    required this.type,
    required this.resourceType,
    required this.targetResource,
    required this.unlockedAt,
    required this.effectFormula,
  });

  double get effect => effectFormula(level);

  double getCost(int levelToBuy) {
    return baseCost * pow(costMultiplier, levelToBuy);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'level': level,
  };
}

class World {
  final String id;
  final String name;
  final String description;
  final WorldColor color;
  final String primaryResource;
  final List<String> visibleResources;
  final String bgGradient;
  final String unlockResource;
  final double unlockAmount;

  World({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.primaryResource,
    required this.visibleResources,
    required this.bgGradient,
    required this.unlockResource,
    required this.unlockAmount,
  });
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final bool Function(GameState state) condition;
  final String reward;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.condition,
    required this.reward,
  });
}

class GameState {
  String currentWorld;
  List<String> unlockedWorlds;
  List<String> unlockedAchievements;
  List<Map<String, dynamic>> logs;
  int clicks;
  int cometsClicked;
  int prestigeCount;
  Map<String, Resource> resources;
  List<Upgrade> upgrades;
  double playTime;

  GameState({
    required this.currentWorld,
    required this.unlockedWorlds,
    required this.unlockedAchievements,
    required this.logs,
    required this.clicks,
    required this.cometsClicked,
    required this.prestigeCount,
    required this.resources,
    required this.upgrades,
    required this.playTime,
  });
}

final List<World> worlds = [
  World(
    id: 'prime',
    name: 'Stellar Forge',
    description: 'The cradle of existence. Synthesize basic matter and energy.',
    color: WorldColor.blue,
    primaryResource: 'energy',
    visibleResources: ['energy', 'matter', 'data', 'stardust'],
    bgGradient: 'radial-gradient(circle at center, #1e3a8a 0%, #020617 80%)',
    unlockResource: 'energy',
    unlockAmount: 0,
  ),
  World(
    id: 'quantum',
    name: 'Quantum Realm',
    description: 'A sub-atomic plane where probability reigns supreme.',
    color: WorldColor.purple,
    primaryResource: 'quarks',
    visibleResources: ['quarks', 'matter'],
    bgGradient: 'radial-gradient(circle at center, #581c87 0%, #020617 80%)',
    unlockResource: 'matter',
    unlockAmount: 100000,
  ),
  World(
    id: 'chronos',
    name: 'Chronos Expanse',
    description: 'The river of time flows backward here.',
    color: WorldColor.emerald,
    primaryResource: 'chronos_dust',
    visibleResources: ['chronos_dust', 'time', 'data'],
    bgGradient: 'radial-gradient(circle at center, #064e3b 0%, #020617 80%)',
    unlockResource: 'data',
    unlockAmount: 500000,
  ),
  World(
    id: 'aether',
    name: 'Aetherial Plane',
    description: 'A spiritual dimension of pure magical potential.',
    color: WorldColor.cyan,
    primaryResource: 'mana',
    visibleResources: ['mana', 'aether', 'stardust'],
    bgGradient: 'radial-gradient(circle at center, #0891b2 0%, #020617 80%)',
    unlockResource: 'stardust',
    unlockAmount: 5000,
  ),
  World(
    id: 'void',
    name: 'The Void',
    description: 'The space between universes. Reset here to gain Cosmic Power.',
    color: WorldColor.red,
    primaryResource: 'void_shards',
    visibleResources: ['void_shards', 'entropy', 'energy'],
    bgGradient: 'radial-gradient(circle at center, #7f1d1d 0%, #000000 90%)',
    unlockResource: 'energy',
    unlockAmount: 1000000000,
  ),
  World(
    id: 'stellaris',
    name: 'Stellaris Nexus',
    description: 'The heart of a dying star, where gravity bends reality.',
    color: WorldColor.emerald,
    primaryResource: 'solar_flares',
    visibleResources: ['solar_flares', 'plasma', 'neutrons', 'photons', 'gravitons'],
    bgGradient: 'radial-gradient(circle at center, #065f46 0%, #020617 80%)',
    unlockResource: 'stardust',
    unlockAmount: 50000,
  ),
  World(
    id: 'cyberia',
    name: 'Cyberia Network',
    description: 'A digital frontier where logic is the only law.',
    color: WorldColor.cyan,
    primaryResource: 'bits',
    visibleResources: ['bits', 'nanites', 'circuits', 'algorithms', 'encryption'],
    bgGradient: 'radial-gradient(circle at center, #155e75 0%, #020617 80%)',
    unlockResource: 'data',
    unlockAmount: 10000000,
  ),
];

List<Upgrade> getInitialUpgrades() => [
  // PRIME WORLD
  Upgrade(
    id: 'click_power',
    worldId: 'prime',
    name: 'Kinetic Capacitor',
    description: 'Increases Energy gained per click.',
    baseCost: 10,
    costMultiplier: 1.5,
    type: 'click',
    resourceType: 'energy',
    targetResource: 'energy',
    unlockedAt: 0,
    effectFormula: (l) => 1.0 + l * 3.0,
  ),
  Upgrade(
    id: 'solar_panel',
    worldId: 'prime',
    name: 'Solar Array',
    description: 'Basic photovoltaic cells that generate passive Energy.',
    baseCost: 15,
    costMultiplier: 1.15,
    type: 'passive',
    resourceType: 'energy',
    targetResource: 'energy',
    unlockedAt: 0,
    effectFormula: (l) => l * 1.0,
  ),
  Upgrade(
    id: 'geothermal_vent',
    worldId: 'prime',
    name: 'Geothermal Bore',
    description: 'Deep crust mining for stable heat energy.',
    baseCost: 120,
    costMultiplier: 1.15,
    type: 'passive',
    resourceType: 'energy',
    targetResource: 'energy',
    unlockedAt: 100,
    effectFormula: (l) => l * 8.0,
  ),
  Upgrade(
    id: 'fusion_core',
    worldId: 'prime',
    name: 'Fusion Reactor',
    description: 'Plasma confinement for massive Energy output.',
    baseCost: 1500,
    costMultiplier: 1.18,
    type: 'passive',
    resourceType: 'energy',
    targetResource: 'energy',
    unlockedAt: 1000,
    effectFormula: (l) => l * 65.0,
  ),
  Upgrade(
    id: 'dyson_swarm',
    worldId: 'prime',
    name: 'Dyson Swarm',
    description: 'Orbital mirror network harvesting an entire star.',
    baseCost: 35000,
    costMultiplier: 1.25,
    type: 'passive',
    resourceType: 'energy',
    targetResource: 'energy',
    unlockedAt: 25000,
    effectFormula: (l) => l * 450.0,
  ),
  Upgrade(
    id: 'matter_synth',
    worldId: 'prime',
    name: 'Matter Synthesizer',
    description: 'Condenses raw energy into hydrogen atoms.',
    baseCost: 800,
    costMultiplier: 1.2,
    type: 'passive',
    resourceType: 'energy',
    targetResource: 'matter',
    unlockedAt: 500,
    effectFormula: (l) => l * 0.5,
  ),
  Upgrade(
    id: 'molecular_printer',
    worldId: 'prime',
    name: 'Molecular Printer',
    description: 'Rapidly prints complex structures from energy.',
    baseCost: 7500,
    costMultiplier: 1.25,
    type: 'passive',
    resourceType: 'energy',
    targetResource: 'matter',
    unlockedAt: 5000,
    effectFormula: (l) => l * 6.0,
  ),
  Upgrade(
    id: 'silicon_miner',
    worldId: 'prime',
    name: 'Silicon Neural Net',
    description: 'Basic learning algorithms running on matter.',
    baseCost: 2500,
    costMultiplier: 1.22,
    type: 'passive',
    resourceType: 'matter',
    targetResource: 'data',
    unlockedAt: 1000,
    effectFormula: (l) => l * 0.2,
  ),
  Upgrade(
    id: 'quantum_computer',
    worldId: 'prime',
    name: 'Quantum Supercomputer',
    description: 'Exploits superposition for exponential processing.',
    baseCost: 25000,
    costMultiplier: 1.28,
    type: 'passive',
    resourceType: 'matter',
    targetResource: 'data',
    unlockedAt: 10000,
    effectFormula: (l) => l * 3.5,
  ),
  Upgrade(
    id: 'matrioshka_brain',
    worldId: 'prime',
    name: 'Matrioshka Brain',
    description: 'Converts a star system into a computer.',
    baseCost: 750000,
    costMultiplier: 1.4,
    type: 'passive',
    resourceType: 'matter',
    targetResource: 'data',
    unlockedAt: 500000,
    effectFormula: (l) => l * 30.0,
  ),
  Upgrade(
    id: 'void_siphon',
    worldId: 'prime',
    name: 'Void Siphon',
    description: 'Extracts exotic particles from the vacuum.',
    baseCost: 15000,
    costMultiplier: 1.5,
    type: 'passive',
    resourceType: 'data',
    targetResource: 'stardust',
    unlockedAt: 5000,
    effectFormula: (l) => l * 0.02,
  ),
  Upgrade(
    id: 'reality_engine',
    worldId: 'prime',
    name: 'Reality Engine',
    description: 'Rewrites physical laws to manifest stardust.',
    baseCost: 250000,
    costMultiplier: 1.6,
    type: 'passive',
    resourceType: 'data',
    targetResource: 'stardust',
    unlockedAt: 100000,
    effectFormula: (l) => l * 0.15,
  ),

  // QUANTUM REALM UPGRADES
  Upgrade(
    id: 'quantum_click',
    worldId: 'quantum',
    name: 'Probability Spike',
    description: 'Forces quantum collapse for more Quarks.',
    baseCost: 100,
    costMultiplier: 1.6,
    type: 'click',
    resourceType: 'quarks',
    targetResource: 'quarks',
    unlockedAt: 0,
    effectFormula: (l) => 5.0 + l * 15.0,
  ),
  Upgrade(
    id: 'entanglement_link',
    worldId: 'quantum',
    name: 'Entanglement Link',
    description: 'Pairs particles to generate passive Quarks.',
    baseCost: 200,
    costMultiplier: 1.2,
    type: 'passive',
    resourceType: 'quarks',
    targetResource: 'quarks',
    unlockedAt: 0,
    effectFormula: (l) => l * 10.0,
  ),

  // CHRONOS EXPANSE UPGRADES
  Upgrade(
    id: 'chronos_click',
    worldId: 'chronos',
    name: 'Temporal Anchor',
    description: 'Harvest Chronos Dust from the time stream.',
    baseCost: 500,
    costMultiplier: 1.7,
    type: 'click',
    resourceType: 'chronos_dust',
    targetResource: 'chronos_dust',
    unlockedAt: 0,
    effectFormula: (l) => 20.0 + l * 50.0,
  ),
  Upgrade(
    id: 'time_loop',
    worldId: 'chronos',
    name: 'Causality Loop',
    description: 'Automates dust collection via recurring events.',
    baseCost: 1000,
    costMultiplier: 1.25,
    type: 'passive',
    resourceType: 'chronos_dust',
    targetResource: 'chronos_dust',
    unlockedAt: 0,
    effectFormula: (l) => l * 40.0,
  ),

  // AETHERIAL PLANE UPGRADES
  Upgrade(
    id: 'aether_click',
    worldId: 'aether',
    name: 'Mana Well',
    description: 'Draw Mana directly from the source.',
    baseCost: 1000,
    costMultiplier: 1.8,
    type: 'click',
    resourceType: 'mana',
    targetResource: 'mana',
    unlockedAt: 0,
    effectFormula: (l) => 50.0 + l * 100.0,
  ),
  Upgrade(
    id: 'crystal_spire',
    worldId: 'aether',
    name: 'Mana Spire',
    description: 'Passive mana condensation from the atmosphere.',
    baseCost: 2500,
    costMultiplier: 1.3,
    type: 'passive',
    resourceType: 'mana',
    targetResource: 'mana',
    unlockedAt: 0,
    effectFormula: (l) => l * 80.0,
  ),

  // THE VOID UPGRADES
  Upgrade(
    id: 'void_click',
    worldId: 'void',
    name: 'Entropy Reversal',
    description: 'Extract Void Shards from the nothingness.',
    baseCost: 10000,
    costMultiplier: 2.0,
    type: 'click',
    resourceType: 'void_shards',
    targetResource: 'void_shards',
    unlockedAt: 0,
    effectFormula: (l) => 200.0 + l * 500.0,
  ),
  Upgrade(
    id: 'black_hole_gen',
    worldId: 'void',
    name: 'Singularity Generator',
    description: 'Crushes light to produce passive Void Shards.',
    baseCost: 50000,
    costMultiplier: 1.4,
    type: 'passive',
    resourceType: 'void_shards',
    targetResource: 'void_shards',
    unlockedAt: 0,
    effectFormula: (l) => l * 300.0,
  ),

  // STELLARIS NEXUS UPGRADES
  Upgrade(
    id: 'stellaris_click',
    worldId: 'stellaris',
    name: 'Flare Catcher',
    description: 'Catch Solar Flares at the star\'s surface.',
    baseCost: 5000,
    costMultiplier: 1.75,
    type: 'click',
    resourceType: 'solar_flares',
    targetResource: 'solar_flares',
    unlockedAt: 0,
    effectFormula: (l) => 100.0 + l * 300.0,
  ),
  Upgrade(
    id: 'plasma_condenser',
    worldId: 'stellaris',
    name: 'Plasma Condenser',
    description: 'Turns solar wind into stable Plasma.',
    baseCost: 10000,
    costMultiplier: 1.35,
    type: 'passive',
    resourceType: 'solar_flares',
    targetResource: 'plasma',
    unlockedAt: 0,
    effectFormula: (l) => l * 50.0,
  ),

  // CYBERIA NETWORK UPGRADES
  Upgrade(
    id: 'cyberia_click',
    worldId: 'cyberia',
    name: 'Bit Miner',
    description: 'Manually mine Bits from the network.',
    baseCost: 20000,
    costMultiplier: 1.9,
    type: 'click',
    resourceType: 'bits',
    targetResource: 'bits',
    unlockedAt: 0,
    effectFormula: (l) => 500.0 + l * 1000.0,
  ),
  Upgrade(
    id: 'server_farm',
    worldId: 'cyberia',
    name: 'Nanite Server Farm',
    description: 'Produces passive Nanites using computed bits.',
    baseCost: 40000,
    costMultiplier: 1.45,
    type: 'passive',
    resourceType: 'bits',
    targetResource: 'nanites',
    unlockedAt: 0,
    effectFormula: (l) => l * 150.0,
  ),
];

final List<Achievement> achievements = [
  Achievement(
    id: 'spark_genesis',
    name: 'Spark of Genesis',
    description: 'Generate your first 1,000 Energy.',
    condition: (s) => (s.resources['energy']?.totalEarned ?? 0) >= 1000,
    reward: '10% Click Bonus',
  ),
  Achievement(
    id: 'matter_weaver',
    name: 'Matter Weaver',
    description: 'Synthesize 5,000 Matter.',
    condition: (s) => (s.resources['matter']?.totalEarned ?? 0) >= 5000,
    reward: 'Unlock Quantum Realm',
  ),
  Achievement(
    id: 'data_hoarder',
    name: 'Data Hoarder',
    description: 'Process 10,000 Data.',
    condition: (s) => (s.resources['data']?.totalEarned ?? 0) >= 10000,
    reward: 'Passive Boost',
  ),
  Achievement(
    id: 'dedicated_captain',
    name: 'Dedicated Captain',
    description: 'Play for 30 minutes.',
    condition: (s) => s.playTime >= 1800,
    reward: 'Visual Theme',
  ),
  Achievement(
    id: 'click_frenzy',
    name: 'Click Frenzy',
    description: 'Perform 1,000 manual clicks.',
    condition: (s) => s.clicks >= 1000,
    reward: 'Auto-Clicker Prototype',
  ),
  Achievement(
    id: 'void_walker',
    name: 'Void Walker',
    description: 'Perform your first Prestige reset.',
    condition: (s) => s.prestigeCount > 0,
    reward: 'Unlocks Void Upgrades',
  ),
];

GameState getInitialState() => GameState(
  currentWorld: 'prime',
  unlockedWorlds: ['prime'],
  unlockedAchievements: [],
  logs: [{'id': 1, 'text': "System Initialized. Awaiting Input.", 'type': 'info'}],
  clicks: 0,
  cometsClicked: 0,
  prestigeCount: 0,
  resources: {
    'energy': Resource(id: 'energy', name: 'Energy', symbol: '⚡'),
    'matter': Resource(id: 'matter', name: 'Matter', symbol: '⚛️'),
    'data': Resource(id: 'data', name: 'Data', symbol: '💾'),
    'stardust': Resource(id: 'stardust', name: 'Stardust', symbol: '✨'),
    'quarks': Resource(id: 'quarks', name: 'Quarks', symbol: '🌀'),
    'time': Resource(id: 'time', name: 'Time Shards', symbol: '⏳'),
    'aether': Resource(id: 'aether', name: 'Aether', symbol: '💠'),
    'entropy': Resource(id: 'entropy', name: 'Entropy', symbol: '🔥'),
    'plasma': Resource(id: 'plasma', name: 'Plasma', symbol: '🔥'),
    'neutrons': Resource(id: 'neutrons', name: 'Neutrons', symbol: '🔘'),
    'photons': Resource(id: 'photons', name: 'Photons', symbol: '💡'),
    'gravitons': Resource(id: 'gravitons', name: 'Gravitons', symbol: '⚓'),
    'nanites': Resource(id: 'nanites', name: 'Nanites', symbol: '🦠'),
    'circuits': Resource(id: 'circuits', name: 'Circuits', symbol: '🔌'),
    'algorithms': Resource(id: 'algorithms', name: 'Algorithms', symbol: '🧮'),
    'encryption': Resource(id: 'encryption', name: 'Encryption', symbol: '🔐'),
    'mana': Resource(id: 'mana', name: 'Mana', symbol: '🔮'),
    'void_shards': Resource(id: 'void_shards', name: 'Void Shards', symbol: '⬛'),
    'chronos_dust': Resource(id: 'chronos_dust', name: 'Chronos Dust', symbol: '⌛'),
    'solar_flares': Resource(id: 'solar_flares', name: 'Solar Flares', symbol: '☀️'),
    'bits': Resource(id: 'bits', name: 'Bits', symbol: '🔢'),
  },
  upgrades: getInitialUpgrades(),
  playTime: 0,
);
