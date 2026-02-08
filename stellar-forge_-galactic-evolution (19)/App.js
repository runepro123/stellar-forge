import React, { useState, useEffect, useRef, useMemo } from 'react';
import htm from 'htm';
import { 
  Zap, Atom, Database, Sparkles, TrendingUp, Cpu, Settings, 
  Info, Lock, Orbit, AlertTriangle, Award, ChevronRight, RefreshCw,
  Play, RotateCcw, Monitor, Globe, Shield, X, CheckCircle,
  Save, Download, Upload, Cloud, Smartphone, Star, Flame, Trophy,
  Terminal, Activity, ZapOff
} from 'lucide-react';
import { INITIAL_STATE, WORLDS, APP_CONFIG, ACHIEVEMENTS, SFX } from './constants.js';
import { formatNumber, calculateMaxBuy } from './utils.js';
import { CloudService } from './cloudService.js';
import { ModIOService } from './modioService.js';

const html = htm.bind(React.createElement);

// --- AUDIO SYSTEM ---
const playSound = (type) => {
    const AudioContext = window.AudioContext || window.webkitAudioContext;
    if (!AudioContext) return;
    
    const ctx = new AudioContext();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    
    osc.connect(gain);
    gain.connect(ctx.destination);
    
    const now = ctx.currentTime;
    
    if (type === 'click') {
        osc.type = 'sine';
        osc.frequency.setValueAtTime(800, now);
        osc.frequency.exponentialRampToValueAtTime(300, now + 0.1);
        gain.gain.setValueAtTime(0.1, now);
        gain.gain.exponentialRampToValueAtTime(0.01, now + 0.1);
        osc.start(now);
        osc.stop(now + 0.1);
    } else if (type === 'upgrade') {
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(400, now);
        osc.frequency.linearRampToValueAtTime(800, now + 0.1);
        gain.gain.setValueAtTime(0.1, now);
        gain.gain.linearRampToValueAtTime(0, now + 0.3);
        osc.start(now);
        osc.stop(now + 0.3);
    } else if (type === 'error') {
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(150, now);
        osc.frequency.linearRampToValueAtTime(100, now + 0.2);
        gain.gain.setValueAtTime(0.1, now);
        gain.gain.linearRampToValueAtTime(0, now + 0.2);
        osc.start(now);
        osc.stop(now + 0.2);
    }
};

// --- LOGO COMPONENT ---
const DevCityLogo = ({ className }) => html`
  <svg viewBox="0 0 200 200" className=${className} xmlns="http://www.w3.org/2000/svg">
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
`;

// --- COMET COMPONENT ---
const Comet = ({ onClick }) => html`
  <div 
    className="fixed top-[20%] left-[-100px] w-24 h-24 z-50 cursor-pointer comet-anim"
    onClick=${onClick}
    style=${{ filter: 'drop-shadow(0 0 15px rgba(255, 165, 0, 0.8))' }}
  >
    <div className="w-8 h-8 bg-orange-100 rounded-full animate-pulse absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2"></div>
    <div className="w-32 h-2 bg-gradient-to-l from-transparent to-orange-500 absolute top-1/2 right-1/2 -translate-y-1/2 origin-right rounded-full opacity-80"></div>
    <${Flame} className="w-10 h-10 text-orange-400 absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 animate-spin" />
  </div>
`;

const App = () => {
  const [scene, setScene] = useState('boot');
  const [activeModal, setActiveModal] = useState(null);
  const [activeTab, setActiveTab] = useState('upgrades');
  const [buyMode, setBuyMode] = useState(1);
  const [cometActive, setCometActive] = useState(false);
  const [activeToasts, setActiveToasts] = useState([]);
  
  const [isCloudSignedIn, setIsCloudSignedIn] = useState(false);
  const [cloudStatus, setCloudStatus] = useState('idle');
  const [availableMods, setAvailableMods] = useState([]);
  const [isModBrowserLoading, setIsModBrowserLoading] = useState(false);

  const [gameState, setGameState] = useState(() => {
    const saved = localStorage.getItem('stellar_forge_v5');
    if (saved) {
      try {
        const parsed = JSON.parse(saved);
        const hydratedUpgrades = INITIAL_STATE.upgrades.map(baseU => {
          const savedU = (parsed.upgrades || []).find((u) => u.id === baseU.id);
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

  const [clickAnims, setClickAnims] = useState([]);
  const logsEndRef = useRef(null);
  
  const stateRef = useRef(gameState);
  stateRef.current = gameState;
  const lastTickRef = useRef(Date.now());
  const cometTimerRef = useRef(0);

  const currentWorldDef = useMemo(() => {
    return WORLDS.find(w => w.id === gameState.currentWorld) || WORLDS[0];
  }, [gameState.currentWorld]);

  const prestigePotential = useMemo(() => {
     const totalLifetime = Object.values(gameState.resources).reduce((acc, res) => acc + (res.totalEarned || 0), 0);
     if (totalLifetime < 1000000) return 0;
     const potential = Math.floor(Math.sqrt(totalLifetime / 1000000));
     return Math.max(0, potential - gameState.prestigeCount);
  }, [gameState.resources]);

  useEffect(() => {
    if (scene === 'boot') {
      const timer = setTimeout(() => setScene('title'), 2500);
      checkCloudAuth();
      return () => clearTimeout(timer);
    }
  }, [scene]);

  useEffect(() => {
      if (logsEndRef.current && activeTab === 'stats') {
          logsEndRef.current.scrollIntoView({ behavior: "smooth" });
      }
  }, [gameState.logs, activeTab]);

  const checkCloudAuth = async () => {
    if (CloudService.isAvailable) {
      const isAuth = await CloudService.isAuthenticated();
      setIsCloudSignedIn(isAuth);
    }
  };

  const showToast = (title, message, icon = 'Info') => {
    const id = Date.now();
    setActiveToasts(prev => [...prev, { id, title, message, icon }]);
    setTimeout(() => setActiveToasts(prev => prev.filter(t => t.id !== id)), 4000);
  };

  const addLog = (text, type = 'info') => {
      setGameState(prev => {
          const newLog = { id: Date.now(), text, type };
          const logs = [...(prev.logs || []), newLog].slice(-50); 
          return { ...prev, logs };
      });
  };

  const unlockAchievement = (ach) => {
    setGameState(prev => {
        if ((prev.unlockedAchievements || []).includes(ach.id)) return prev;
        showToast('Achievement Unlocked!', ach.name, 'Trophy');
        playSound('unlock');
        return {
            ...prev,
            unlockedAchievements: [...(prev.unlockedAchievements || []), ach.id],
            logs: [...(prev.logs || []), { id: Date.now(), text: `ACHIEVEMENT: ${ach.name} - ${ach.description}`, type: 'success' }]
        };
    });
  };

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
        const prestigeMultiplier = 1 + (prev.prestigeCount * 0.1);
        
        let generated = false;
        prev.upgrades.forEach(u => {
          if (u.type === 'passive') {
            const prod = u.effect(u.level) * delta * prestigeMultiplier;
            if (prod > 0 && nextResources[u.targetResource]) {
              nextResources[u.targetResource] = {
                ...nextResources[u.targetResource],
                amount: nextResources[u.targetResource].amount + prod,
                totalEarned: nextResources[u.targetResource].totalEarned + prod
              };
              generated = true;
            }
          }
        });

        ACHIEVEMENTS.forEach(ach => {
          if (!(prev.unlockedAchievements || []).includes(ach.id) && ach.condition(prev)) {
             setTimeout(() => unlockAchievement(ach), 0);
          }
        });

        if (!cometActive) {
            cometTimerRef.current += delta;
            if (cometTimerRef.current > 45 && Math.random() < 0.005) { 
                setCometActive(true);
                cometTimerRef.current = 0;
                setTimeout(() => setCometActive(false), 8000);
            }
        }

        return {
          ...prev,
          resources: nextResources,
          playTime: prev.playTime + delta
        };
      });
    }, 100);
    return () => clearInterval(loop);
  }, [scene, cometActive]);

  const handleCloudConnect = async () => {
    setCloudStatus('loading');
    try {
      await CloudService.login();
      setIsCloudSignedIn(true);
      setCloudStatus('success');
      showToast('Cloud Sync', 'Connected to Google Play Games', 'Cloud');
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
      showToast('Cloud Save', 'Game progress uploaded safely.', 'Save');
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

  useEffect(() => {
    const saver = setInterval(() => {
      const serializable = {
        ...stateRef.current,
        upgrades: stateRef.current.upgrades.map(({ effect, ...rest }) => rest)
      };
      localStorage.setItem('stellar_forge_v5', JSON.stringify(serializable));
    }, 5000);
    return () => clearInterval(saver);
  }, []);

  const handleForgeClick = (e) => {
    const touches = e.touches ? Array.from(e.touches) : [{ clientX: e.clientX, clientY: e.clientY }];
    
    touches.forEach(t => {
        const clickUpgrade = gameState.upgrades.find(u => u.type === 'click' && u.worldId === gameState.currentWorld);
        const prestigeMultiplier = 1 + (gameState.prestigeCount * 0.1);
        const clickPower = (clickUpgrade ? clickUpgrade.effect(clickUpgrade.level) : 1) * prestigeMultiplier;
        const targetResId = currentWorldDef.primaryResource;

        playSound('click');

        setGameState(prev => {
          const res = prev.resources[targetResId];
          return {
            ...prev,
            stats: { ...prev.stats, clicks: (prev.stats?.clicks || 0) + 1 },
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
        setClickAnims(prev => [...prev, { id, x: t.clientX, y: t.clientY, val: `+${formatNumber(clickPower)}` }]);
        setTimeout(() => setClickAnims(prev => prev.filter(a => a.id !== id)), 800);
    });
  };

  const handleCometClick = (e) => {
      e.stopPropagation();
      setCometActive(false);
      const bonus = (gameState.resources.energy.amount * 0.15) + 1000 * (gameState.prestigeCount + 1);
      setGameState(prev => ({
          ...prev,
          stats: { ...prev.stats, cometsClicked: (prev.stats?.cometsClicked || 0) + 1 },
          resources: {
              ...prev.resources,
              energy: { ...prev.resources.energy, amount: prev.resources.energy.amount + bonus }
          }
      }));
      showToast('Comet Captured!', `+${formatNumber(bonus)} Energy`, 'Flame');
      playSound('unlock');
      addLog(`COMET INTERCEPTED. Gained ${formatNumber(bonus)} Energy.`, 'success');
  };

  const buyUpgrade = (upgradeId) => {
    setGameState(prev => {
      const u = prev.upgrades.find(up => up.id === upgradeId);
      if (!u) return prev;
      
      const res = prev.resources[u.resourceType];
      const purchase = calculateMaxBuy(u.baseCost, u.costMultiplier, u.level, res.amount, buyMode === 'MAX' ? 1000 : buyMode);
      
      if (purchase.count > 0 && res.amount >= purchase.cost) {
        playSound('upgrade');
        return {
          ...prev,
          resources: {
            ...prev.resources,
            [u.resourceType]: { ...res, amount: res.amount - purchase.cost }
          },
          upgrades: prev.upgrades.map(up => up.id === upgradeId ? { ...up, level: up.level + purchase.count } : up)
        };
      } else {
          playSound('error');
      }
      return prev;
    });
  };

  const performPrestige = () => {
      if (prestigePotential <= 0) return;
      const newPrestigeCount = gameState.prestigeCount + prestigePotential;
      const resetResources = { ...INITIAL_STATE.resources };
      const resetUpgrades = INITIAL_STATE.upgrades.map(u => ({ ...u, level: 0 }));

      setGameState(prev => ({
          ...prev,
          resources: resetResources,
          upgrades: resetUpgrades,
          prestigeCount: newPrestigeCount,
          currentWorld: 'prime', 
          logs: [...(prev.logs || []), { id: Date.now(), text: `UNIVERSE REBOOTED. Prestige Level ${newPrestigeCount}. Multiplier active.`, type: 'warning' }]
      }));
      
      setActiveModal(null);
      playSound('unlock');
      showToast('UNIVERSE REBORN', `Ascended to Level ${newPrestigeCount}`, 'Zap');
  };

  const switchWorld = (worldId) => {
    setGameState(prev => ({ ...prev, currentWorld: worldId }));
    setActiveModal(null);
    playSound('click');
  };

  const requestWipe = () => setActiveModal('wipe_confirm');
  
  const confirmWipe = () => {
    localStorage.removeItem('stellar_forge_v5');
    setGameState(INITIAL_STATE);
    setActiveModal(null);
    setScene('boot');
  };

  const getPassiveRate = (resId) => {
    const prestigeBonus = 1 + (gameState.prestigeCount * 0.1);
    return gameState.upgrades
      .filter(u => u.targetResource === resId && u.type === 'passive')
      .reduce((sum, u) => sum + u.effect(u.level), 0) * prestigeBonus;
  };

  if (scene === 'boot') {
    return html`
      <div className="h-screen w-screen flex flex-col items-center justify-center bg-slate-950 overflow-hidden">
        <${DevCityLogo} className="w-32 h-32 md:w-48 md:h-48 mb-6 animate-pulse-glow" />
        <div className="flex flex-col items-center animate-fade-in" style=${{ animationDelay: '1s' }}>
          <h1 className="text-3xl font-black tracking-widest text-white uppercase">Dev City</h1>
          <h2 className="text-lg font-light tracking-[0.5em] text-blue-500 uppercase font-mono">Studio</h2>
        </div>
      </div>
    `;
  }

  if (scene === 'title') {
    return html`
      <div 
        className="h-screen w-screen flex flex-col items-center justify-center bg-slate-950 relative overflow-hidden cursor-pointer"
        onClick=${() => setScene('menu')}
      >
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,_#1e3a8a_0%,_#020617_80%)] opacity-40"></div>
        <div className="z-10 text-center animate-fade-in px-6">
          <h1 className="text-6xl md:text-9xl font-black text-transparent bg-clip-text bg-gradient-to-b from-blue-100 to-blue-600 uppercase tracking-tighter mb-2 drop-shadow-2xl">STELLAR</h1>
          <h1 className="text-5xl md:text-8xl font-black text-transparent bg-clip-text bg-gradient-to-b from-blue-400 to-indigo-900 uppercase tracking-tighter mb-12 drop-shadow-2xl">FORGE</h1>
          <p className="text-blue-400 font-mono tracking-[0.5em] animate-pulse text-sm bg-blue-900/20 px-4 py-2 rounded-full border border-blue-500/30">TAP TO INITIALIZE</p>
        </div>
        <div className="absolute bottom-10 text-slate-600 text-[10px] font-mono tracking-widest uppercase">
          Build v${APP_CONFIG.VERSION}
        </div>
      </div>
    `;
  }

  if (scene === 'menu') {
    return html`
      <div className="h-screen w-screen flex items-center justify-center bg-slate-950 relative overflow-hidden p-6">
        <div className="absolute inset-0 z-0">
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-blue-900/10 rounded-full blur-3xl animate-pulse"></div>
        </div>
        
        <div className="z-10 w-full max-w-sm glass-panel rounded-3xl p-8 animate-slide-up flex flex-col gap-4 shadow-2xl relative border-t border-blue-500/20">
          
          ${activeModal === 'settings' && html`
            <div className="absolute inset-0 z-20 bg-slate-900/95 backdrop-blur-xl rounded-2xl p-6 flex flex-col animate-fade-in">
              <div className="flex justify-between items-center mb-6 border-b border-slate-800 pb-2">
                <h3 className="text-white font-bold uppercase tracking-widest flex items-center gap-2">
                  <${Settings} className="w-4 h-4 text-blue-400" /> Settings
                </h3>
                <button onClick=${() => setActiveModal(null)}><${X} className="w-5 h-5 text-slate-400" /></button>
              </div>
              <div className="space-y-4">
                <div className="p-4 bg-slate-800/50 rounded-lg border border-slate-700">
                   <h4 className="text-xs font-bold text-green-400 uppercase tracking-wider mb-2 flex items-center gap-2">
                     <${Cloud} className="w-3 h-3" /> Cloud Sync
                   </h4>
                   ${CloudService.isAvailable ? (
                     isCloudSignedIn ? html`
                       <div className="flex flex-col gap-2">
                         <span className="text-[10px] text-green-300 font-mono">CONNECTED</span>
                         <button onClick=${handleCloudSave} disabled=${cloudStatus === 'loading'} className="py-2 bg-slate-700 hover:bg-slate-600 rounded text-[10px] font-bold uppercase transition-colors">
                            ${cloudStatus === 'loading' ? 'Syncing...' : 'Save to Cloud'}
                         </button>
                       </div>
                     ` : html`
                       <button onClick=${handleCloudConnect} className="w-full py-2 bg-green-600 hover:bg-green-500 rounded text-xs font-bold uppercase">
                         Connect Google Play
                       </button>
                     `
                   ) : html`
                     <p className="text-[10px] text-slate-500 italic">Cloud features require Android</p>
                   `}
                </div>
              </div>
            </div>
          `}

          <div className="text-center mb-4">
            <h2 className="text-xl font-bold text-white uppercase tracking-widest mb-1">COMMAND DECK</h2>
            <div className="h-1 w-12 bg-blue-500 mx-auto rounded-full"></div>
          </div>

          <button 
            onClick=${() => setScene('game')}
            className="w-full p-4 rounded-2xl flex items-center justify-between bg-blue-600/20 border border-blue-500/50 hover:bg-blue-600/40 hover:border-blue-400 transition-all active:scale-95 group"
          >
            <div className="flex items-center gap-4">
              <${Play} className="w-6 h-6 text-blue-400" />
              <div className="text-left">
                <div className="text-xs font-bold text-white uppercase">Resume Simulation</div>
                <div className="text-[10px] text-slate-400 font-mono">Cycle: ${Math.floor(gameState.playTime)}s</div>
              </div>
            </div>
            <${ChevronRight} className="w-5 h-5 text-blue-400 group-hover:translate-x-1 transition-transform" />
          </button>

          <button 
            onClick=${() => setActiveModal('settings')}
            className="w-full p-4 rounded-2xl flex items-center gap-4 bg-slate-900/40 border border-slate-800 hover:border-slate-600 transition-all"
          >
            <${Settings} className="w-6 h-6 text-slate-400" />
            <span className="text-xs font-bold text-slate-200 uppercase tracking-widest">System Params</span>
          </button>

          <button 
            onClick=${requestWipe}
            className="w-full p-4 rounded-2xl flex items-center gap-4 bg-slate-900/40 border border-slate-800 hover:border-red-600/40 transition-all group"
          >
            <${AlertTriangle} className="w-6 h-6 text-slate-500 group-hover:text-red-500 transition-colors" />
            <span className="text-xs font-bold text-slate-400 group-hover:text-red-400 uppercase tracking-widest">Wipe Memory</span>
          </button>

          <div className="mt-4 pt-4 border-t border-slate-800 flex justify-center items-center gap-3 opacity-50">
            <${DevCityLogo} className="w-6 h-6" />
            <span className="text-[10px] uppercase tracking-[0.3em] font-light">Dev City Studio</span>
          </div>
        </div>

        ${activeModal === 'wipe_confirm' && html`
          <div className="absolute inset-0 z-50 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-6">
            <div className="w-full max-w-xs glass-panel rounded-3xl p-8 text-center animate-fade-in shadow-3xl border-red-500/20">
              <${AlertTriangle} className="w-16 h-16 text-red-500 mx-auto mb-6 animate-pulse" />
              <h3 className="text-xl font-bold text-white uppercase mb-2">CRITICAL ACTION</h3>
              <p className="text-sm text-slate-400 mb-8 leading-relaxed">System purge will erase all progress. Are you sure you wish to initialize factory reset?</p>
              <div className="flex flex-col gap-3">
                <button onClick=${confirmWipe} className="w-full py-3 rounded-xl bg-red-600 hover:bg-red-500 text-white font-bold uppercase text-xs transition-colors">Confirm Purge</button>
                <button onClick=${() => setActiveModal(null)} className="w-full py-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 font-bold uppercase text-xs transition-colors">Abort Mission</button>
              </div>
            </div>
          </div>
        `}
      </div>
    `;
  }

  return html`
    <div className="flex flex-col h-screen bg-slate-950 text-slate-100 overflow-hidden select-none font-sans animate-fade-in">
      
      <div className="fixed top-24 right-4 z-50 flex flex-col gap-2 pointer-events-none">
        ${activeToasts.map(toast => html`
          <div key=${toast.id} className="toast-anim bg-slate-900/90 border border-blue-500/30 backdrop-blur-md p-4 rounded-xl shadow-2xl flex items-center gap-4 min-w-[280px]">
            <div className="p-2 bg-blue-500/20 rounded-lg">
              ${toast.icon === 'Trophy' ? html`<${Trophy} className="w-6 h-6 text-yellow-400" />` : html`<${Info} className="w-6 h-6 text-blue-400" />`}
            </div>
            <div>
              <div className="text-sm font-bold text-white">${toast.title}</div>
              <div className="text-xs text-slate-300">${toast.message}</div>
            </div>
          </div>
        `)}
      </div>

      <header className="shrink-0 flex gap-2 p-2 bg-slate-900/80 border-b border-slate-800 backdrop-blur-xl z-40 overflow-x-auto custom-scrollbar no-scrollbar">
        ${currentWorldDef.visibleResources.map(resId => {
          const res = gameState.resources[resId];
          const rate = getPassiveRate(resId);
          return html`
            <div key=${resId} className="flex flex-col px-4 py-2 rounded-xl bg-slate-950/50 border border-slate-800/50 min-w-[120px] transition-colors hover:border-slate-700">
              <div className="flex items-center gap-2 text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-1">
                <span className="text-sm">${res.symbol}</span>
                <span>${res.name}</span>
              </div>
              <div className="flex flex-col">
                <span className="text-base font-mono font-bold text-white">${formatNumber(res.amount)}</span>
                <span className=${`text-[10px] font-mono ${rate > 0 ? 'text-green-500' : 'text-slate-600'}`}>
                  ${rate > 0 ? '+' : ''}${formatNumber(rate)}/s
                </span>
              </div>
            </div>
          `;
        })}
      </header>

      <main className="flex-1 flex flex-col md:flex-row overflow-hidden relative">
        
        <section 
          className="relative flex flex-col items-center justify-center h-[40vh] md:h-auto md:flex-1 transition-all duration-1000 overflow-hidden"
          style=${{ background: currentWorldDef.bgGradient }}
          onMouseDown=${handleForgeClick}
          onTouchStart=${handleForgeClick}
        >
          <div className="absolute top-6 text-center pointer-events-none z-10 select-none">
            <h1 className="text-3xl md:text-5xl font-black tracking-tighter text-white uppercase opacity-90 drop-shadow-lg">${currentWorldDef.name}</h1>
            <p className="text-xs text-slate-400 font-mono tracking-widest mt-2 uppercase flex items-center justify-center gap-2">
               ${currentWorldDef.description}
            </p>
            ${gameState.prestigeCount > 0 && html`
              <div className="mt-2 inline-flex items-center gap-2 px-3 py-1 rounded-full bg-yellow-500/20 border border-yellow-500/50 text-yellow-300 text-[10px] font-bold uppercase tracking-widest">
                 <${Zap} className="w-3 h-3" /> Prestige Level ${gameState.prestigeCount}
              </div>
            `}
          </div>

          <div className="absolute top-4 right-4 z-20 flex flex-col gap-2">
            <button 
              onClick=${() => setActiveModal('galaxy_map')}
              className="p-3 rounded-full bg-blue-600/20 border border-blue-500/50 text-blue-300 hover:bg-blue-600 hover:text-white transition-all shadow-lg active:scale-95"
            >
              <${Globe} className="w-5 h-5" />
            </button>
             <button 
              onClick=${() => setActiveModal('ascension')}
              className="p-3 rounded-full bg-purple-600/20 border border-purple-500/50 text-purple-300 hover:bg-purple-600 hover:text-white transition-all shadow-lg active:scale-95"
            >
              <${Zap} className="w-5 h-5" />
            </button>
          </div>

          ${cometActive && html`<${Comet} onClick=${handleCometClick} />`}

          <div className="relative group cursor-pointer touch-manipulation z-10 active:scale-95 transition-transform duration-150 select-none -webkit-tap-highlight-color-transparent">
            <div className="absolute -inset-10 bg-blue-500/20 rounded-full blur-3xl animate-pulse"></div>
            <div className=${`w-48 h-48 md:w-72 md:h-72 rounded-full p-2 bg-gradient-to-br from-blue-500 via-slate-900 to-slate-950 shadow-[0_0_60px_rgba(59,130,246,0.4)] relative flex items-center justify-center group-hover:shadow-[0_0_100px_rgba(59,130,246,0.6)] transition-all duration-500`}>
              <div className="w-full h-full rounded-full bg-slate-950 flex flex-col items-center justify-center border border-white/5 relative overflow-hidden">
                <${Orbit} className=${`w-16 h-16 md:w-24 md:h-24 text-${currentWorldDef.color}-400 mb-2 animate-orbit`} />
                <span className="text-[10px] md:text-xs font-bold text-slate-500 uppercase tracking-[0.4em] group-hover:text-white transition-colors">FORGE</span>
                <div className="absolute inset-0 bg-white/0 group-active:bg-white/10 transition-colors"></div>
              </div>
            </div>
            
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[120%] h-[120%] border border-blue-500/10 rounded-full animate-orbit" style=${{ animationDuration: '20s' }}></div>
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[140%] h-[140%] border border-blue-500/5 rounded-full animate-orbit" style=${{ animationDirection: 'reverse', animationDuration: '30s' }}></div>
          </div>

          ${clickAnims.map(a => html`
            <div key=${a.id} className="absolute pointer-events-none animate-float-up text-white font-black text-2xl z-50 drop-shadow-[0_0_10px_rgba(37,99,235,1)]" style=${{ left: a.x, top: a.y - 100 }}>
              ${a.val}
            </div>
          `)}
        </section>

        <aside className="flex-1 flex flex-col w-full md:w-[380px] md:flex-none bg-slate-900/90 md:border-l border-slate-800 z-20 backdrop-blur-2xl shadow-2xl">
          <nav className="flex border-b border-slate-800">
            ${[
              { id: 'upgrades', icon: TrendingUp, label: 'Tech' },
              { id: 'stats', icon: Activity, label: 'Data' },
              { id: 'achievements', icon: Trophy, label: 'Awards' },
              { id: 'nexus', icon: Settings, label: 'Nexus' }
            ].map(tab => html`
              <button
                key=${tab.id}
                onClick=${() => setActiveTab(tab.id)}
                className=${`flex-1 py-4 flex flex-col items-center gap-1.5 transition-all relative ${activeTab === tab.id ? 'text-blue-400 bg-blue-400/5' : 'text-slate-500 hover:text-slate-300'}`}
              >
                <${tab.icon} className="w-5 h-5" />
                <span className="text-[9px] font-black uppercase tracking-widest">${tab.label}</span>
                ${activeTab === tab.id && html`<div className="absolute bottom-0 left-0 w-full h-0.5 bg-blue-500"></div>`}
              </button>
            `)}
          </nav>

          <div className="flex-1 overflow-y-auto p-4 space-y-4 custom-scrollbar">
            ${activeTab === 'upgrades' && html`
              <div className="space-y-3 pb-8">
                <div className="flex justify-between items-center mb-4 px-1">
                  <span className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Upgrade Queue</span>
                  <div className="flex gap-1.5">
                    ${[1, 10, 'MAX'].map(mode => html`
                      <button
                        key=${mode}
                        onClick=${() => setBuyMode(mode)}
                        className=${`px-3 py-1 rounded-lg text-[10px] font-bold border transition-all ${buyMode === mode ? 'bg-blue-600 border-blue-500 text-white' : 'bg-slate-800 border-slate-700 text-slate-500 hover:border-slate-500'}`}
                      >
                        ${mode === 'MAX' ? 'MAX' : `${mode}X`}
                      </button>
                    `)}
                  </div>
                </div>

                ${gameState.upgrades
                  .filter(u => u.worldId === gameState.currentWorld)
                  .map(u => {
                    const res = gameState.resources[u.resourceType];
                    const unlocked = res.totalEarned >= u.unlockedAt;
                    const purchase = calculateMaxBuy(u.baseCost, u.costMultiplier, u.level, res.amount, buyMode === 'MAX' ? 1000 : buyMode);
                    const canBuy = purchase.count > 0 && res.amount >= purchase.cost;

                    if (!unlocked) {
                      return html`
                        <div key=${u.id} className="p-4 rounded-2xl border border-slate-800 bg-slate-900/30 flex items-center justify-between opacity-40 grayscale">
                          <div className="flex items-center gap-4">
                            <${Lock} className="w-5 h-5 text-slate-600" />
                            <span className="text-xs font-bold text-slate-500 uppercase tracking-widest">Restricted Tech</span>
                          </div>
                          <span className="text-[10px] text-slate-600 font-mono">REQ: ${formatNumber(u.unlockedAt)} ${res.symbol}</span>
                        </div>
                      `;
                    }

                    return html`
                      <button
                        key=${u.id}
                        onClick=${() => buyUpgrade(u.id)}
                        disabled=${!canBuy}
                        className=${`w-full p-4 rounded-2xl border text-left transition-all relative overflow-hidden group ${canBuy ? 'bg-slate-800 border-slate-700 hover:border-blue-500/50 active:scale-[0.98]' : 'bg-slate-900/50 border-slate-800 opacity-60'}`}
                      >
                        <div className="flex justify-between items-start mb-1">
                          <div className="flex items-center gap-3">
                            <div className="p-2 rounded-lg bg-slate-950/50">
                              <${Cpu} className=${`w-4 h-4 ${canBuy ? 'text-blue-400' : 'text-slate-600'}`} />
                            </div>
                            <span className="font-bold text-slate-100 text-sm">${u.name}</span>
                          </div>
                          <span className="text-[10px] px-2 py-0.5 rounded-full bg-slate-950 text-blue-400 font-mono font-bold">LV.${u.level}</span>
                        </div>
                        <p className="text-xs text-slate-400 mb-4 line-clamp-2 leading-relaxed">${u.description}</p>
                        <div className="flex justify-between items-end">
                          <div className="flex flex-col">
                            <span className="text-[9px] text-slate-500 font-bold uppercase mb-0.5 tracking-tighter">Cost</span>
                            <div className="flex items-center gap-1.5 font-mono text-xs">
                              <span className=${canBuy ? 'text-green-400' : 'text-red-400'}>${formatNumber(purchase.cost)}</span>
                              <span className="text-slate-600">${res.symbol}</span>
                            </div>
                          </div>
                          <div className="text-right">
                            <span className="text-[9px] text-slate-500 font-bold uppercase mb-0.5 tracking-tighter">Output</span>
                            <div className="text-xs text-blue-300 font-mono font-bold">+${formatNumber(u.effect(u.level + purchase.count) - u.effect(u.level))}</div>
                          </div>
                        </div>
                      </button>
                    `;
                  })}
              </div>
            `}

            ${activeTab === 'achievements' && html`
              <div className="space-y-4 pb-8">
                 <div className="p-4 rounded-xl bg-gradient-to-br from-yellow-900/20 to-slate-900 border border-yellow-500/20">
                    <h3 className="text-xs font-black text-yellow-400 uppercase tracking-widest mb-1 flex items-center gap-2">
                       <${Trophy} className="w-4 h-4" /> Hall of Fame
                    </h3>
                    <p className="text-[10px] text-slate-400">Unlock milestones to gain unique rewards.</p>
                 </div>
                 <div className="grid gap-3">
                   ${ACHIEVEMENTS.map(ach => {
                     const unlocked = (gameState.unlockedAchievements || []).includes(ach.id);
                     return html`
                        <div key=${ach.id} className=${`p-4 rounded-2xl border transition-all ${unlocked ? 'bg-slate-800/80 border-green-500/30' : 'bg-slate-900/40 border-slate-800 grayscale opacity-70'}`}>
                           <div className="flex justify-between items-start mb-2">
                              <h4 className=${`text-xs font-bold uppercase ${unlocked ? 'text-white' : 'text-slate-500'}`}>${ach.name}</h4>
                              ${unlocked && html`<${CheckCircle} className="w-4 h-4 text-green-400" />`}
                           </div>
                           <p className="text-[11px] text-slate-400 mb-2">${ach.description}</p>
                           <div className="inline-block px-2 py-1 rounded bg-slate-950/50 text-[9px] font-mono text-yellow-500 border border-yellow-500/10">
                              REWARD: ${ach.reward}
                           </div>
                        </div>
                     `;
                   })}
                 </div>
              </div>
            `}

            ${activeTab === 'stats' && html`
              <div className="space-y-4 pb-8">
                
                <div className="p-4 bg-slate-950 rounded-2xl border border-slate-800 h-48 overflow-y-auto custom-scrollbar font-mono text-[10px]">
                   <div className="flex items-center gap-2 mb-2 text-slate-500 border-b border-slate-800 pb-1">
                      <${Terminal} className="w-3 h-3" /> SYSTEM LOG
                   </div>
                   <div className="flex flex-col gap-1">
                       ${(gameState.logs || []).map(log => html`
                          <div key=${log.id} className=${`animate-fade-in ${log.type === 'success' ? 'text-green-400' : log.type === 'warning' ? 'text-yellow-400' : 'text-slate-300'}`}>
                             <span className="text-slate-600 mr-2">[${new Date(log.id).toLocaleTimeString([], {hour12:false})}]</span>
                             ${log.text}
                          </div>
                       `)}
                       <div ref=${logsEndRef}></div>
                   </div>
                </div>

                <div className="p-5 rounded-2xl bg-slate-950/50 border border-slate-800">
                  <h3 className="text-xs font-black text-blue-400 uppercase tracking-widest mb-4 flex items-center gap-2 border-b border-slate-800 pb-2">
                    <${Award} className="w-4 h-4" /> Universe Metrics
                  </h3>
                  <div className="space-y-3">
                    <div className="flex justify-between items-center text-xs">
                      <span className="text-slate-500">Simulation Age</span>
                      <span className="font-mono text-blue-200">${Math.floor(gameState.playTime)}s</span>
                    </div>
                    <div className="flex justify-between items-center text-xs">
                      <span className="text-slate-500">Manual Clicks</span>
                      <span className="font-mono text-blue-200">${formatNumber(gameState.stats?.clicks || 0)}</span>
                    </div>
                    <div className="flex justify-between items-center text-xs">
                      <span className="text-slate-500">Comets Captured</span>
                      <span className="font-mono text-blue-200">${gameState.stats?.cometsClicked || 0}</span>
                    </div>
                  </div>
                </div>
              </div>
            `}

            ${activeTab === 'nexus' && html`
              <div className="space-y-4 pb-8">
                <div className="p-5 rounded-2xl bg-slate-950/50 border border-slate-800">
                  <h3 className="text-xs font-black text-slate-400 uppercase tracking-widest mb-4">Extended Systems</h3>
                  <button onClick=${() => setActiveModal('mod_browser')} className="w-full py-3 bg-purple-900/20 hover:bg-purple-900/30 text-purple-300 border border-purple-500/30 rounded-2xl text-xs font-bold flex items-center justify-center gap-3 transition-all mb-3">
                    <${Cloud} className="w-4 h-4" /> MOD BROWSER
                  </button>
                  <button onClick=${requestWipe} className="w-full py-3 bg-red-900/10 border border-red-900/20 text-red-500 rounded-2xl text-[10px] font-bold flex items-center justify-center gap-2 hover:bg-red-900/20 transition-all">
                    WIPE CORE MEMORY
                  </button>
                </div>

                <div className="p-5 rounded-2xl bg-slate-950/50 border border-slate-800">
                   <h3 className="text-xs font-black text-slate-400 uppercase tracking-widest mb-2">Cloud Sync</h3>
                   ${CloudService.isAvailable ? html`
                     <button onClick=${isCloudSignedIn ? handleCloudSave : handleCloudConnect} className="w-full py-3 bg-slate-800 text-white border border-slate-700 rounded-2xl text-xs font-bold">
                        ${isCloudSignedIn ? 'Save to Cloud' : 'Connect Account'}
                     </button>
                   ` : html`
                     <div className="text-[10px] text-slate-500 text-center">Mobile Only</div>
                   `}
                </div>
              </div>
            `}
          </div>
        </aside>
      </main>

      ${activeModal === 'mod_browser' && html`
        <div className="absolute inset-0 z-50 bg-slate-950/90 backdrop-blur-xl flex flex-col p-6 animate-fade-in overflow-y-auto custom-scrollbar">
          <div className="flex justify-between items-center mb-8 sticky top-0 bg-slate-950/80 p-4 rounded-2xl z-20">
            <h2 className="text-xl font-black text-white uppercase tracking-tighter flex items-center gap-4">
              <${Cloud} className="w-6 h-6 text-purple-500" /> MODIFICATIONS
            </h2>
            <button onClick=${() => setActiveModal(null)} className="p-3 hover:bg-slate-800 rounded-full text-slate-400 hover:text-white transition-all">
              <${X} className="w-6 h-6" />
            </button>
          </div>
          <div className="mb-4 text-center">
            <button onClick=${fetchMods} disabled=${isModBrowserLoading} className="px-6 py-2 bg-purple-600 rounded-full text-xs font-bold uppercase hover:bg-purple-500 transition-all">
              ${isModBrowserLoading ? 'Scanning...' : 'Refresh Feed'}
            </button>
          </div>
          <div className="grid gap-4 max-w-3xl mx-auto w-full">
            ${availableMods.map((mod) => html`
              <div key=${mod.id} className="p-4 rounded-xl bg-slate-900/50 border border-slate-800 flex justify-between items-center">
                 <div>
                   <h4 className="text-sm font-bold text-white">${mod.name}</h4>
                   <p className="text-xs text-slate-400">${mod.summary}</p>
                 </div>
                 <button className="px-4 py-2 bg-slate-800 rounded text-[10px] font-bold uppercase hover:bg-slate-700">Install</button>
              </div>
            `)}
          </div>
        </div>
      `}

      ${activeModal === 'galaxy_map' && html`
        <div className="absolute inset-0 z-50 bg-slate-950/90 backdrop-blur-xl flex flex-col p-6 animate-fade-in overflow-y-auto custom-scrollbar">
          <div className="flex justify-between items-center mb-8 sticky top-0 bg-slate-950/80 p-4 rounded-2xl z-20">
            <h2 className="text-2xl font-black text-white uppercase tracking-tighter flex items-center gap-4">
              <${Globe} className="w-8 h-8 text-blue-500" /> MULTIVERSE CONDUIT
            </h2>
            <button onClick=${() => setActiveModal(null)} className="p-3 hover:bg-slate-800 rounded-full text-slate-400 hover:text-white transition-all">
              <${X} className="w-8 h-8" />
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 max-w-6xl mx-auto w-full pb-20">
            ${WORLDS.map(world => {
              const isUnlocked = gameState.unlockedWorlds.includes(world.id);
              const isCurrent = gameState.currentWorld === world.id;
              const unlockReq = world.unlockReq;
              const canUnlock = !isUnlocked && gameState.resources[unlockReq.resource].amount >= unlockReq.amount;

              return html`
                <div 
                  key=${world.id} 
                  className=${`relative overflow-hidden rounded-3xl border transition-all p-6 flex flex-col justify-between h-64 ${isCurrent ? 'border-blue-500 bg-blue-900/20' : isUnlocked ? 'border-slate-800 bg-slate-900/50 hover:border-slate-600' : 'border-slate-900 bg-slate-950/50 opacity-60'}`}
                >
                  <div className="absolute inset-0 opacity-20 pointer-events-none" style=${{ background: world.bgGradient }}></div>
                  
                  <div className="relative z-10">
                    <div className="flex justify-between items-start mb-2">
                      <h4 className=${`text-xl font-black uppercase tracking-widest ${isCurrent ? 'text-blue-300' : 'text-white'}`}>${world.name}</h4>
                      ${isCurrent && html`<span className="text-[10px] bg-blue-500 text-white font-bold px-3 py-1 rounded-full uppercase">Active</span>`}
                    </div>
                    <p className="text-xs text-slate-400 mb-4 leading-relaxed line-clamp-2">${world.description}</p>
                    <div className="flex items-center gap-3 text-[10px] font-mono text-slate-500">
                      <span>Primary:</span>
                      <span className=${`text-${world.color}-400 font-bold uppercase`}>${gameState.resources[world.primaryResource].name}</span>
                    </div>
                  </div>

                  <div className="relative z-10">
                    ${isCurrent ? html`
                      <button disabled className="w-full py-3 rounded-xl bg-blue-600/20 text-blue-400 font-bold text-xs uppercase cursor-default">Current Location</button>
                    ` : isUnlocked ? html`
                      <button onClick=${() => switchWorld(world.id)} className="w-full py-3 rounded-xl bg-blue-600 hover:bg-blue-500 text-white font-bold text-xs uppercase transition-all shadow-xl shadow-blue-900/20">Initialize Warp Drive</button>
                    ` : html`
                      <button 
                        disabled=${!canUnlock}
                        className=${`w-full py-3 rounded-xl font-bold text-xs uppercase border transition-all ${canUnlock ? 'bg-green-600/10 border-green-500 text-green-400 hover:bg-green-600 hover:text-white' : 'border-slate-800 text-slate-600 cursor-not-allowed'}`}
                      >
                        ${canUnlock ? 'Establish Link' : `Requires ${formatNumber(unlockReq.amount)} ${gameState.resources[unlockReq.resource].name}`}
                      </button>
                    `}
                  </div>
                </div>
              `;
            })}
          </div>
        </div>
      `}

      ${activeModal === 'ascension' && html`
        <div className="absolute inset-0 z-50 bg-slate-950/95 backdrop-blur-xl flex flex-col items-center justify-center p-6 animate-fade-in">
             <div className="max-w-md w-full glass-panel p-8 rounded-3xl border border-purple-500/30 shadow-[0_0_50px_rgba(168,85,247,0.2)] text-center relative overflow-hidden">
                <div className="absolute top-0 left-0 w-full h-2 bg-gradient-to-r from-purple-500 to-blue-500"></div>
                <${Zap} className="w-16 h-16 text-purple-400 mx-auto mb-6 animate-pulse" />
                <h2 className="text-3xl font-black text-white uppercase tracking-tighter mb-2">Ascension Protocol</h2>
                <p className="text-sm text-slate-300 mb-6 leading-relaxed">
                   Reset your universe to gain permanent power.
                   <br/>
                   <span className="text-purple-400 font-bold">Current Bonus: +${(gameState.prestigeCount * 10).toFixed(0)}%</span>
                </p>
                
                <div className="bg-slate-900/50 p-6 rounded-2xl border border-purple-500/20 mb-8">
                   <div className="text-[10px] text-slate-500 font-bold uppercase tracking-widest mb-2">Potential Gain</div>
                   <div className="text-4xl font-black text-white font-mono flex items-center justify-center gap-2">
                      +${prestigePotential} <span className="text-sm text-purple-500">LEVELS</span>
                   </div>
                </div>

                <div className="flex flex-col gap-3">
                   <button 
                      onClick=${performPrestige}
                      disabled=${prestigePotential <= 0}
                      className=${`w-full py-4 rounded-xl font-bold uppercase tracking-widest text-sm transition-all ${prestigePotential > 0 ? 'bg-purple-600 hover:bg-purple-500 text-white shadow-lg shadow-purple-900/40' : 'bg-slate-800 text-slate-500 cursor-not-allowed'}`}
                   >
                      ${prestigePotential > 0 ? 'Initiate Rebirth' : 'More Energy Required'}
                   </button>
                   <button onClick=${() => setActiveModal(null)} className="text-xs text-slate-500 hover:text-white uppercase tracking-widest py-2">
                      Cancel Sequence
                   </button>
                </div>
             </div>
        </div>
      `}
    </div>
  `;
};

export default App;