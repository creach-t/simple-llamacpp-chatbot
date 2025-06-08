#!/bin/bash

# Script de correction pour Windows
echo "🔧 Correction pour Windows..."

# Vérifier si on est sur Windows
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    echo "✅ Détection de Windows"
    
    # Créer le dossier llama.cpp s'il n'existe pas
    mkdir -p llama.cpp
    
    echo "📥 Téléchargement des binaires llama.cpp pour Windows..."
    
    # URL des releases GitHub
    RELEASE_URL="https://api.github.com/repos/ggerganov/llama.cpp/releases/latest"
    
    # Obtenir l'URL de téléchargement du binaire Windows
    DOWNLOAD_URL=$(curl -s "$RELEASE_URL" | grep "browser_download_url.*win.*x64.*zip" | cut -d '"' -f 4 | head -n 1)
    
    if [ -n "$DOWNLOAD_URL" ]; then
        echo "📦 Téléchargement depuis: $DOWNLOAD_URL"
        
        # Télécharger
        curl -L -o llama-cpp-windows.zip "$DOWNLOAD_URL"
        
        # Extraire dans le dossier llama.cpp
        if command -v unzip &> /dev/null; then
            unzip -o llama-cpp-windows.zip -d llama.cpp
        elif command -v 7z &> /dev/null; then
            7z x llama-cpp-windows.zip -ollama.cpp -y
        else
            echo "⚠️  Extraction manuelle requise"
            echo "Veuillez extraire llama-cpp-windows.zip dans le dossier llama.cpp/"
            exit 1
        fi
        
        # Nettoyer
        rm -f llama-cpp-windows.zip
        
        # Chercher l'exécutable
        LLAMACLI_PATH=$(find llama.cpp -name "llama-cli.exe" -o -name "main.exe" -o -name "llama.exe" | head -n 1)
        
        if [ -n "$LLAMACLI_PATH" ]; then
            echo "✅ Exécutable trouvé: $LLAMACLI_PATH"
            
            # Mettre à jour la configuration
            FULL_PATH=$(realpath "$LLAMACLI_PATH")
            
            # Créer un nouveau config.json avec le bon chemin
            cat > config.json << EOF
{
  "port": 3000,
  "llamaCppPath": "$FULL_PATH",
  "modelPath": "./models/croissant.gguf",
  "maxTokens": 100,
  "temperature": 0.7,
  "chatbot": {
    "title": "Assistant CroissantLLM",
    "placeholder": "Tapez votre message en français...",
    "primaryColor": "#4A90E2",
    "secondaryColor": "#F5F5F5",
    "textColor": "#333333",
    "maxMessages": 50,
    "typingDelay": 100
  },
  "llamaArgs": {
    "ctx_size": 2048,
    "threads": 4,
    "batch_size": 512
  }
}
EOF
            
            echo "✅ Configuration mise à jour"
            echo "🚀 Vous pouvez maintenant démarrer le serveur avec: npm start"
            
        else
            echo "❌ Aucun exécutable trouvé dans l'archive"
            exit 1
        fi
        
    else
        echo "❌ Impossible de trouver l'URL de téléchargement"
        exit 1
    fi
    
else
    echo "❌ Ce script est destiné à Windows"
    exit 1
fi

# Télécharger le modèle s'il n'existe pas
if [ ! -f "models/croissant.gguf" ]; then
    echo "📥 Téléchargement du modèle CroissantLLM..."
    mkdir -p models
    
    MODEL_URL="https://huggingface.co/croissantllm/CroissantLLMChat-v0.1-GGUF/resolve/main/croissant-llm-chat-v0.1.Q4_K_M.gguf"
    
    if command -v wget &> /dev/null; then
        wget -O "models/croissant.gguf" "$MODEL_URL"
    elif command -v curl &> /dev/null; then
        curl -L -o "models/croissant.gguf" "$MODEL_URL"
    else
        echo "⚠️  Veuillez télécharger manuellement le modèle depuis:"
        echo "$MODEL_URL"
        echo "Et le placer dans: models/croissant.gguf"
    fi
fi

echo "🎉 Configuration terminée !"
