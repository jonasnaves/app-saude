
import React, { useState, useEffect, useRef } from 'react';
import { Mic, CheckCircle, FileText, Stethoscope, Share2, Loader2, Info, Activity, Brain, CircleHelp, ChevronRight } from 'lucide-react';
import { getClinicalSummary, getIncrementalAnalysis, createAudioBlob } from '../services/geminiService';
import { TranscriptionSummary } from '../types';
import { GoogleGenAI, Modality } from '@google/genai';

export const ClinicalHub: React.FC<{ isRecording: boolean; onStop: () => void }> = ({ isRecording, onStop }) => {
  const [transcript, setTranscript] = useState<string>("");
  const [liveInsights, setLiveInsights] = useState<string>("Inicie a conversa para gerar insights automáticos...");
  const [liveQuestions, setLiveQuestions] = useState<string[]>([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const [isAnalysisUpdating, setIsAnalysisUpdating] = useState(false);
  const [summary, setSummary] = useState<TranscriptionSummary | null>(null);
  const [activeTab, setActiveTab] = useState<'recording' | 'review'>('recording');
  
  const transcriptRef = useRef("");
  const insightsRef = useRef("");
  const audioContextRef = useRef<AudioContext | null>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const processorRef = useRef<ScriptProcessorNode | null>(null);
  const lastAnalysisLengthRef = useRef(0);
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [transcript]);

  useEffect(() => {
    if (isRecording) {
      startLiveSession();
    } else {
      stopLiveSession();
    }
    return () => stopLiveSession();
  }, [isRecording]);

  const startLiveSession = async () => {
    try {
      setActiveTab('recording');
      setSummary(null);
      setTranscript("");
      setLiveQuestions([]);
      transcriptRef.current = "";
      insightsRef.current = "";
      setLiveInsights("IA conectada. Ouvindo atendimento...");

      const ai = new GoogleGenAI({ apiKey: process.env.API_KEY });
      audioContextRef.current = new (window.AudioContext || (window as any).webkitAudioContext)({ sampleRate: 16000 });
      streamRef.current = await navigator.mediaDevices.getUserMedia({ audio: true });
      
      const sessionPromise = ai.live.connect({
        model: 'gemini-2.5-flash-native-audio-preview-09-2025',
        config: {
          responseModalities: [Modality.AUDIO],
          inputAudioTranscription: {},
          systemInstruction: "Você é um escriba médico discreto. Transcreva cada palavra da consulta fielmente. Não responda por voz. Sua única função é fornecer a transcrição textual exata do que o médico e o paciente dizem.",
        },
        callbacks: {
          onopen: () => {
            const source = audioContextRef.current!.createMediaStreamSource(streamRef.current!);
            processorRef.current = audioContextRef.current!.createScriptProcessor(4096, 1, 1);
            
            processorRef.current.onaudioprocess = (e) => {
              const inputData = e.inputBuffer.getChannelData(0);
              const pcmBlob = createAudioBlob(inputData);
              sessionPromise.then(session => {
                session.sendRealtimeInput({ media: pcmBlob });
              });
            };

            source.connect(processorRef.current);
            processorRef.current.connect(audioContextRef.current!.destination);
          },
          onmessage: async (message) => {
            if (message.serverContent?.inputTranscription) {
              const text = message.serverContent.inputTranscription.text;
              if (text.trim()) {
                const updated = transcriptRef.current + " " + text;
                transcriptRef.current = updated;
                setTranscript(updated);

                if (updated.length - lastAnalysisLengthRef.current > 200) {
                  updateIncrementalAnalysis(updated);
                  lastAnalysisLengthRef.current = updated.length;
                }
              }
            }
          },
          onerror: (e) => {
            console.error("Live session error", e);
            setLiveInsights("Erro de conexão. Tente novamente.");
          },
          onclose: () => console.log("Live session closed"),
        }
      });

    } catch (err) {
      console.error("Failed to start live session", err);
      setLiveInsights("Erro ao acessar microfone. Verifique as permissões.");
      onStop();
    }
  };

  const stopLiveSession = () => {
    if (processorRef.current) {
      processorRef.current.disconnect();
      processorRef.current = null;
    }
    if (streamRef.current) {
      streamRef.current.getTracks().forEach(track => track.stop());
      streamRef.current = null;
    }
    if (audioContextRef.current) {
      audioContextRef.current.close();
      audioContextRef.current = null;
    }
  };

  const updateIncrementalAnalysis = async (text: string) => {
    if (isAnalysisUpdating) return;
    setIsAnalysisUpdating(true);
    try {
      const analysis = await getIncrementalAnalysis(text, insightsRef.current);
      insightsRef.current = analysis.insights || insightsRef.current;
      setLiveInsights(insightsRef.current);
      setLiveQuestions(analysis.suggestedQuestions || []);
    } catch (e) {
      console.warn("Failed incremental analysis", e);
    } finally {
      setIsAnalysisUpdating(false);
    }
  };

  const handleFinish = async () => {
    onStop();
    setIsProcessing(true);
    setActiveTab('review');
    try {
      const res = await getClinicalSummary(transcriptRef.current || "Consulta rápida.");
      setSummary(res);
    } catch (e) {
      console.error(e);
      setSummary({
        anamnesis: "Análise falhou, dados brutos mantidos.",
        physicalExam: "Revisar manualmente.",
        diagnosisSuggestions: ["Revisão necessária"],
        conduct: "Não gerada."
      });
    } finally {
      setIsProcessing(false);
    }
  };

  return (
    <div className="space-y-6 pb-20 animate-in slide-in-from-bottom-4 duration-500 max-w-5xl mx-auto">
      <header className="flex justify-between items-center">
        <h1 className="text-2xl font-bold flex items-center gap-2">
          <Stethoscope className="text-emerald-400" /> Atendimento Inteligente
        </h1>
        {isRecording && (
          <div className="flex items-center gap-2 px-3 py-1 bg-red-500/20 border border-red-500/40 rounded-full">
            <div className="w-2 h-2 bg-red-500 rounded-full animate-ping" />
            <span className="text-[10px] font-bold text-red-500 uppercase tracking-widest">Gravando</span>
          </div>
        )}
      </header>

      {activeTab === 'recording' && (
        <div className="flex flex-col gap-6">
          {/* Section 1: Fluid Transcription */}
          <div className="bg-slate-800/40 border border-slate-700 p-6 rounded-2xl flex flex-col h-[300px]">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-sm font-semibold text-slate-400 uppercase tracking-wider flex items-center gap-2">
                <FileText className="w-4 h-4" /> Transcrição em Tempo Real
              </h2>
              <Activity className={`w-4 h-4 ${isRecording ? 'text-emerald-400 animate-pulse' : 'text-slate-600'}`} />
            </div>
            
            <div 
              ref={scrollRef}
              className="flex-1 bg-slate-900/60 p-5 rounded-xl border border-slate-700/50 overflow-y-auto custom-scrollbar"
            >
              {transcript ? (
                <p className="text-slate-200 leading-relaxed text-base font-medium">
                  {transcript}
                  <span className="inline-block w-1.5 h-4 bg-emerald-400 ml-1 animate-pulse" />
                </p>
              ) : (
                <div className="h-full flex flex-col items-center justify-center text-center opacity-30">
                  <Mic size={40} className="mb-3" />
                  <p className="text-sm italic">Capturando áudio...</p>
                </div>
              )}
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Section 2: Progressive Clinical Insights */}
            <div className="bg-slate-800/60 border border-blue-500/30 p-6 rounded-2xl shadow-2xl relative flex flex-col min-h-[250px]">
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-blue-400 font-bold flex items-center gap-2 text-sm uppercase tracking-widest">
                  <Brain size={18} /> Insights Clínicos
                </h2>
                {isAnalysisUpdating && <Loader2 className="w-4 h-4 text-blue-400 animate-spin" />}
              </div>
              <div className="flex-1 text-slate-200 text-sm leading-relaxed whitespace-pre-wrap bg-slate-900/40 p-4 rounded-xl border border-slate-700/30 overflow-y-auto custom-scrollbar">
                {liveInsights}
              </div>
            </div>

            {/* Section 3: Suggested Questions */}
            <div className="bg-slate-800/60 border border-purple-500/30 p-6 rounded-2xl shadow-2xl relative flex flex-col min-h-[250px]">
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-purple-400 font-bold flex items-center gap-2 text-sm uppercase tracking-widest">
                  <CircleHelp size={18} /> Perguntas Sugeridas
                </h2>
              </div>
              <div className="flex-1 space-y-3 bg-slate-900/40 p-4 rounded-xl border border-slate-700/30 overflow-y-auto custom-scrollbar">
                {liveQuestions.length > 0 ? (
                  liveQuestions.map((q, idx) => (
                    <div key={idx} className="group flex items-start gap-3 p-3 bg-purple-500/5 hover:bg-purple-500/10 border border-purple-500/10 rounded-lg transition-all cursor-pointer">
                      <ChevronRight size={16} className="text-purple-400 mt-0.5 group-hover:translate-x-1 transition-transform" />
                      <p className="text-slate-300 text-sm font-medium">{q}</p>
                    </div>
                  ))
                ) : (
                  <div className="h-full flex items-center justify-center text-slate-500 text-xs italic text-center p-4">
                    A IA sugerirá perguntas conforme a consulta avança para garantir anamnese completa.
                  </div>
                )}
              </div>
            </div>
          </div>

          {isRecording && (
            <button 
              onClick={handleFinish}
              className="bg-emerald-600 hover:bg-emerald-500 text-white py-4 rounded-2xl font-bold transition-all shadow-xl shadow-emerald-900/20 active:scale-95 flex items-center justify-center gap-2"
            >
              <CheckCircle size={20} /> Finalizar Atendimento
            </button>
          )}
        </div>
      )}

      {activeTab === 'review' && (
        <div className="space-y-6 animate-in fade-in duration-700">
          {isProcessing ? (
            <div className="flex flex-col items-center justify-center py-24 bg-slate-800/50 rounded-2xl border border-slate-700">
              <div className="relative mb-6">
                <Loader2 className="w-16 h-16 text-blue-500 animate-spin" />
                <Brain className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-white w-6 h-6" />
              </div>
              <p className="text-xl font-bold text-white">Gerando Prontuário Final</p>
              <p className="text-slate-400 text-sm mt-2">Convertendo dados brutos em resumo estruturado...</p>
            </div>
          ) : summary && (
            <div className="grid grid-cols-1 gap-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="bg-slate-800/50 border border-slate-700 p-6 rounded-2xl shadow-lg border-l-4 border-l-emerald-500">
                  <h3 className="text-emerald-400 font-bold flex items-center gap-2 mb-4">
                    <FileText size={18} /> Anamnese Detalhada
                  </h3>
                  <p className="text-slate-300 leading-relaxed text-sm">
                    {summary.anamnesis}
                  </p>
                </div>
                <div className="bg-slate-800/50 border border-slate-700 p-6 rounded-2xl shadow-lg border-l-4 border-l-blue-500">
                  <h3 className="text-blue-400 font-bold flex items-center gap-2 mb-4">
                    <CheckCircle size={18} /> Exame Físico Observado
                  </h3>
                  <p className="text-slate-300 leading-relaxed text-sm">
                    {summary.physicalExam}
                  </p>
                </div>
              </div>

              <div className="bg-slate-800/50 border border-slate-700 p-6 rounded-2xl shadow-lg">
                <h3 className="text-yellow-400 font-bold mb-4 flex items-center gap-2">
                  <Info size={18} /> Hipóteses Diagnósticas
                </h3>
                <div className="flex flex-wrap gap-3">
                  {summary.diagnosisSuggestions.map((diag, i) => (
                    <span key={i} className="bg-yellow-400/10 text-yellow-400 border border-yellow-400/30 px-4 py-2 rounded-xl text-xs font-bold uppercase">
                      {diag}
                    </span>
                  ))}
                </div>
              </div>

              <div className="bg-slate-800/50 border border-slate-700 p-6 rounded-2xl shadow-lg border-t-4 border-t-emerald-500">
                <h3 className="text-emerald-400 font-bold mb-4">Conduta Sugerida</h3>
                <p className="text-slate-300 text-sm mb-8 bg-slate-900/50 p-4 rounded-xl leading-relaxed italic border border-slate-700/50">
                  {summary.conduct}
                </p>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <button className="bg-blue-600 hover:bg-blue-500 py-4 rounded-xl font-bold flex items-center justify-center gap-2 transition-all shadow-lg active:scale-95">
                    <Share2 size={18} /> Compartilhar com Paciente
                  </button>
                  <button className="bg-emerald-600 hover:bg-emerald-500 py-4 rounded-xl font-bold flex items-center justify-center gap-2 transition-all shadow-lg active:scale-95">
                    <CheckCircle size={18} /> Integrar ao Prontuário
                  </button>
                </div>
              </div>
              
              <button 
                onClick={() => { setActiveTab('recording'); setTranscript(""); transcriptRef.current = ""; setLiveQuestions([]); }}
                className="text-slate-500 hover:text-slate-300 text-sm font-medium transition-colors py-4 text-center"
              >
                Nova Consulta
              </button>
            </div>
          )}
        </div>
      )}
    </div>
  );
};
