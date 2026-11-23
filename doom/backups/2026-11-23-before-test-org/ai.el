;;; doom/ai.el -*- lexical-binding: t; -*-

(after! gptel
  (setq gptel-backend
        (gptel-make-ollama "Ollama"
          :host "localhost:11434"
          :stream t
          :models '(llama3.2:3b))
        gptel-model 'llama3.2:3b))

(provide 'ai)
