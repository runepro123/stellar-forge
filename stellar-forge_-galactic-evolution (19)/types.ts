
export type ResourceType = 'energy' | 'matter' | 'data' | 'stardust' | 'quarks' | 'time' | 'aether' | 'entropy';

export interface Resource {
  id: ResourceType;
  name: string;
  amount: number;
  totalEarned: number;
  symbol: string;
}

export interface Upgrade {
  id: string;
  worldId: string;
  name: string;
  description: string;
  baseCost: number;
  costMultiplier: number;
  level: number;
  maxLevel?: number;
  effect: (level: number) => number;
  type: 'click' | 'passive' | 'multiplier';
  resourceType: ResourceType;
  targetResource: ResourceType;
  unlockedAt: number;
}

export interface World {
  id: string;
  name: string;
  description: string;
  color: string;
  primaryResource: ResourceType;
  visibleResources: ResourceType[];
  bgGradient: string;
  unlockReq: { resource: ResourceType; amount: number };
}

export interface GameState {
  resources: Record<ResourceType, Resource>;
  upgrades: Upgrade[];
  prestigeCount: number;
  lastSave: number;
  playTime: number;
  currentWorld: string;
  unlockedWorlds: string[];
}
