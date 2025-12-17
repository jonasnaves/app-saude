
import React from 'react';
import { Mic } from 'lucide-react';

interface Props {
  onClick: () => void;
  isRecording: boolean;
}

export const FloatingAction: React.FC<Props> = ({ onClick, isRecording }) => {
  return (
    <button
      onClick={onClick}
      className={`fixed bottom-24 right-6 w-16 h-16 rounded-full flex items-center justify-center shadow-2xl transition-all active:scale-95 z-50 ${
        isRecording 
          ? 'bg-red-500 animate-pulse' 
          : 'bg-blue-600 hover:bg-blue-500'
      }`}
    >
      <Mic className="text-white w-8 h-8" />
      {isRecording && (
        <div className="absolute -top-12 right-0 bg-white text-gray-900 px-3 py-1 rounded-full text-xs font-bold shadow-md">
          REC
        </div>
      )}
    </button>
  );
};
