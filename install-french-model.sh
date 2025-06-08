#!/bin/bash

# Script pour changer de modèle français
echo "🇫🇷 Installation d'un modèle français pour Windows..."

MODEL_CHOICE=""

echo "Choisissez votre modèle français :"
echo "1. Vigogne-2-7B-Chat (Recommandé - ~4GB, optimisé conversation française)"
echo "2. Qwen2.5-7B-Instruct (Performance maximale - ~4.5GB, multilingue)"
echo "3. Vigogne-2-13B-Instruct (Plus puissant - ~7GB, instruction française)"
echo

read -p "Votre choix (1-3): " choice

case $choice in
    1)
        MODEL_NAME="vigogne-2-7b-chat"
        MODEL_URL="https://huggingface.co/TheBloke/Vigogne-2-7B-Chat-GGUF/resolve/main/vigogne-2-7b-chat.q4_K_M.gguf"
        TEMPLATE_TYPE="vigogne_chat"
        echo "✅ Vigogne-2-7B-Chat sélectionné"
        ;;
    2)
        MODEL_NAME="qwen2.5-7b-instruct"
        MODEL_URL="https://huggingface.co/Qwen/Qwen2.5-7B-Instruct-GGUF/resolve/main/qwen2.5-7b-instruct-q4_k_m.gguf"
        TEMPLATE_TYPE="chatml"
        echo "✅ Qwen2.5-7B-Instruct sélectionné"
        ;;
    3)
        MODEL_NAME="vigogne-2-13b-instruct"
        MODEL_URL="https://huggingface.co/TheBloke/Vigogne-2-13B-Instruct-GGUF/resolve/main/vigogne-2-13b-instruct.q4_K_M.gguf"
        TEMPLATE_TYPE="vigogne_instruct"
        echo "✅ Vigogne-2-13B-Instruct sélectionné"
        ;;
    *)
        echo "❌ Choix invalide"
        exit 1
        ;;
esac

echo "📥 Téléchargement du modèle $MODEL_NAME..."
echo "🔗 URL: $MODEL_URL"

mkdir -p models

if command -v wget &> /dev/null; then
    wget -O "models/${MODEL_NAME}.gguf" "$MODEL_URL" --progress=bar:force
elif command -v curl &> /dev/null; then
    curl -L -o "models/${MODEL_NAME}.gguf" "$MODEL_URL" --progress-bar
else
    echo "❌ wget ou curl requis pour télécharger le modèle"
    echo "Téléchargez manuellement depuis: $MODEL_URL"
    echo "Et placez le fichier dans: models/${MODEL_NAME}.gguf"
    exit 1
fi

echo "⚙️  Mise à jour de la configuration..."

# Mettre à jour config.json
case $TEMPLATE_TYPE in
    "vigogne_chat")
        cat > config.json << EOF
{
  "port": 3000,
  "llamaCppPath": "./llama.cpp/llama-cli.exe",
  "modelPath": "./models/${MODEL_NAME}.gguf",
  "maxTokens": 150,
  "temperature": 0.7,
  "templateType": "vigogne_chat",
  "chatbot": {
    "title": "Assistant Vigogne 🇫🇷",
    "placeholder": "Tapez votre message en français...",
    "primaryColor": "#1E40AF",
    "secondaryColor": "#F1F5F9",
    "textColor": "#1F2937",
    "maxMessages": 50,
    "typingDelay": 100
  },
  "llamaArgs": {
    "ctx_size": 4096,
    "threads": 4,
    "batch_size": 512
  }
}
EOF
        ;;
    "chatml")
        cat > config.json << EOF
{
  "port": 3000,
  "llamaCppPath": "./llama.cpp/llama-cli.exe",
  "modelPath": "./models/${MODEL_NAME}.gguf",
  "maxTokens": 150,
  "temperature": 0.7,
  "templateType": "chatml",
  "chatbot": {
    "title": "Assistant Qwen 🌐",
    "placeholder": "Tapez votre message...",
    "primaryColor": "#7C3AED",
    "secondaryColor": "#F3F4F6",
    "textColor": "#111827",
    "maxMessages": 50,
    "typingDelay": 100
  },
  "llamaArgs": {
    "ctx_size": 4096,
    "threads": 4,
    "batch_size": 512
  }
}
EOF
        ;;
    "vigogne_instruct")
        cat > config.json << EOF
{
  "port": 3000,
  "llamaCppPath": "./llama.cpp/llama-cli.exe",
  "modelPath": "./models/${MODEL_NAME}.gguf",
  "maxTokens": 150,
  "temperature": 0.7,
  "templateType": "vigogne_instruct",
  "chatbot": {
    "title": "Assistant Vigogne Pro 🇫🇷",
    "placeholder": "Posez votre question en français...",
    "primaryColor": "#059669",
    "secondaryColor": "#ECFDF5",
    "textColor": "#065F46",
    "maxMessages": 50,
    "typingDelay": 100
  },
  "llamaArgs": {
    "ctx_size": 4096,
    "threads": 4,
    "batch_size": 512
  }
}
EOF
        ;;
esac

# Vérifier la taille du fichier téléchargé
if [ -f "models/${MODEL_NAME}.gguf" ]; then
    SIZE=$(du -h "models/${MODEL_NAME}.gguf" | cut -f1)
    echo "✅ Modèle téléchargé avec succès (taille: $SIZE)"
else
    echo "❌ Erreur lors du téléchargement"
    exit 1
fi

echo
echo "🎉 Installation terminée !"
echo "========================="
echo
echo "Modèle installé: $MODEL_NAME"
echo "Template: $TEMPLATE_TYPE"
echo "Fichier: models/${MODEL_NAME}.gguf"
echo
echo "Pour démarrer avec le nouveau modèle :"
echo "  npm start"
echo
echo "Le chatbot sera optimisé pour le français ! 🇫🇷"
echo
