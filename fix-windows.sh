#!/bin/bash

# Script de correction pour Windows avec URLs spécifiques
echo "🔧 Correction pour Windows..."

# Vérifier si on est sur Windows
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    echo "✅ Détection de Windows"
    
    # Créer le dossier llama.cpp s'il n'existe pas
    mkdir -p llama.cpp
    
    echo "📥 Téléchargement des binaires llama.cpp pour Windows..."
    
    # URL directe des binaires Windows
    DOWNLOAD_URL="https://github.com/ggml-org/llama.cpp/releases/download/b5604/llama-b5604-bin-win-cpu-x64.zip"
    
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
    
    # Chercher l'exécutable (llama-cli.exe ou main.exe)
    LLAMACLI_PATH=$(find llama.cpp -name "llama-cli.exe" -o -name "main.exe" -o -name "llama.exe" | head -n 1)
    
    if [ -n "$LLAMACLI_PATH" ]; then
        echo "✅ Exécutable trouvé: $LLAMACLI_PATH"
        
        # Mettre à jour la configuration avec le chemin Windows
        WINDOWS_PATH=$(echo "$LLAMACLI_PATH" | sed 's|/|\\|g')
        
        # Créer un nouveau config.json avec le bon chemin
        cat > config.json << EOF
{
  "port": 3000,
  "llamaCppPath": "./$LLAMACLI_PATH",
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
        
        echo "✅ Configuration mise à jour avec le chemin: ./$LLAMACLI_PATH"
        
    else
        echo "❌ Aucun exécutable trouvé dans l'archive"
        echo "📂 Contenu du dossier llama.cpp:"
        ls -la llama.cpp/
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
    
    # URL directe du modèle CroissantLLM
    MODEL_URL="https://huggingface.co/croissantllm/CroissantLLMChat-v0.1-GGUF/resolve/main/croissantllmchat-v0.1.Q4_K_M.gguf?download=true"
    
    echo "📦 Téléchargement du modèle depuis HuggingFace..."
    echo "⏳ Cela peut prendre plusieurs minutes (fichier ~2.4GB)..."
    
    if command -v wget &> /dev/null; then
        wget -O "models/croissant.gguf" "$MODEL_URL" --progress=bar:force
    elif command -v curl &> /dev/null; then
        curl -L -o "models/croissant.gguf" "$MODEL_URL" --progress-bar
    else
        echo "⚠️  wget ou curl requis pour télécharger le modèle"
        echo "Veuillez télécharger manuellement le modèle depuis:"
        echo "$MODEL_URL"
        echo "Et le placer dans: models/croissant.gguf"
    fi
    
    # Vérifier la taille du fichier téléchargé
    if [ -f "models/croissant.gguf" ]; then
        SIZE=$(du -h "models/croissant.gguf" | cut -f1)
        echo "✅ Modèle téléchargé avec succès (taille: $SIZE)"
    fi
else
    echo "✅ Modèle déjà présent"
fi

# Test de l'installation
echo "🧪 Test de la configuration..."
if [ -f "$LLAMACLI_PATH" ] && [ -f "models/croissant.gguf" ]; then
    echo "✅ Tous les fichiers sont présents"
    
    # Test rapide de llama.cpp
    echo "🔍 Test de llama.cpp..."
    timeout 5s "./$LLAMACLI_PATH" --help > /dev/null 2>&1
    if [ $? -eq 0 ] || [ $? -eq 124 ]; then  # 124 = timeout (normal)
        echo "✅ llama.cpp fonctionne correctement"
    else
        echo "⚠️  Test de llama.cpp partiellement réussi"
    fi
else
    echo "⚠️  Certains fichiers manquent, vérifiez l'installation"
fi

echo
echo "🎉 Configuration terminée pour Windows !"
echo "========================================="
echo
echo "Pour démarrer le chatbot :"
echo "  npm start"
echo
echo "URLs disponibles :"
echo "  • Interface principale:  http://localhost:3000"
echo "  • Version embeddable:    http://localhost:3000/embed"
echo "  • Exemples:              http://localhost:3000/examples/example.html"
echo
echo "Configuration :"
echo "  • Exécutable: ./$LLAMACLI_PATH"
echo "  • Modèle: ./models/croissant.gguf"
echo
