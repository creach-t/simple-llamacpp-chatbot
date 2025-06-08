(function() {
    'use strict';

    // Configuration par défaut
    const defaultConfig = {
        title: 'Assistant CroissantLLM',
        placeholder: 'Tapez votre message...',
        primaryColor: '#4A90E2',
        secondaryColor: '#F5F5F5',
        textColor: '#333333',
        width: '400px',
        height: '600px',
        position: 'bottom-right',
        showToggle: true,
        serverUrl: window.location.origin,
        zIndex: 9999
    };

    // Widget principal
    window.ChatbotWidget = {
        init: function(options = {}) {
            this.config = { ...defaultConfig, ...options };
            this.isOpen = false;
            this.container = null;
            this.iframe = null;
            
            if (this.config.container) {
                this.createEmbeddedWidget();
            } else {
                this.createFloatingWidget();
            }
        },

        createEmbeddedWidget: function() {
            const container = typeof this.config.container === 'string' 
                ? document.querySelector(this.config.container)
                : this.config.container;

            if (!container) {
                console.error('ChatbotWidget: Container not found');
                return;
            }

            container.style.position = 'relative';
            container.style.width = this.config.width;
            container.style.height = this.config.height;

            this.iframe = document.createElement('iframe');
            this.iframe.src = `${this.config.serverUrl}/embed`;
            this.iframe.style.width = '100%';
            this.iframe.style.height = '100%';
            this.iframe.style.border = 'none';
            this.iframe.style.borderRadius = '8px';
            this.iframe.style.boxShadow = '0 2px 10px rgba(0, 0, 0, 0.1)';

            container.appendChild(this.iframe);

            // Configurer la communication
            this.setupCommunication();
        },

        createFloatingWidget: function() {
            // Créer le bouton de toggle si activé
            if (this.config.showToggle) {
                this.createToggleButton();
            }

            // Créer le conteneur du widget
            this.container = document.createElement('div');
            this.container.id = 'chatbot-widget-container';
            this.container.style.cssText = `
                position: fixed;
                ${this.getPositionStyles()}
                width: ${this.config.width};
                height: ${this.config.height};
                z-index: ${this.config.zIndex};
                display: none;
                box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
                border-radius: 12px;
                overflow: hidden;
                transition: all 0.3s ease;
                transform: translateY(20px);
                opacity: 0;
            `;

            // Créer l'iframe
            this.iframe = document.createElement('iframe');
            this.iframe.src = `${this.config.serverUrl}/embed`;
            this.iframe.style.cssText = `
                width: 100%;
                height: 100%;
                border: none;
                border-radius: 12px;
            `;

            this.container.appendChild(this.iframe);
            document.body.appendChild(this.container);

            // Configurer la communication
            this.setupCommunication();
        },

        createToggleButton: function() {
            this.toggleButton = document.createElement('button');
            this.toggleButton.id = 'chatbot-toggle-button';
            this.toggleButton.innerHTML = `
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="m3 21 1.9-5.7a8.5 8.5 0 1 1 3.8 3.8z"></path>
                </svg>
            `;
            
            this.toggleButton.style.cssText = `
                position: fixed;
                ${this.getPositionStyles(true)}
                width: 60px;
                height: 60px;
                border-radius: 50%;
                background: ${this.config.primaryColor};
                color: white;
                border: none;
                cursor: pointer;
                z-index: ${this.config.zIndex + 1};
                box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
                transition: all 0.3s ease;
                display: flex;
                align-items: center;
                justify-content: center;
            `;

            this.toggleButton.addEventListener('click', () => {
                this.toggle();
            });

            this.toggleButton.addEventListener('mouseenter', () => {
                this.toggleButton.style.transform = 'scale(1.1)';
            });

            this.toggleButton.addEventListener('mouseleave', () => {
                this.toggleButton.style.transform = 'scale(1)';
            });

            document.body.appendChild(this.toggleButton);
        },

        getPositionStyles: function(isButton = false) {
            const offset = isButton ? '20px' : '80px';
            
            switch (this.config.position) {
                case 'bottom-right':
                    return `bottom: ${offset}; right: 20px;`;
                case 'bottom-left':
                    return `bottom: ${offset}; left: 20px;`;
                case 'top-right':
                    return `top: ${offset}; right: 20px;`;
                case 'top-left':
                    return `top: ${offset}; left: 20px;`;
                default:
                    return `bottom: ${offset}; right: 20px;`;
            }
        },

        setupCommunication: function() {
            window.addEventListener('message', (event) => {
                if (event.data.source === 'croissant-chatbot') {
                    this.handleMessage(event.data);
                }
            });

            // Attendre que l'iframe soit prête
            this.iframe.addEventListener('load', () => {
                setTimeout(() => {
                    this.sendConfigToIframe();
                }, 100);
            });
        },

        sendConfigToIframe: function() {
            if (this.iframe && this.iframe.contentWindow) {
                this.iframe.contentWindow.postMessage({
                    type: 'chatbot-config',
                    config: {
                        chatbot: {
                            title: this.config.title,
                            placeholder: this.config.placeholder,
                            primaryColor: this.config.primaryColor,
                            secondaryColor: this.config.secondaryColor,
                            textColor: this.config.textColor
                        }
                    }
                }, this.config.serverUrl);
            }
        },

        handleMessage: function(data) {
            switch (data.type) {
                case 'chatbot-ready':
                    this.onReady();
                    break;
                case 'chatbot-message':
                    this.onMessage(data.message);
                    break;
            }
        },

        onReady: function() {
            console.log('Chatbot widget ready');
            this.sendConfigToIframe();
        },

        onMessage: function(message) {
            // Événement personnalisé pour les développeurs
            const event = new CustomEvent('chatbot-message', {
                detail: message
            });
            document.dispatchEvent(event);
        },

        toggle: function() {
            if (this.isOpen) {
                this.close();
            } else {
                this.open();
            }
        },

        open: function() {
            if (!this.container) return;
            
            this.isOpen = true;
            this.container.style.display = 'block';
            
            // Animation d'ouverture
            setTimeout(() => {
                this.container.style.transform = 'translateY(0)';
                this.container.style.opacity = '1';
            }, 10);

            // Mettre à jour le bouton
            if (this.toggleButton) {
                this.toggleButton.innerHTML = `
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <line x1="18" y1="6" x2="6" y2="18"></line>
                        <line x1="6" y1="6" x2="18" y2="18"></line>
                    </svg>
                `;
            }
        },

        close: function() {
            if (!this.container) return;
            
            this.isOpen = false;
            this.container.style.transform = 'translateY(20px)';
            this.container.style.opacity = '0';
            
            setTimeout(() => {
                this.container.style.display = 'none';
            }, 300);

            // Mettre à jour le bouton
            if (this.toggleButton) {
                this.toggleButton.innerHTML = `
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="m3 21 1.9-5.7a8.5 8.5 0 1 1 3.8 3.8z"></path>
                    </svg>
                `;
            }
        },

        // API publique
        sendMessage: function(message) {
            if (this.iframe && this.iframe.contentWindow) {
                this.iframe.contentWindow.postMessage({
                    type: 'send-message',
                    message: message
                }, this.config.serverUrl);
            }
        },

        clearChat: function() {
            if (this.iframe && this.iframe.contentWindow && this.iframe.contentWindow.ChatbotEmbed) {
                this.iframe.contentWindow.ChatbotEmbed.clearChat();
            }
        },

        updateConfig: function(newConfig) {
            this.config = { ...this.config, ...newConfig };
            this.sendConfigToIframe();
        },

        destroy: function() {
            if (this.container) {
                this.container.remove();
            }
            if (this.toggleButton) {
                this.toggleButton.remove();
            }
            if (this.iframe) {
                this.iframe.remove();
            }
        }
    };

    // Auto-initialisation si des attributs data sont présents
    document.addEventListener('DOMContentLoaded', function() {
        const autoInit = document.querySelector('[data-chatbot-auto-init]');
        if (autoInit) {
            const config = {};
            
            // Récupérer la configuration depuis les attributs data
            const attributes = autoInit.attributes;
            for (let i = 0; i < attributes.length; i++) {
                const attr = attributes[i];
                if (attr.name.startsWith('data-chatbot-')) {
                    const key = attr.name.replace('data-chatbot-', '').replace(/-/g, '');
                    let value = attr.value;
                    
                    // Conversion des types
                    if (value === 'true') value = true;
                    if (value === 'false') value = false;
                    if (!isNaN(value) && value !== '') value = Number(value);
                    
                    config[key] = value;
                }
            }
            
            // Initialiser le widget
            window.ChatbotWidget.init(config);
        }
    });

    // Styles CSS injectés
    const style = document.createElement('style');
    style.textContent = `
        #chatbot-toggle-button:hover {
            transform: scale(1.1) !important;
        }
        
        #chatbot-toggle-button:active {
            transform: scale(0.95) !important;
        }
        
        #chatbot-widget-container.show {
            display: block !important;
            opacity: 1 !important;
            transform: translateY(0) !important;
        }
        
        @media (max-width: 768px) {
            #chatbot-widget-container {
                width: calc(100vw - 40px) !important;
                height: calc(100vh - 100px) !important;
                bottom: 80px !important;
                right: 20px !important;
                left: 20px !important;
            }
        }
    `;
    document.head.appendChild(style);

})();
