# Simple LlamaCPP Chatbot 🥐

Un chatbot simple et personnalisable utilisant llama.cpp avec le modèle CroissantLLM, facilement embeddable sur n'importe quel site web.

## 🚀 Fonctionnalités

- Interface de chat simple et responsive
- Utilise le modèle CroissantLLM français
- Personnalisable (couleurs, titre, placeholder, etc.)
- Embeddable sur n'importe quel site
- Backend Express.js simple
- Support pour llama.cpp

## 📋 Prérequis

- Node.js (v14 ou plus récent)
- llama.cpp installé
- Le modèle CroissantLLM téléchargé

## 🛠️ Installation

1. **Cloner le repository**
   ```bash
   git clone https://github.com/creach-t/simple-llamacpp-chatbot.git
   cd simple-llamacpp-chatbot
   ```

2. **Installer les dépendances**
   ```bash
   npm install
   ```

3. **Installer llama.cpp** (si ce n'est pas déjà fait)
   ```bash
   git clone https://github.com/ggerganov/llama.cpp.git
   cd llama.cpp
   make
   ```

4. **Télécharger le modèle CroissantLLM**
   ```bash
   # Créer le dossier models
   mkdir -p models
   
   # Télécharger le modèle (exemple avec wget)
   wget -O models/croissant.gguf https://huggingface.co/croissantllm/CroissantLLMChat-v0.1-GGUF/resolve/main/croissant-llm-chat-v0.1.Q4_K_M.gguf
   ```

5. **Configurer les chemins**
   
   Modifier le fichier `config.json` selon votre installation :
   ```json
   {
     "llamaCppPath": "/path/to/llama.cpp/llama-cli",
     "modelPath": "./models/croissant.gguf"
   }
   ```

## 🚀 Utilisation

### Démarrer le serveur

```bash
npm start
```

Le serveur sera accessible sur `http://localhost:3000`

### Embed sur votre site

#### Option 1 : Iframe
```html
<iframe 
  src="http://localhost:3000/embed" 
  width="400" 
  height="600" 
  frameborder="0">
</iframe>
```

#### Option 2 : Widget JavaScript
```html
<div id="chatbot-container"></div>
<script src="http://localhost:3000/widget.js"></script>
<script>
  ChatbotWidget.init({
    container: '#chatbot-container',
    title: 'Mon Chatbot',
    primaryColor: '#007bff',
    placeholder: 'Tapez votre message...'
  });
</script>
```

## ⚙️ Configuration

Le fichier `config.json` permet de personnaliser :

- `port` : Port du serveur (défaut: 3000)
- `llamaCppPath` : Chemin vers l'exécutable llama-cli
- `modelPath` : Chemin vers le modèle .gguf
- `maxTokens` : Nombre maximum de tokens générés (défaut: 100)
- `temperature` : Créativité du modèle (0.0 à 1.0)

## 📁 Structure du projet

```
simple-llamacpp-chatbot/
├── server.js           # Serveur Express principal
├── config.json         # Configuration
├── package.json        # Dépendances npm
├── public/            
│   ├── index.html      # Interface principale
│   ├── embed.html      # Version embeddable
│   ├── widget.js       # Widget JavaScript
│   └── style.css       # Styles CSS
└── models/             # Dossier pour les modèles
```

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou soumettre une pull request.

## 📄 Licence

MIT License
