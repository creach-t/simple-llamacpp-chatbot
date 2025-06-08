#!/bin/bash

# Script d'installation automatique pour Simple LlamaCPP Chatbot
# Usage: bash install.sh

set -e

echo "🥐 Installation du Chatbot CroissantLLM"
echo "======================================="

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Vérifier si Node.js est installé
check_node() {
    info "Vérification de Node.js..."
    if ! command -v node &> /dev/null; then
        error "Node.js n'est pas installé. Veuillez l'installer depuis https://nodejs.org"
    fi
    
    NODE_VERSION=$(node --version | cut -c2-)
    REQUIRED_VERSION="14.0.0"
    
    if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$NODE_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
        success "Node.js version $NODE_VERSION détectée"
    else
        error "Node.js version $REQUIRED_VERSION ou supérieure requise, version $NODE_VERSION détectée"
    fi
}

# Installer les dépendances npm
install_dependencies() {
    info "Installation des dépendances npm..."
    if [ -f "package.json" ]; then
        npm install
        success "Dépendances installées"
    else
        error "Fichier package.json non trouvé"
    fi
}

# Vérifier/installer llama.cpp
setup_llamacpp() {
    info "Configuration de llama.cpp..."
    
    if [ ! -d "llama.cpp" ]; then
        warning "llama.cpp non trouvé, téléchargement en cours..."
        git clone https://github.com/ggerganov/llama.cpp.git
        cd llama.cpp
        
        info "Compilation de llama.cpp..."
        make -j4
        cd ..
        success "llama.cpp installé et compilé"
    else
        success "llama.cpp déjà présent"
    fi
    
    # Vérifier l'exécutable
    if [ -f "llama.cpp/llama-cli" ]; then
        success "Exécutable llama-cli trouvé"
    elif [ -f "llama.cpp/main" ]; then
        warning "Ancien nom d'exécutable détecté, création d'un lien symbolique..."
        ln -sf main llama.cpp/llama-cli
        success "Lien symbolique créé"
    else
        error "Exécutable llama.cpp non trouvé après compilation"
    fi
}

# Télécharger le modèle CroissantLLM
download_model() {
    info "Configuration du modèle CroissantLLM..."
    
    # Créer le dossier models
    mkdir -p models
    
    MODEL_FILE="models/croissant.gguf"
    
    if [ ! -f "$MODEL_FILE" ]; then
        warning "Modèle CroissantLLM non trouvé, téléchargement en cours..."
        
        # URL du modèle (quantifié Q4_K_M pour un bon équilibre taille/qualité)
        MODEL_URL="https://huggingface.co/croissantllm/CroissantLLMChat-v0.1-GGUF/resolve/main/croissant-llm-chat-v0.1.Q4_K_M.gguf"
        
        info "Téléchargement depuis HuggingFace..."
        info "Cela peut prendre plusieurs minutes selon votre connexion..."
        
        if command -v wget &> /dev/null; then
            wget -O "$MODEL_FILE" "$MODEL_URL" --progress=bar:force
        elif command -v curl &> /dev/null; then
            curl -L -o "$MODEL_FILE" "$MODEL_URL" --progress-bar
        else
            error "wget ou curl requis pour télécharger le modèle"
        fi
        
        success "Modèle téléchargé: $MODEL_FILE"
    else
        success "Modèle déjà présent: $MODEL_FILE"
    fi
    
    # Vérifier la taille du fichier
    if [ -f "$MODEL_FILE" ]; then
        SIZE=$(du -h "$MODEL_FILE" | cut -f1)
        info "Taille du modèle: $SIZE"
    fi
}

# Configurer les chemins
configure_paths() {
    info "Configuration des chemins..."
    
    # Chemin absolu vers llama.cpp
    LLAMA_PATH=$(realpath llama.cpp/llama-cli)
    MODEL_PATH=$(realpath models/croissant.gguf)
    
    # Créer ou mettre à jour config.json
    cat > config.json << EOF
{
  "port": 3000,
  "llamaCppPath": "$LLAMA_PATH",
  "modelPath": "$MODEL_PATH",
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
    
    success "Configuration mise à jour"
    info "Chemin llama.cpp: $LLAMA_PATH"
    info "Chemin modèle: $MODEL_PATH"
}

# Test de fonctionnement
test_setup() {
    info "Test de la configuration..."
    
    # Test basique de llama.cpp
    if [ -f "llama.cpp/llama-cli" ] && [ -f "models/croissant.gguf" ]; then
        info "Test de llama.cpp avec le modèle..."
        
        timeout 10s ./llama.cpp/llama-cli -m models/croissant.gguf -p "Bonjour" -n 5 --no-display-prompt > /dev/null 2>&1
        
        if [ $? -eq 0 ] || [ $? -eq 124 ]; then  # 124 = timeout (normal)
            success "Test réussi - llama.cpp fonctionne avec le modèle"
        else
            warning "Test partiellement réussi - vérifiez manuellement"
        fi
    else
        warning "Impossible de tester - fichiers manquants"
    fi
}

# Créer un script de démarrage
create_start_script() {
    info "Création du script de démarrage..."
    
    cat > start.sh << 'EOF'
#!/bin/bash

echo "🥐 Démarrage du Chatbot CroissantLLM..."

# Vérifier que tout est en place
if [ ! -f "config.json" ]; then
    echo "❌ Fichier config.json manquant"
    exit 1
fi

if [ ! -f "server.js" ]; then
    echo "❌ Fichier server.js manquant"
    exit 1
fi

# Démarrer le serveur
echo "🚀 Lancement du serveur..."
node server.js
EOF
    
    chmod +x start.sh
    success "Script de démarrage créé: ./start.sh"
}

# Afficher les instructions finales
show_instructions() {
    echo
    echo "🎉 Installation terminée !"
    echo "========================"
    echo
    echo "Pour démarrer le chatbot :"
    echo "  npm start"
    echo "  # ou"
    echo "  ./start.sh"
    echo
    echo "URLs disponibles :"
    echo "  • Interface principale:  http://localhost:3000"
    echo "  • Version embeddable:    http://localhost:3000/embed"
    echo "  • Exemple d'intégration: http://localhost:3000/examples/example.html"
    echo "  • Widget JavaScript:     http://localhost:3000/widget.js"
    echo
    echo "Configuration :"
    echo "  • Fichier: config.json"
    echo "  • Modèle: $(basename $(grep -o '"modelPath": "[^"]*"' config.json | cut -d'"' -f4) 2>/dev/null || echo 'models/croissant.gguf')"
    echo "  • Threads: $(grep -o '"threads": [0-9]*' config.json | cut -d':' -f2 | tr -d ' ' 2>/dev/null || echo '4')"
    echo
    echo "Pour personnaliser, éditez le fichier config.json"
    echo
    warning "Première utilisation: le modèle peut prendre quelques secondes à se charger"
    echo
}

# Fonction principale
main() {
    echo
    info "Début de l'installation..."
    echo
    
    check_node
    install_dependencies
    setup_llamacpp
    download_model
    configure_paths
    test_setup
    create_start_script
    
    echo
    show_instructions
}

# Vérifier si on est dans le bon dossier
if [ ! -f "package.json" ] || [ ! -f "server.js" ]; then
    error "Veuillez exécuter ce script depuis le dossier racine du projet"
fi

# Demander confirmation avant installation
echo
read -p "Voulez-vous continuer l'installation ? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    main
else
    info "Installation annulée"
    exit 0
fi
