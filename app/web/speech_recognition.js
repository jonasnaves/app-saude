// Wrapper para Web Speech API que simplifica o uso no Flutter
class SpeechRecognitionWrapper {
  constructor() {
    this.recognition = null;
    this.onResultCallback = null;
    this.isSupported = false;
    
    if (window.SpeechRecognition || window.webkitSpeechRecognition) {
      const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
      this.recognition = new SpeechRecognition();
      this.recognition.continuous = true;
      this.recognition.interimResults = true;
      this.recognition.lang = 'pt-BR';
      this.isSupported = true;
      
      this.recognition.onresult = (event) => {
        let finalTranscript = '';
        let interimTranscript = '';
        
        for (let i = event.resultIndex; i < event.results.length; i++) {
          const transcript = event.results[i][0].transcript;
          if (event.results[i].isFinal) {
            finalTranscript += transcript;
          } else {
            interimTranscript += transcript;
          }
        }
        
        if (this.onResultCallback) {
          this.onResultCallback({
            final: finalTranscript,
            interim: interimTranscript
          });
        }
      };
      
      this.recognition.onerror = (event) => {
        console.error('Speech recognition error:', event.error);
      };
    }
  }
  
  setOnResult(callback) {
    this.onResultCallback = callback;
  }
  
  start() {
    if (this.isSupported && this.recognition) {
      try {
        this.recognition.start();
      } catch (e) {
        // Ignorar erro se já estiver rodando
        console.warn('Speech recognition start error:', e);
      }
    }
  }
  
  stop() {
    if (this.recognition) {
      this.recognition.stop();
    }
  }
}

// Tornar disponível globalmente
window.SpeechRecognitionWrapper = SpeechRecognitionWrapper;


