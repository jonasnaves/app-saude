
import React, { useState } from 'react';
import { Package, Search, ShoppingCart, CreditCard, Gift, ArrowUpRight } from 'lucide-react';
import { MOCK_DRUGS } from '../constants';

export const BusinessHub: React.FC = () => {
  const [searchTerm, setSearchTerm] = useState('');

  const filteredDrugs = MOCK_DRUGS.filter(d => 
    d.name.toLowerCase().includes(searchTerm.toLowerCase()) || 
    d.category.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="space-y-6 pb-20 animate-in fade-in duration-500">
      <header>
        <h1 className="text-2xl font-bold flex items-center gap-2">
          <Package className="text-purple-400" /> Ecossistema de Negócios
        </h1>
      </header>

      <div className="bg-gradient-to-br from-indigo-900/40 to-blue-900/40 border border-indigo-500/30 p-6 rounded-2xl shadow-xl relative overflow-hidden group">
        <div className="absolute -top-10 -right-10 w-40 h-40 bg-indigo-500/10 rounded-full blur-3xl group-hover:scale-110 transition-transform" />
        <div className="flex justify-between items-start mb-6">
          <div>
            <p className="text-indigo-300 text-sm font-medium uppercase tracking-wider">Créditos de Plataforma</p>
            <h2 className="text-4xl font-bold mt-1">R$ 1.240,00</h2>
          </div>
          <div className="bg-indigo-600/50 p-3 rounded-xl">
            <CreditCard className="text-indigo-200" />
          </div>
        </div>
        <div className="flex gap-4">
          <button className="flex-1 bg-white text-indigo-900 py-3 rounded-xl font-bold text-sm flex items-center justify-center gap-2 hover:bg-slate-100 transition-all">
            <ArrowUpRight size={18} /> Resgatar p/ Marketing
          </button>
          <button className="flex-1 bg-indigo-600/40 border border-indigo-400/30 py-3 rounded-xl font-bold text-sm flex items-center justify-center gap-2 hover:bg-indigo-600/60 transition-all">
            <Gift size={18} /> Ver Benefícios
          </button>
        </div>
      </div>

      <div className="space-y-4">
        <div className="flex justify-between items-center">
          <h2 className="text-lg font-semibold">Catálogo e Checkout Médico</h2>
          <span className="text-slate-400 text-xs">{filteredDrugs.length} resultados</span>
        </div>
        
        <div className="relative">
          <Search className="absolute left-3 top-3 text-slate-500" size={18} />
          <input 
            type="text" 
            placeholder="Buscar princípio ativo ou marca..." 
            className="w-full bg-slate-800 border border-slate-700 rounded-xl py-3 pl-10 pr-4 text-sm focus:outline-none focus:border-purple-500 transition-colors"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {filteredDrugs.map((drug, i) => (
            <div key={i} className="bg-slate-800/40 border border-slate-700 p-4 rounded-xl flex justify-between items-center hover:bg-slate-700/40 transition-all">
              <div>
                <h3 className="font-bold text-white">{drug.name}</h3>
                <p className="text-slate-400 text-xs">{drug.category} • {drug.dosage}</p>
              </div>
              <button className="bg-blue-600/20 text-blue-400 p-2 rounded-lg hover:bg-blue-600 hover:text-white transition-all">
                <ShoppingCart size={18} />
              </button>
            </div>
          ))}
        </div>
      </div>

      <div className="bg-slate-800/20 border border-slate-700 border-dashed p-6 rounded-2xl text-center">
        <p className="text-slate-500 text-xs italic">
          "A indicação de medicamentos via link de conveniência foca na adesão ao tratamento pelo paciente, respeitando as diretrizes éticas do CFM."
        </p>
      </div>
    </div>
  );
};
