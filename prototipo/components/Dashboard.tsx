
import React from 'react';
import { Users, FileText, TrendingUp, Calendar } from 'lucide-react';
import { MOCK_PATIENTS } from '../constants';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

const data = [
  { name: 'Seg', total: 12 },
  { name: 'Ter', total: 19 },
  { name: 'Qua', total: 15 },
  { name: 'Qui', total: 22 },
  { name: 'Sex', total: 10 },
];

export const Dashboard: React.FC = () => {
  return (
    <div className="space-y-6 pb-12 animate-in fade-in duration-500">
      <header className="flex justify-between items-center mb-4">
        <div>
          <h1 className="text-2xl font-bold text-white">Olá, Dr. Carvalho</h1>
          <p className="text-slate-400 text-sm">Resumo do seu dia: 14 de Maio</p>
        </div>
        <div className="w-10 h-10 rounded-full bg-blue-900 border border-blue-400 flex items-center justify-center">
          <span className="text-xs font-bold">DC</span>
        </div>
      </header>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Pacientes Hoje', val: '18', icon: Users, color: 'text-blue-400' },
          { label: 'Pendências', val: '3', icon: FileText, color: 'text-yellow-400' },
          { label: 'Ganhos Estim.', val: 'R$ 4.2k', icon: TrendingUp, color: 'text-emerald-400' },
          { label: 'Plantões', val: '1', icon: Calendar, color: 'text-purple-400' },
        ].map((item, idx) => (
          <div key={idx} className="bg-slate-800/50 border border-slate-700 p-4 rounded-xl">
            <div className="flex justify-between items-start">
              <span className="text-slate-400 text-sm">{item.label}</span>
              <item.icon className={`${item.color} w-5 h-5`} />
            </div>
            <p className="text-2xl font-bold mt-2">{item.val}</p>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 bg-slate-800/50 border border-slate-700 p-6 rounded-2xl">
          <h2 className="text-lg font-semibold mb-6 flex items-center gap-2">
            <TrendingUp className="text-emerald-400 w-5 h-5" /> Volume de Atendimento
          </h2>
          <div className="h-[250px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={data}>
                <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                <XAxis dataKey="name" stroke="#94A3B8" />
                <YAxis stroke="#94A3B8" />
                <Tooltip 
                  contentStyle={{ backgroundColor: '#1E293B', border: 'none', borderRadius: '8px' }}
                  itemStyle={{ color: '#34D399' }}
                />
                <Bar dataKey="total" fill="#3B82F6" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="bg-slate-800/50 border border-slate-700 p-6 rounded-2xl">
          <h2 className="text-lg font-semibold mb-6 flex items-center gap-2">
            <Users className="text-blue-400 w-5 h-5" /> Próximos Pacientes
          </h2>
          <div className="space-y-4">
            {MOCK_PATIENTS.map((p) => (
              <div key={p.id} className="flex items-center justify-between p-3 bg-slate-900/50 rounded-lg hover:bg-slate-700/50 transition-colors cursor-pointer">
                <div>
                  <p className="font-medium">{p.name}</p>
                  <p className="text-xs text-slate-400">Última: {p.lastVisit}</p>
                </div>
                <div className="bg-blue-600 px-2 py-1 rounded text-xs font-bold">
                  {p.nextAppointment}
                </div>
              </div>
            ))}
          </div>
          <button className="w-full mt-6 py-2 text-sm text-blue-400 font-medium hover:text-blue-300">
            Ver agenda completa
          </button>
        </div>
      </div>
    </div>
  );
};
