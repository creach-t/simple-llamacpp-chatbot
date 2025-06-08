const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

// Charger la configuration
const config = JSON.parse(fs.readFileSync('./config.json', 'utf8'));

const app = express();

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(express.static('public'));

// Route principale
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Route pour la version embeddable
app.get('/embed', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'embed.html'));
});

// Route pour récupérer la configuration côté client
app.get('/api/config', (req, res) => {
    res.json({
        chatbot: config.chatbot
    });
});

// Route principale du chat
app.post('/api/chat', async (req, res) => {
    try {
        const { message, history = [] } = req.body;

        if (!message || message.trim() === '') {
            return res.status(400).json({ error: 'Message requis' });
        }

        // Construire le contexte avec l'historique
        let prompt = '';
        
        // Ajouter l'historique des messages précédents
        if (history.length > 0) {
            history.forEach(msg => {
                if (msg.type === 'user') {
                    prompt += `Utilisateur: ${msg.content}\n`;
                } else if (msg.type === 'bot') {
                    prompt += `Assistant: ${msg.content}\n`;
                }
            });
        }
        
        // Ajouter le message actuel
        prompt += `Utilisateur: ${message}\nAssistant:`;

        console.log('Prompt envoyé:', prompt);

        // Appeler llama.cpp
        const response = await callLlamaCpp(prompt);
        
        res.json({ 
            response: response.trim(),
            status: 'success'
        });

    } catch (error) {
        console.error('Erreur lors du traitement:', error);
        res.status(500).json({ 
            error: 'Erreur interne du serveur',
            details: error.message 
        });
    }
});

// Fonction pour appeler llama.cpp
function callLlamaCpp(prompt) {
    return new Promise((resolve, reject) => {
        const args = [
            '-m', config.modelPath,
            '-p', prompt,
            '-n', config.maxTokens.toString(),
            '--temp', config.temperature.toString(),
            '-c', config.llamaArgs.ctx_size.toString(),
            '-t', config.llamaArgs.threads.toString(),
            '-b', config.llamaArgs.batch_size.toString(),
            '--no-display-prompt',
            '--no-warmup'  // Éviter le réchauffage à chaque appel
        ];

        console.log('Commande llama.cpp:', config.llamaCppPath, args.join(' '));

        const llamaProcess = spawn(config.llamaCppPath, args);
        
        let output = '';
        let errorOutput = '';

        llamaProcess.stdout.on('data', (data) => {
            output += data.toString();
        });

        llamaProcess.stderr.on('data', (data) => {
            errorOutput += data.toString();
        });

        llamaProcess.on('close', (code) => {
            if (code === 0) {
                // Nettoyer la sortie
                const cleanOutput = output
                    .replace(/^\s*\n/, '') // Enlever les nouvelles lignes au début
                    .replace(/\n\s*$/, '') // Enlever les nouvelles lignes à la fin
                    .trim();
                
                resolve(cleanOutput || 'Désolé, je n\'ai pas pu générer une réponse.');
            } else {
                console.error('Erreur llama.cpp:', errorOutput);
                reject(new Error(`llama.cpp a échoué avec le code ${code}: ${errorOutput}`));
            }
        });

        llamaProcess.on('error', (error) => {
            console.error('Erreur de spawn:', error);
            reject(new Error(`Impossible de lancer llama.cpp: ${error.message}`));
        });

        // Timeout de sécurité plus long pour Windows et premier démarrage
        setTimeout(() => {
            llamaProcess.kill();
            reject(new Error('Timeout: llama.cpp a pris trop de temps (60s)'));
        }, 60000); // 60 secondes au lieu de 30
    });
}

// Route de santé
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'ok', 
        timestamp: new Date().toISOString(),
        model: config.modelPath,
        llamaPath: config.llamaCppPath
    });
});

// Middleware de gestion d'erreurs
app.use((error, req, res, next) => {
    console.error('Erreur non gérée:', error);
    res.status(500).json({
        error: 'Erreur interne du serveur',
        message: error.message
    });
});

// Démarrer le serveur
const PORT = config.port || 3000;
app.listen(PORT, () => {
    console.log(`🚀 Serveur démarré sur le port ${PORT}`);
    console.log(`📱 Interface: http://localhost:${PORT}`);
    console.log(`🔗 Version embeddable: http://localhost:${PORT}/embed`);
    console.log(`🤖 Modèle: ${config.modelPath}`);
    console.log(`⚙️  llama.cpp: ${config.llamaCppPath}`);
    console.log(`⏰ Timeout: 60 secondes`);
    console.log(`💡 Conseil: La première génération peut prendre plus de temps`);
});
