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

// Fonction pour formater le prompt selon le template
function formatPrompt(message, history, templateType) {
    let prompt = '';
    
    switch (templateType) {
        case 'vigogne_chat':
            // Template Vigogne Chat: <|UTILISATEUR|>: ... <|ASSISTANT|>:
            if (history.length > 0) {
                history.forEach(msg => {
                    if (msg.type === 'user') {
                        prompt += `<|UTILISATEUR|>: ${msg.content}\n`;
                    } else if (msg.type === 'bot') {
                        prompt += `<|ASSISTANT|>: ${msg.content}\n`;
                    }
                });
            }
            prompt += `<|UTILISATEUR|>: ${message}\n<|ASSISTANT|>:`;
            break;
            
        case 'vigogne_instruct':
            // Template Vigogne Instruct: ### Instruction: ... ### Response:
            prompt = `Below is an instruction that describes a task. Write a response that appropriately completes the request.\n\n### Instruction:\n${message}\n\n### Response:`;
            break;
            
        case 'chatml':
        default:
            // Template ChatML (Qwen, CroissantLLM): <|im_start|>user ... <|im_end|>
            if (history.length > 0) {
                history.forEach(msg => {
                    if (msg.type === 'user') {
                        prompt += `<|im_start|>user\n${msg.content}<|im_end|>\n`;
                    } else if (msg.type === 'bot') {
                        prompt += `<|im_start|>assistant\n${msg.content}<|im_end|>\n`;
                    }
                });
            }
            prompt += `<|im_start|>user\n${message}<|im_end|>\n<|im_start|>assistant\n`;
            break;
    }
    
    return prompt;
}

// Fonction pour nettoyer la sortie selon le template
function cleanOutput(output, templateType) {
    let cleanOutput = output;
    
    switch (templateType) {
        case 'vigogne_chat':
            cleanOutput = cleanOutput
                .replace(/<\|UTILISATEUR\|>:.*$/g, '') // Supprimer les répétitions
                .replace(/<\|ASSISTANT\|>:/g, '')
                .trim();
            break;
            
        case 'vigogne_instruct':
            cleanOutput = cleanOutput
                .replace(/### Instruction:.*$/g, '')
                .replace(/### Response:/g, '')
                .trim();
            break;
            
        case 'chatml':
        default:
            cleanOutput = cleanOutput
                .replace(/<\|im_end\|>/g, '')
                .replace(/<\|im_start\|>.*$/g, '')
                .trim();
            break;
    }
    
    return cleanOutput;
}

// Route principale du chat
app.post('/api/chat', async (req, res) => {
    try {
        const { message, history = [] } = req.body;

        if (!message || message.trim() === '') {
            return res.status(400).json({ error: 'Message requis' });
        }

        // Déterminer le type de template
        const templateType = config.templateType || 'chatml';
        
        // Construire le prompt selon le template
        const prompt = formatPrompt(message, history, templateType);

        console.log('Template utilisé:', templateType);
        console.log('Prompt envoyé:', prompt);

        // Appeler llama.cpp
        const response = await callLlamaCpp(prompt, templateType);
        
        res.json({ 
            response: response.trim(),
            status: 'success',
            template: templateType
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
function callLlamaCpp(prompt, templateType) {
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
            '-e',  // Traiter les échappements
            '-s', '-1'  // Seed aléatoire
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
                // Nettoyer la sortie selon le template
                let cleanedOutput = cleanOutput(output, templateType);
                
                // Si la réponse est vide, fournir un message par défaut
                if (!cleanedOutput) {
                    cleanedOutput = 'Désolé, je n\'ai pas pu générer une réponse.';
                }
                
                resolve(cleanedOutput);
            } else {
                console.error('Erreur llama.cpp:', errorOutput);
                reject(new Error(`llama.cpp a échoué avec le code ${code}: ${errorOutput}`));
            }
        });

        llamaProcess.on('error', (error) => {
            console.error('Erreur de spawn:', error);
            reject(new Error(`Impossible de lancer llama.cpp: ${error.message}`));
        });

        // Timeout de sécurité 
        setTimeout(() => {
            llamaProcess.kill();
            reject(new Error('Timeout: llama.cpp a pris trop de temps (90s)'));
        }, 90000);
    });
}

// Route de santé
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'ok', 
        timestamp: new Date().toISOString(),
        model: config.modelPath,
        llamaPath: config.llamaCppPath,
        template: config.templateType || 'chatml'
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
    const templateType = config.templateType || 'chatml';
    const modelName = path.basename(config.modelPath, '.gguf');
    
    console.log(`🚀 Serveur démarré sur le port ${PORT}`);
    console.log(`📱 Interface: http://localhost:${PORT}`);
    console.log(`🔗 Version embeddable: http://localhost:${PORT}/embed`);
    console.log(`🤖 Modèle: ${modelName}`);
    console.log(`⚙️  llama.cpp: ${config.llamaCppPath}`);
    console.log(`📝 Template: ${templateType}`);
    console.log(`⏰ Timeout: 90 secondes`);
    console.log(`💬 Première génération peut prendre 30-60 secondes`);
});
