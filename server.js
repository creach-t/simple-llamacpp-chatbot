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