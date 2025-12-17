
import React, { useState } from 'react';
import { BrainCircuit, Gavel, Megaphone, Send, Loader2, Bot } from 'lucide-react';
import { getSupportResponse } from '../services/geminiService';

export const SupportHub: React.FC = () => {
  const [mode, setMode] = useState<'medical' | 'legal' | 'marketing'>('medical');
  const [query, setQuery] = useState('');
  const [chat, setChat] = useState<{ role: 'user' | 'bot'; text: string }[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  const handleSend = async () => {
    if (!query.trim()) return;
    const userMsg = query;
    setQuery('');
    setChat(prev => [...prev, { role: 'user', text: userMsg }]);
    setIsLoading(true);

    try {
      const response = await getSupportResponse(userMsg, mode);
      setChat(prev => [...prev, { role: 'bot', text: response }]);
    } catch (e) {
      setChat(prev => [...prev, { role: 'bot', text: "Desculpe, tive um problema ao processar sua dúvida." }]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="h-full flex flex-col space-y-4 pb-12 animate-in fade-in duration-500">
      <header className="flex flex-col gap-2">
        <h1 className="text-2xl font-bold">Hub de Especialistas IA</h1>
        <div className="flex gap-2 p-1 bg-slate-800 rounded-xl w-fit">
          <button 
            onClick={() => setMode('medical')}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all ${mode === 'medical' ? 'bg-blue-600 text-white shadow-lg' : 'text-slate-400 hover:text-white'}`}
          >
            <BrainCircuit size={16} /> IA Médica
          </button>
          <button 
            onClick={() => setMode('legal')}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all ${mode === 'legal' ? 'bg-emerald-600 text-white shadow-lg' : 'text-slate-400 hover:text-white'}`}
          >
            <Gavel size={16} /> IA Jurídica
          </button>
          <button 
            onClick={() => setMode('marketing')}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all ${mode === 'marketing' ? 'bg-purple-600 text-white shadow-lg' : 'text-slate-400 hover:text-white'}`}
          >
            <Megaphone size={16} /> IA Marketing
          </button>
        </div>
      </header>

      <div className="flex-1 bg-slate-800/30 border border-slate-700 rounded-2xl overflow-hidden flex flex-col min-h-[400px]">
        <div className="flex-1 p-4 overflow-y-auto space-y-4 custom-scrollbar">
          {chat.length === 0 && (
            <div className="h-full flex flex-col items-center justify-center text-center p-8">
              <Bot size={48} className="text-slate-600 mb-4" />
              <p className="text-slate-400">
                Selecione o especialista acima e tire suas dúvidas. <br/>
                {mode === 'medical' && "Consulte guidelines, medicamentos e estudos recentes."}
                {mode === 'legal' && "Pergunte sobre LGPD, termos de consentimento e defesa médica."}
                {mode === 'marketing' && "Gere posts, roteiros e estratégias de posicionamento."}
              </p>
            </div>
          )}
          {chat.map((msg, i) => (
            <div key={i} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
              <div className={`max-w-[80%] p-3 rounded-2xl ${msg.role === 'user' ? 'bg-blue-600 text-white' : 'bg-slate-700 text-slate-200'}`}>
                <p className="text-sm leading-relaxed whitespace-pre-wrap">{msg.text}</p>
              </div>
            </div>
          ))}
          {isLoading && (
            <div className="flex justify-start">
              <div className="bg-slate-700 p-3 rounded-2xl flex gap-2 items-center">
                <div className="w-1.5 h-1.5 bg-slate-400 rounded-full animate-bounce" />
                <div className="w-1.5 h-1.5 bg-slate-400 rounded-full animate-bounce [animation-delay:0.2s]" />
                <div className="w-1.5 h-1.5 bg-slate-400 rounded-full animate-bounce [animation-delay:0.4s]" />
              </div>
            </div>
          )}
        </div>

        <div className="p-4 bg-slate-900/50 border-t border-slate-700">
          <div className="relative">
            <input 
              type="text" 
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleSend()}
              placeholder={`Pergunte para a IA ${mode === 'medical' ? 'Médica' : mode === 'legal' ? 'Jurídica' : 'de Marketing'}...`}
              className="w-full bg-slate-800 border border-slate-700 rounded-xl py-3 pl-4 pr-12 text-sm focus:outline-none focus:border-blue-500 transition-colors"
            />
            <button 
              onClick={handleSend}
              disabled={isLoading}
              className="absolute right-2 top-1.5 p-2 text-blue-400 hover:text-blue-300 disabled:opacity-50 transition-colors"
            >
              <Send size={20} />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
