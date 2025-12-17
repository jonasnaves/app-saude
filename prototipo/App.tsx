
import React, { useState, useEffect } from 'react';
import { Layout } from './components/Layout';
import { Dashboard } from './components/Dashboard';
import { ClinicalHub } from './components/ClinicalHub';
import { SupportHub } from './components/SupportHub';
import { BusinessHub } from './components/BusinessHub';
import { FloatingAction } from './components/FloatingAction';
import { AppPillar } from './types';

const App: React.FC = () => {
  const [activePillar, setActivePillar] = useState<AppPillar>(AppPillar.DASHBOARD);
  const [isRecording, setIsRecording] = useState(false);

  const toggleRecording = () => {
    if (!isRecording) {
      setActivePillar(AppPillar.CLINICAL);
      setIsRecording(true);
    } else {
      setIsRecording(false);
    }
  };

  const renderActivePillar = () => {
    switch (activePillar) {
      case AppPillar.DASHBOARD:
        return <Dashboard />;
      case AppPillar.CLINICAL:
        return <ClinicalHub isRecording={isRecording} onStop={() => setIsRecording(false)} />;
      case AppPillar.SUPPORT:
        return <SupportHub />;
      case AppPillar.BUSINESS:
        return <BusinessHub />;
      default:
        return <Dashboard />;
    }
  };

  return (
    <div className="min-h-screen bg-[#0B1120] text-slate-100 flex flex-col">
      <main className="flex-1 container mx-auto max-w-5xl px-4 pt-6 pb-32">
        {renderActivePillar()}
      </main>

      <FloatingAction onClick={toggleRecording} isRecording={isRecording} />

      <nav className="fixed bottom-0 left-0 right-0 bg-[#0B1120]/80 backdrop-blur-xl border-t border-slate-800 z-40 px-6 py-4">
        <div className="max-w-md mx-auto flex justify-between items-center">
          <NavItem 
            active={activePillar === AppPillar.DASHBOARD} 
            onClick={() => setActivePillar(AppPillar.DASHBOARD)}
            label="Início"
            icon={<HomeIcon />}
          />
          <NavItem 
            active={activePillar === AppPillar.CLINICAL} 
            onClick={() => setActivePillar(AppPillar.CLINICAL)}
            label="Clínico"
            icon={<StethoscopeIcon />}
          />
          <div className="w-16" /> {/* Space for FAB */}
          <NavItem 
            active={activePillar === AppPillar.SUPPORT} 
            onClick={() => setActivePillar(AppPillar.SUPPORT)}
            label="Suporte"
            icon={<SupportIcon />}
          />
          <NavItem 
            active={activePillar === AppPillar.BUSINESS} 
            onClick={() => setActivePillar(AppPillar.BUSINESS)}
            label="Business"
            icon={<BusinessIcon />}
          />
        </div>
      </nav>
    </div>
  );
};

const NavItem: React.FC<{ active: boolean; onClick: () => void; label: string; icon: React.ReactNode }> = ({ active, onClick, label, icon }) => (
  <button onClick={onClick} className={`flex flex-col items-center gap-1 transition-all ${active ? 'text-blue-500 scale-110' : 'text-slate-500'}`}>
    {icon}
    <span className="text-[10px] font-bold uppercase tracking-tighter">{label}</span>
  </button>
);

const HomeIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
);
const StethoscopeIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4.8 2.3A.3.3 0 1 0 5 2a.3.3 0 0 0-.2.3Z"/><path d="M10 22v-2a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v2"/><path d="M5 8V5a3 3 0 0 1 3-3h7a3 3 0 0 1 3 3v3"/><path d="M2 12h20"/><path d="M7 21a2 2 0 1 1-4 0 2 2 0 0 1 4 0Z"/><path d="M21 21a2 2 0 1 1-4 0 2 2 0 0 1 4 0Z"/><path d="M12 12v10"/></svg>
);
const SupportIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 8V4H8"/><rect width="16" height="12" x="4" y="8" rx="2"/><path d="M2 14h2"/><path d="M20 14h2"/><path d="M15 13v2"/><path d="M9 13v2"/></svg>
);
const BusinessIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="20" height="14" x="2" y="5" rx="2"/><line x1="2" x2="22" y1="10" y2="10"/></svg>
);

export default App;
