import React, { useState, useEffect, useRef, useMemo } from 'react';
import { 
  Zap, Atom, Database, Sparkles, TrendingUp, Cpu, Settings, 
  Info, Lock, Orbit, AlertTriangle, Award, ChevronRight, RefreshCw,
  Play, RotateCcw, Monitor, Globe, Shield, X, CheckCircle,
  Save, Download, Upload, Cloud, Smartphone, Star
} from 'lucide-react';
import { INITIAL_STATE, WORLDS, APP_CONFIG } from './constants.ts';
import { formatNumber, calculateMaxBuy } from './utils.ts';
import { GameState, ResourceType, Upgrade, Resource } from './types.ts';
// @ts-ignore
import { CloudService } from './cloudService.js';
// @ts-ignore
import { ModIOService } from './modioService.js';

// --- LOGO COMPONENT ---
const DevCityLogo: React.FC<{className?: string}> = ({ className }) => (
  <svg viewBox="0 0 200 200" className={className} xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="cityGradient" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor="#3b82f6" />
        <stop offset="100%" stopColor="#1e3a8a" />
      </linearGradient>
    </defs>
    <g className="construct-anim">
      <path d="M40 140 L100 170 L160 140 L160 120 L100 150 L40 120 Z" fill="#0f172a" stroke="#3b82f6" strokeWidth="2" />
      <rect x="65" y="80" width="20" height="60" fill="url(#cityGradient)" stroke="#60a5fa" strokeWidth="1" />
      <rect x="90" y="50" width="25" height="90" fill="url(#cityGradient)" stroke="#60a5fa" strokeWidth="1" />
      <rect x="120" y="70" width="20" height="70" fill="url(#cityGradient)" stroke="#60a5fa" strokeWidth="1" />
      <circle cx="100" cy="150" r="3" fill="#3b82f6" />
    </g>
  </svg>
);

const App: React.FC = () => {
  // Navigation & Scene State
  const [scene, setScene] = useState<'boot' | 'title' | 'menu' | 'game'>('boot');
  const [activeModal, setActiveModal] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'upgrades' | 'stats' | 'nexus'>('upgrades');
  const [buyMode, setBuyMode] = useState<1 | 10 | 'MAX'>(1);
  
  // Cloud & Mods State
  const [isCloudSignedIn, setIsCloudSignedIn] = useState(false);
  const [cloudStatus, setCloudStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');
  const [availableMods, setAvailableMods] = useState<any[]>([]);
  const [isModBrowserLoading, setIsModBrowserLoading] = useState(false);

  // Game Data State
  const [gameState, setGameState] = useState<GameState>(() => {
    const saved = localStorage.getItem('stellar_forge_v4');
    if (saved) {
      try {
        const parsed = JSON.parse(saved);
        // Hydrate upgrades with logic
        const hydratedUpgrades = INITIAL_STATE.upgrades.map(baseU => {
          const savedU = (parsed.upgrades || []).find((u: any) => u.id === baseU.id);
          return { ...baseU, level: savedU ? savedU.level : 0 };
        });
        return { 
          ...INITIAL_STATE, 
          ...parsed, 
          upgrades: hydratedUpgrades,
          resources: { ...INITIAL_STATE.resources, ...parsed.resources }
        };
      } catch (e) {
        console.error("Failed to load save", e);
      }
    }
    return INITIAL_STATE;
  });

  const [clickAnims, setClickAnims] = useState<{ id: number, x: number, y: number, val: string }[]>([]);
  
  const stateRef = useRef(gameState);
  stateRef.current = gameState;
  const lastTickRef = useRef(Date.now());

  // Current World Definition
  const currentWorldDef = useMemo(() => {
    return WORLDS.find(w => w.id === gameState.currentWorld) || WORLDS[0];
  }, [gameState.currentWorld]);

  // Boot Sequence
  useEffect(() => {
    if (scene === 'boot') {
      const timer = setTimeout(() => setScene('title'), 3000);
      checkCloudAuth();
      return () => clearTimeout(timer);
    }
  }, [scene]);

  // Cloud Logic
  const checkCloudAuth = async () => {
    if (CloudService.isAvailable) {
      const isAuth = await CloudService.isAuthenticated();
      setIsCloudSignedIn(isAuth);
    }
  };

  const handleCloudConnect = async () => {
    setCloudStatus('loading');
    try {
      await CloudService.login();
      setIsCloudSignedIn(true);
      setCloudStatus('success');
    } catch (e) {
      setCloudStatus('error');
    }
    setTimeout(() => setCloudStatus('idle'), 2000);
  };

  const handleCloudSave = async () => {
    setCloudStatus('loading');
    try {
      const serializable = {
        ...gameState,
        upgrades: gameState.upgrades.map(({ effect, ...rest }) => rest),
        lastSave: Date.now()
      };
      await CloudService.saveGame(serializable);
      setCloudStatus('success');
    } catch (e) {
      setCloudStatus('error');
    }
    setTimeout(() => setCloudStatus('idle'), 2000);
  };

  const fetchMods = async () => {
    setIsModBrowserLoading(true);
    const result = await ModIOService.getMods();
    setAvailableMods(result.data || []);
    setIsModBrowserLoading(false);
  };

  // Save Loop
  useEffect(() => {
    const saver = setInterval(() => {
      const serializable = {
        ...stateRef.current,
        upgrades: stateRef.current.upgrades.map(({ effect, ...rest }) => rest)
      };
      localStorage.setItem('stellar_forge_v4', JSON.stringify(serializable));
    }, 5000);
    return () => clearInterval(saver);
  }, []);

  // Main Game Loop
  useEffect(() => {
    if (scene !== 'game') {
      lastTickRef.current = Date.now();
      return;
    }
    const loop = setInterval(() => {
      const now = Date.now();
      const delta = (now - lastTickRef.current) / 1000;
      lastTickRef.current = now;

      setGameState(prev => {
        const nextResources = { ...prev.resources };
        const prestigeBonus = 1 + (prev.prestigeCount * 0.1);
        
        prev.upgrades.forEach(u => {
          if (u.type === 'passive') {
            const prod = u.effect(u.level) * delta * prestigeBonus;
            if (prod > 0 && nextResources[u.targetResource]) {
              nextResources[u.targetResource] = {
                ...nextResources[u.targetResource],
                amount: nextResources[u.targetResource].amount + prod,
                totalEarned: nextResources[u.targetResource].totalEarned + prod
              };
            }
          }
        });

        return {
          ...prev,
          resources: nextResources,
          playTime: prev.playTime + delta
        };
      });
    }, 100);
    return () => clearInterval(loop);
  }, [scene]);

  // --- Handlers ---
  const handleForgeClick = (e: React.MouseEvent | React.TouchEvent) => {
    const clientX = 'clientX' in e ? (e as React.MouseEvent).clientX : (e as React.TouchEvent).touches[0].clientX;
    const clientY = 'clientY' in e ? (e as React.MouseEvent).clientY : (e as React.TouchEvent).touches[0].clientY;
    
    // Find relevant click upgrade for current world
    const clickUpgrade = gameState.upgrades.find(u => u.type === 'click' && u.worldId === gameState.currentWorld);
    const clickPower = (clickUpgrade ? clickUpgrade.effect(clickUpgrade.level) : 1) * (1 + gameState.prestigeCount * 0.1);
    const targetResId = currentWorldDef.primaryResource;

    setGameState(prev => {
      const res = prev.resources[targetResId];
      return {
        ...prev,
        resources: {
          ...prev.resources,
          [targetResId]: {
            ...res,
            amount: res.amount + clickPower,
            totalEarned: res.totalEarned + clickPower
          }
        }
      };
    });

    const id = Date.now() + Math.random();
    setClickAnims(prev => [...prev, { id, x: clientX, y: clientY, val: `+${formatNumber(clickPower)}` }]);
    setTimeout(() => setClickAnims(prev => prev.filter(a => a.id !== id)), 800);
  };

  const buyUpgrade = (upgradeId: string) => {
    setGameState(prev => {
      const u = prev.upgrades.find(up => up.id === upgradeId);
      if (!u) return prev;
      
      const res = prev.resources[u.resourceType];
      const purchase = calculateMaxBuy(u.baseCost, u.costMultiplier, u.level, res.amount, buyMode === 'MAX' ? 1000 : buyMode);
      
      if (purchase.count > 0 && res.amount >= purchase.cost) {
        return {
          ...prev,
          resources: {
            ...prev.resources,
            [u.resourceType]: { ...res, amount: res.amount - purchase.cost }
          },
          upgrades: prev.upgrades.map(up => up.id === upgradeId ? { ...up, level: up.level + purchase.count } : up)
        };
      }
      return prev;
    });
  };

  const switchWorld = (worldId: string) => {
    setGameState(prev => ({ ...prev, currentWorld: worldId }));
    setActiveModal(null);
  };

  const requestWipe = () => setActiveModal('wipe_confirm');
  
  const confirmWipe = () => {
    localStorage.removeItem('stellar_forge_v4');
    setGameState(INITIAL_STATE);
    setActiveModal(null);
    setScene('boot');
  };

  const getPassiveRate = (resId: ResourceType) => {
    const prestigeBonus = 1 + (gameState.prestigeCount * 0.1);
    return gameState.upgrades
      .filter(u => u.targetResource === resId && u.type === 'passive')
      .reduce((sum, u) => sum + u.effect(u.level), 0) * prestigeBonus;
  };

  // --- Render Helpers ---
  if (scene === 'boot') {
    return (
      <div className="h-screen w-screen flex flex-col items-center justify-center bg-slate-950 overflow-hidden">
        <DevCityLogo className="w-32 h-32 md:w-48 md:h-48 mb-6" />
        <div className="flex flex-col items-center animate-fade-in" style={{ animationDelay: '1s' }}>
          <h1 className="text-2xl font-black tracking-widest text-white uppercase">Dev City</h1>
          <h2 className="text-lg font-light tracking-[0.5em] text-blue-500 uppercase font-mono">Studio</h2>
        </div>
      </div>
    );
  }

  if (scene === 'title') {
    return (
      <div 
        className="h-screen w-screen flex flex-col items-center justify-center bg-slate-950 relative overflow-hidden cursor-pointer"
        onClick={() => setScene('menu')}
      >
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,_#1e3a8a_0%,_#020617_80%)] opacity-40"></div>
        <div className="z-10 text-center animate-fade-in px-6">
          <h1 className="text-6xl md:text-9xl font-black text-transparent bg-clip-text bg-gradient-to-b from-blue-100 to-blue-600 uppercase tracking-tighter mb-2">STELLAR</h1>
          <h1 className="text-5xl md:text-8xl font-black text-transparent bg-clip-text bg-gradient-to-b from-blue-400 to-indigo-900 uppercase tracking-tighter mb-12">FORGE</h1>
          <p className="text-blue-400 font-mono tracking-[0.5em] animate-pulse text-sm">TAP TO INITIALIZE</p>
        </div>
        <div className="absolute bottom-10 text-slate-600 text-[10px] font-mono tracking-widest uppercase">
          Autonomous Systems V{APP_CONFIG.VERSION}
        </div>
      </div>
    );
  }

  if (scene === 'menu') {
    return (
      <div className="h-screen w-screen flex items-center justify-center bg-slate-950 relative overflow-hidden p-6">
        <div className="absolute inset-0 z-0">
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-blue-900/10 rounded-full blur-3xl animate-pulse"></div>
        </div>
        
        <div className="z-10 w-full max-w-sm glass-panel rounded-3xl p-8 animate-slide-up flex flex-col gap-4 shadow-2xl relative">
          
          {/* Settings Modal (Cloud) */}
          {activeModal === 'settings' && (
            <div className="absolute inset-0 z-20 bg-slate-900/95 backdrop-blur-xl rounded-2xl p-6 flex flex-col animate-fade-in">
              <div className="flex justify-between items-center mb-6 border-b border-slate-800 pb-2">
                <h3 className="text-white font-bold uppercase tracking-widest flex items-center gap-2">
                  <Settings className="w-4 h-4 text-blue-400" /> Settings
                </h3>
                <button onClick={() => setActiveModal(null)}><X className="w-5 h-5 text-slate-400" /></button>
              </div>
              <div className="space-y-4">
                <div className="p-4 bg-slate-800/50 rounded-lg border border-slate-700">
                   <h4 className="text-xs font-bold text-green-400 uppercase tracking-wider mb-2 flex items-center gap-2">
                     <Cloud className="w-3 h-3" /> Cloud Sync
                   </h4>
                   {CloudService.isAvailable ? (
                     isCloudSignedIn ? (
                       <div className="flex flex-col gap-2">
                         <span className="text-[10px] text-green-300 font-mono">CONNECTED</span>
                         <button onClick={handleCloudSave} disabled={cloudStatus === 'loading'} className="py-2 bg-slate-700 hover:bg-slate-600 rounded text-[10px] font-bold uppercase transition-colors">
                            {cloudStatus === 'loading' ? 'Syncing...' : 'Save to Cloud'}
                         </button>
                       </div>
                     ) : (
                       <button onClick={handleCloudConnect} className="w-full py-2 bg-green-600 hover:bg-green-500 rounded text-xs font-bold uppercase">
                         Connect Google Play
                       </button>
                     )
                   ) : (
                     <p className="text-[10px] text-slate-500 italic">Cloud features require Android</p>
                   )}
                </div>
              </div>
            </div>
          )}

          <div className="text-center mb-4">
            <h2 className="text-xl font-bold text-white uppercase tracking-widest mb-1">COMMAND DECK</h2>
            <div className="h-1 w-12 bg-blue-500 mx-auto rounded-full"></div>
          </div>

          <button 
            onClick={() => setScene('game')}
            className="w-full p-4 rounded-2xl flex items-center justify-between bg-blue-600/20 border border-blue-500/50 hover:bg-blue-600/40 hover:border-blue-400 transition-all active:scale-95 group"
          >
            <div className="flex items-center gap-4">
              <Play className="w-6 h-6 text-blue-400" />
              <div className="text-left">
                <div className="text-xs font-bold text-white uppercase">Resume Simulation</div>
                <div className="text-[10px] text-slate-400 font-mono">Cycle: {Math.floor(gameState.playTime)}s</div>
              </div>
            </div>
            <ChevronRight className="w-5 h-5 text-blue-400 group-hover:translate-x-1 transition-transform" />
          </button>

          <button 
            onClick={() => setActiveModal('settings')}
            className="w-full p-4 rounded-2xl flex items-center gap-4 bg-slate-900/40 border border-slate-800 hover:border-slate-600 transition-all"
          >
            <Settings className="w-6 h-6 text-slate-400" />
            <span className="text-xs font-bold text-slate-200 uppercase tracking-widest">System Params</span>
          </button>

          <button 
            onClick={requestWipe}
            className="w-full p-4 rounded-2xl flex items-center gap-4 bg-slate-900/40 border border-slate-800 hover:border-red-600/40 transition-all group"
          >
            <AlertTriangle className="w-6 h-6 text-slate-500 group-hover:text-red-500 transition-colors" />
            <span className="text-xs font-bold text-slate-400 group-hover:text-red-400 uppercase tracking-widest">Wipe Memory</span>
          </button>

          <div className="mt-4 pt-4 border-t border-slate-800 flex justify-center items-center gap-3 opacity-50">
            <DevCityLogo className="w-6 h-6" />
            <span className="text-[10px] uppercase tracking-[0.3em] font-light">Dev City Studio</span>
          </div>
        </div>

        {/* Wipe Confirmation Modal */}
        {activeModal === 'wipe_confirm' && (
          <div className="absolute inset-0 z-50 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-6">
            <div className="w-full max-w-xs glass-panel rounded-3xl p-8 text-center animate-fade-in shadow-3xl border-red-500/20">
              <AlertTriangle className="w-16 h-16 text-red-500 mx-auto mb-6 animate-pulse" />
              <h3 className="text-xl font-bold text-white uppercase mb-2">CRITICAL ACTION</h3>
              <p className="text-sm text-slate-400 mb-8 leading-relaxed">System purge will erase all progress. Are you sure you wish to initialize factory reset?</p>
              <div className="flex flex-col gap-3">
                <button onClick={confirmWipe} className="w-full py-3 rounded-xl bg-red-600 hover:bg-red-500 text-white font-bold uppercase text-xs transition-colors">Confirm Purge</button>
                <button onClick={() => setActiveModal(null)} className="w-full py-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 font-bold uppercase text-xs transition-colors">Abort Mission</button>
              </div>
            </div>
          </div>
        )}
      </div>
    );
  }

  return (
    <div className="flex flex-col h-screen bg-slate-950 text-slate-100 overflow-hidden select-none font-sans animate-fade-in">
      {/* Top Header: Resources */}
      <header className="shrink-0 flex gap-2 p-2 bg-slate-900/80 border-b border-slate-800 backdrop-blur-xl z-40 overflow-x-auto custom-scrollbar no-scrollbar">
        {currentWorldDef.visibleResources.map(resId => {
          const res = gameState.resources[resId];
          const rate = getPassiveRate(resId);
          return (
            <div key={resId} className="flex flex-col px-4 py-2 rounded-xl bg-slate-950/50 border border-slate-800/50 min-w-[120px]">
              <div className="flex items-center gap-2 text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-1">
                <span className="text-sm">{res.symbol}</span>
                <span>{res.name}</span>
              </div>
              <div className="flex flex-col">
                <span className="text-base font-mono font-bold text-white">{formatNumber(res.amount)}</span>
                <span className={`text-[10px] font-mono ${rate > 0 ? 'text-green-500' : 'text-slate-600'}`}>
                  {rate > 0 ? '+' : ''}{formatNumber(rate)}/s
                </span>
              </div>
            </div>
          );
        })}
      </header>

      {/* Main Content Area */}
      <main className="flex-1 flex flex-col md:flex-row overflow-hidden relative">
        
        {/* Interaction Sector */}
        <section 
          className="relative flex flex-col items-center justify-center h-[40vh] md:h-auto md:flex-1 transition-all duration-1000 overflow-hidden"
          style={{ background: currentWorldDef.bgGradient }}
          onMouseDown={handleForgeClick}
        >
          {/* World Info */}
          <div className="absolute top-6 text-center pointer-events-none z-10">
            <h1 className="text-3xl md:text-5xl font-black tracking-tighter text-white uppercase opacity-90">{currentWorldDef.name}</h1>
            <p className="text-xs text-slate-400 font-mono tracking-widest mt-2 uppercase">{currentWorldDef.description}</p>
          </div>

          {/* Galaxy Map Button */}
          <div className="absolute top-4 right-4 z-20">
            <button 
              onClick={() => setActiveModal('galaxy_map')}
              className="p-3 rounded-full bg-blue-600/20 border border-blue-500/50 text-blue-300 hover:bg-blue-600 hover:text-white transition-all shadow-lg active:scale-95"
            >
              <Globe className="w-5 h-5" />
            </button>
          </div>

          {/* Interactive Forge Orb */}
          <div className="relative group cursor-pointer touch-manipulation z-10 active:scale-95 transition-transform duration-150">
            <div className="absolute -inset-10 bg-blue-500/20 rounded-full blur-3xl animate-pulse"></div>
            <div className={`w-48 h-48 md:w-72 md:h-72 rounded-full p-2 bg-gradient-to-br from-blue-500 via-slate-900 to-slate-950 shadow-[0_0_60px_rgba(59,130,246,0.4)] relative flex items-center justify-center group-hover:shadow-[0_0_100px_rgba(59,130,246,0.6)] transition-all duration-500`}>
              <div className="w-full h-full rounded-full bg-slate-950 flex flex-col items-center justify-center border border-white/5 relative overflow-hidden">
                <Orbit className={`w-16 h-16 md:w-24 md:h-24 text-${currentWorldDef.color}-400 mb-2 animate-orbit`} />
                <span className="text-[10px] md:text-xs font-bold text-slate-500 uppercase tracking-[0.4em] group-hover:text-white transition-colors">FORGE</span>
                <div className="absolute inset-0 bg-white/0 group-active:bg-white/10 transition-colors"></div>
              </div>
            </div>
            
            {/* Ambient Rings */}
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[120%] h-[120%] border border-blue-500/10 rounded-full animate-orbit" style={{ animationDuration: '20s' }}></div>
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[140%] h-[140%] border border-blue-500/5 rounded-full animate-orbit" style={{ animationDirection: 'reverse', animationDuration: '30s' }}></div>
          </div>

          {/* Click Animations */}
          {clickAnims.map(a => (
            <div key={a.id} className="absolute pointer-events-none animate-float-up text-white font-black text-2xl z-50 drop-shadow-[0_0_10px_rgba(37,99,235,1)]" style={{ left: a.x, top: a.y - 100 }}>
              {a.val}
            </div>
          ))}
        </section>

        {/* Panel Sidebar */}
        <aside className="flex-1 flex flex-col w-full md:w-[380px] md:flex-none bg-slate-900/90 md:border-l border-slate-800 z-20 backdrop-blur-2xl shadow-2xl">
          {/* Sidebar Nav */}
          <nav className="flex border-b border-slate-800">
            {[
              { id: 'upgrades', icon: TrendingUp, label: 'Tech' },
              { id: 'stats', icon: Info, label: 'Stats' },
              { id: 'nexus', icon: Settings, label: 'Nexus' }
            ].map(tab => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`flex-1 py-4 flex flex-col items-center gap-1.5 transition-all relative ${activeTab === tab.id ? 'text-blue-400 bg-blue-400/5' : 'text-slate-500 hover:text-slate-300'}`}
              >
                <tab.icon className="w-5 h-5" />
                <span className="text-[9px] font-black uppercase tracking-widest">{tab.label}</span>
                {activeTab === tab.id && <div className="absolute bottom-0 left-0 w-full h-0.5 bg-blue-500"></div>}
              </button>
            ))}
          </nav>

          {/* Panel Content */}
          <div className="flex-1 overflow-y-auto p-4 space-y-4 custom-scrollbar">
            {activeTab === 'upgrades' && (
              <div className="space-y-3 pb-8">
                {/* Buy Controls */}
                <div className="flex justify-between items-center mb-4 px-1">
                  <span className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Upgrade Queue</span>
                  <div className="flex gap-1.5">
                    {[1, 10, 'MAX'].map(mode => (
                      <button
                        key={mode}
                        onClick={() => setBuyMode(mode as any)}
                        className={`px-3 py-1 rounded-lg text-[10px] font-bold border transition-all ${buyMode === mode ? 'bg-blue-600 border-blue-500 text-white' : 'bg-slate-800 border-slate-700 text-slate-500 hover:border-slate-500'}`}
                      >
                        {mode === 'MAX' ? 'MAX' : `${mode}X`}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Upgrade List */}
                {gameState.upgrades
                  .filter(u => u.worldId === gameState.currentWorld)
                  .map(u => {
                    const res = gameState.resources[u.resourceType];
                    const unlocked = res.totalEarned >= u.unlockedAt;
                    const purchase = calculateMaxBuy(u.baseCost, u.costMultiplier, u.level, res.amount, buyMode === 'MAX' ? 1000 : buyMode);
                    const canBuy = purchase.count > 0 && res.amount >= purchase.cost;

                    if (!unlocked) {
                      return (
                        <div key={u.id} className="p-4 rounded-2xl border border-slate-800 bg-slate-900/30 flex items-center justify-between opacity-40 grayscale">
                          <div className="flex items-center gap-4">
                            <Lock className="w-5 h-5 text-slate-600" />
                            <span className="text-xs font-bold text-slate-500 uppercase tracking-widest">Restricted Tech</span>
                          </div>
                          <span className="text-[10px] text-slate-600 font-mono">REQ: {formatNumber(u.unlockedAt)} {res.symbol}</span>
                        </div>
                      );
                    }

                    return (
                      <button
                        key={u.id}
                        onClick={() => buyUpgrade(u.id)}
                        disabled={!canBuy}
                        className={`w-full p-4 rounded-2xl border text-left transition-all relative overflow-hidden group ${canBuy ? 'bg-slate-800 border-slate-700 hover:border-blue-500/50 active:scale-[0.98]' : 'bg-slate-900/50 border-slate-800 opacity-60'}`}
                      >
                        <div className="flex justify-between items-start mb-1">
                          <div className="flex items-center gap-3">
                            <div className="p-2 rounded-lg bg-slate-950/50">
                              <Cpu className={`w-4 h-4 ${canBuy ? 'text-blue-400' : 'text-slate-600'}`} />
                            </div>
                            <span className="font-bold text-slate-100 text-sm">{u.name}</span>
                          </div>
                          <span className="text-[10px] px-2 py-0.5 rounded-full bg-slate-950 text-blue-400 font-mono font-bold">LV.{u.level}</span>
                        </div>
                        <p className="text-xs text-slate-400 mb-4 line-clamp-2 leading-relaxed">{u.description}</p>
                        <div className="flex justify-between items-end">
                          <div className="flex flex-col">
                            <span className="text-[9px] text-slate-500 font-bold uppercase mb-0.5 tracking-tighter">Cost</span>
                            <div className="flex items-center gap-1.5 font-mono text-xs">
                              <span className={canBuy ? 'text-green-400' : 'text-red-400'}>{formatNumber(purchase.cost)}</span>
                              <span className="text-slate-600">{res.symbol}</span>
                            </div>
                          </div>
                          <div className="text-right">
                            <span className="text-[9px] text-slate-500 font-bold uppercase mb-0.5 tracking-tighter">Output</span>
                            <div className="text-xs text-blue-300 font-mono font-bold">+{formatNumber(u.effect(u.level + purchase.count) - u.effect(u.level))}</div>
                          </div>
                        </div>
                      </button>
                    );
                  })}
              </div>
            )}

            {activeTab === 'stats' && (
              <div className="space-y-4 pb-8">
                <div className="p-5 rounded-2xl bg-slate-950/50 border border-slate-800">
                  <h3 className="text-xs font-black text-blue-400 uppercase tracking-widest mb-4 flex items-center gap-2 border-b border-slate-800 pb-2">
                    <Award className="w-4 h-4" /> Universe Metrics
                  </h3>
                  <div className="space-y-3">
                    <div className="flex justify-between items-center text-xs">
                      <span className="text-slate-500">Simulation Age</span>
                      <span className="font-mono text-blue-200">{Math.floor(gameState.playTime)}s</span>
                    </div>
                    <div className="flex justify-between items-center text-xs">
                      <span className="text-slate-500">Prestige Grade</span>
                      <span className="font-mono text-blue-200">LVL {gameState.prestigeCount}</span>
                    </div>
                    <div className="flex justify-between items-center text-xs">
                      <span className="text-slate-500">Active Modality</span>
                      <span className="font-mono text-blue-200 uppercase">{currentWorldDef.name}</span>
                    </div>
                  </div>
                </div>

                <div className="p-5 rounded-2xl bg-slate-950/50 border border-slate-800">
                  <h3 className="text-xs font-black text-slate-400 uppercase tracking-widest mb-4 flex items-center gap-2 border-b border-slate-800 pb-2">
                    <Star className="w-4 h-4" /> Lifetime Earnings
                  </h3>
                  <div className="space-y-3">
                    {(Object.values(gameState.resources) as Resource[]).map(res => (
                      <div key={res.id} className="flex justify-between items-center text-xs">
                        <span className="text-slate-500 flex items-center gap-2">
                          <span className="text-sm">{res.symbol}</span> {res.name}
                        </span>
                        <span className="font-mono text-slate-300">{formatNumber(res.totalEarned)}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {activeTab === 'nexus' && (
              <div className="space-y-4 pb-8">
                <div className="p-5 rounded-2xl bg-slate-950/50 border border-slate-800">
                  <h3 className="text-xs font-black text-slate-400 uppercase tracking-widest mb-4">Storage Protocol</h3>
                  <div className="flex gap-2 mb-4">
                    <button onClick={() => {}} className="flex-1 py-3 bg-slate-800 text-blue-400 border border-slate-700 rounded-xl text-xs font-bold flex items-center justify-center gap-2 hover:bg-slate-700 transition-colors">
                      <Download className="w-4 h-4" /> Export
                    </button>
                    <button onClick={() => {}} className="flex-1 py-3 bg-slate-800 text-green-400 border border-slate-700 rounded-xl text-xs font-bold flex items-center justify-center gap-2 hover:bg-slate-700 transition-colors">
                      <Upload className="w-4 h-4" /> Import
                    </button>
                  </div>
                  <div className="flex items-center justify-between text-[10px] text-slate-500 bg-slate-950/50 p-3 rounded-xl border border-slate-800">
                    <span className="flex items-center gap-2"><Save className="w-3.5 h-3.5"/> LOCAL BACKUP</span>
                    <span className="text-blue-400 font-bold">READY</span>
                  </div>
                </div>

                <div className="p-5 rounded-2xl bg-slate-950/50 border border-slate-800">
                  <h3 className="text-xs font-black text-slate-400 uppercase tracking-widest mb-4">Extended Systems</h3>
                  <button onClick={() => setActiveModal('mod_browser')} className="w-full py-3 bg-purple-900/20 hover:bg-purple-900/30 text-purple-300 border border-purple-500/30 rounded-2xl text-xs font-bold flex items-center justify-center gap-3 transition-all mb-3">
                    <Cloud className="w-4 h-4" /> MOD BROWSER
                  </button>
                  <button onClick={requestWipe} className="w-full py-3 bg-red-900/10 border border-red-900/20 text-red-500 rounded-2xl text-[10px] font-bold flex items-center justify-center gap-2 hover:bg-red-900/20 transition-all">
                    WIPE CORE MEMORY
                  </button>
                </div>

                <div className="p-5 rounded-2xl bg-slate-950/50 border border-slate-800">
                   <h3 className="text-xs font-black text-slate-400 uppercase tracking-widest mb-2">Cloud Sync</h3>
                   {CloudService.isAvailable ? (
                     <button onClick={isCloudSignedIn ? handleCloudSave : handleCloudConnect} className="w-full py-3 bg-slate-800 text-white border border-slate-700 rounded-2xl text-xs font-bold">
                        {isCloudSignedIn ? 'Save to Cloud' : 'Connect Account'}
                     </button>
                   ) : (
                     <div className="text-[10px] text-slate-500 text-center">Mobile Only</div>
                   )}
                </div>
              </div>
            )}
          </div>
        </aside>
      </main>

      {/* Mod Browser Modal */}
      {activeModal === 'mod_browser' && (
        <div className="absolute inset-0 z-50 bg-slate-950/90 backdrop-blur-xl flex flex-col p-6 animate-fade-in overflow-y-auto custom-scrollbar">
          <div className="flex justify-between items-center mb-8 sticky top-0 bg-slate-950/80 p-4 rounded-2xl z-20">
            <h2 className="text-xl font-black text-white uppercase tracking-tighter flex items-center gap-4">
              <Cloud className="w-6 h-6 text-purple-500" /> MODIFICATIONS
            </h2>
            <button onClick={() => setActiveModal(null)} className="p-3 hover:bg-slate-800 rounded-full text-slate-400 hover:text-white transition-all">
              <X className="w-6 h-6" />
            </button>
          </div>
          <div className="mb-4 text-center">
            <button onClick={fetchMods} disabled={isModBrowserLoading} className="px-6 py-2 bg-purple-600 rounded-full text-xs font-bold uppercase hover:bg-purple-500 transition-all">
              {isModBrowserLoading ? 'Scanning...' : 'Refresh Feed'}
            </button>
          </div>
          <div className="grid gap-4 max-w-3xl mx-auto w-full">
            {availableMods.map((mod: any) => (
              <div key={mod.id} className="p-4 rounded-xl bg-slate-900/50 border border-slate-800 flex justify-between items-center">
                 <div>
                   <h4 className="text-sm font-bold text-white">{mod.name}</h4>
                   <p className="text-xs text-slate-400">{mod.summary}</p>
                 </div>
                 <button className="px-4 py-2 bg-slate-800 rounded text-[10px] font-bold uppercase hover:bg-slate-700">Install</button>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Galaxy Map Modal */}
      {activeModal === 'galaxy_map' && (
        <div className="absolute inset-0 z-50 bg-slate-950/90 backdrop-blur-xl flex flex-col p-6 animate-fade-in overflow-y-auto custom-scrollbar">
          <div className="flex justify-between items-center mb-8 sticky top-0 bg-slate-950/80 p-4 rounded-2xl z-20">
            <h2 className="text-2xl font-black text-white uppercase tracking-tighter flex items-center gap-4">
              <Globe className="w-8 h-8 text-blue-500" /> MULTIVERSE CONDUIT
            </h2>
            <button onClick={() => setActiveModal(null)} className="p-3 hover:bg-slate-800 rounded-full text-slate-400 hover:text-white transition-all">
              <X className="w-8 h-8" />
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 max-w-6xl mx-auto w-full pb-20">
            {WORLDS.map(world => {
              const isUnlocked = gameState.unlockedWorlds.includes(world.id);
              const isCurrent = gameState.currentWorld === world.id;
              const unlockReq = world.unlockReq;
              const canUnlock = !isUnlocked && gameState.resources[unlockReq.resource].amount >= unlockReq.amount;

              return (
                <div 
                  key={world.id} 
                  className={`relative overflow-hidden rounded-3xl border transition-all p-6 flex flex-col justify-between h-64 ${isCurrent ? 'border-blue-500 bg-blue-900/20' : isUnlocked ? 'border-slate-800 bg-slate-900/50 hover:border-slate-600' : 'border-slate-900 bg-slate-950/50 opacity-60'}`}
                >
                  <div className="absolute inset-0 opacity-20 pointer-events-none" style={{ background: world.bgGradient }}></div>
                  
                  <div className="relative z-10">
                    <div className="flex justify-between items-start mb-2">
                      <h4 className={`text-xl font-black uppercase tracking-widest ${isCurrent ? 'text-blue-300' : 'text-white'}`}>{world.name}</h4>
                      {isCurrent && <span className="text-[10px] bg-blue-500 text-white font-bold px-3 py-1 rounded-full uppercase">Active</span>}
                    </div>
                    <p className="text-xs text-slate-400 mb-4 leading-relaxed line-clamp-2">{world.description}</p>
                    <div className="flex items-center gap-3 text-[10px] font-mono text-slate-500">
                      <span>Primary:</span>
                      <span className={`text-${world.color}-400 font-bold uppercase`}>{gameState.resources[world.primaryResource].name}</span>
                    </div>
                  </div>

                  <div className="relative z-10">
                    {isCurrent ? (
                      <button disabled className="w-full py-3 rounded-xl bg-blue-600/20 text-blue-400 font-bold text-xs uppercase cursor-default">Current Location</button>
                    ) : isUnlocked ? (
                      <button onClick={() => switchWorld(world.id)} className="w-full py-3 rounded-xl bg-blue-600 hover:bg-blue-500 text-white font-bold text-xs uppercase transition-all shadow-xl shadow-blue-900/20">Initialize Warp Drive</button>
                    ) : (
                      <button 
                        disabled={!canUnlock}
                        className={`w-full py-3 rounded-xl font-bold text-xs uppercase border transition-all ${canUnlock ? 'bg-green-600/10 border-green-500 text-green-400 hover:bg-green-600 hover:text-white' : 'border-slate-800 text-slate-600 cursor-not-allowed'}`}
                      >
                        {canUnlock ? 'Establish Link' : `Requires ${formatNumber(unlockReq.amount)} ${gameState.resources[unlockReq.resource].name}`}
                      </button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
};

export default App;