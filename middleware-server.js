// ============================================================================
// Lovense API Middleware Server for Second Life Integration
// ============================================================================
// This Node.js/Express server acts as a bridge between Second Life and the
// Lovense API, handling authentication and forwarding requests.
//
// Setup:
// 1. npm install express node-fetch dotenv
// 2. Copy config.example.json to config.json and configure
// 3. Set up SSL certificates (required for Second Life)
// 4. node middleware-server.js
// ============================================================================

const express = require('express');
const https = require('https');
const fs = require('fs');
const path = require('path');

// Load configuration
const config = require('./config.json');

const app = express();
app.use(express.json());

// ============================================================================
// Configuration Validation
// ============================================================================

function validateConfig() {
    const required = [
        'lovense.developer_token',
        'lovense.user_id',
        'middleware.server_url',
        'middleware.port'
    ];

    const missing = required.filter(key => {
        const keys = key.split('.');
        let value = config;
        for (const k of keys) {
            value = value?.[k];
        }
        return !value || value.includes('YOUR_') || value.includes('EXAMPLE');
    });

    if (missing.length > 0) {
        console.error('❌ Configuration Error: Missing or invalid values for:');
        missing.forEach(key => console.error(`   - ${key}`));
        console.error('\nPlease copy config.example.json to config.json and configure it.');
        process.exit(1);
    }
}

// ============================================================================
// Rate Limiting
// ============================================================================

const rateLimitMap = new Map();

function checkRateLimit(userId) {
    if (!config.rate_limiting?.enabled) return true;

    const now = Date.now();
    const userLimits = rateLimitMap.get(userId) || { requests: [], lastRequest: 0 };

    // Clean old requests (older than 1 minute)
    userLimits.requests = userLimits.requests.filter(time => now - time < 60000);

    // Check per-minute limit
    if (userLimits.requests.length >= config.rate_limiting.max_requests_per_minute) {
        return false;
    }

    // Check per-second limit
    const recentRequests = userLimits.requests.filter(time => now - time < 1000);
    if (recentRequests.length >= config.rate_limiting.max_requests_per_second) {
        return false;
    }

    // Check cooldown
    if (now - userLimits.lastRequest < config.rate_limiting.cooldown_ms) {
        return false;
    }

    // Update limits
    userLimits.requests.push(now);
    userLimits.lastRequest = now;
    rateLimitMap.set(userId, userLimits);

    return true;
}

// ============================================================================
// Logging
// ============================================================================

function log(level, message, data = null) {
    if (!config.logging?.enabled) return;

    const timestamp = new Date().toISOString();
    const logEntry = {
        timestamp,
        level,
        message,
        ...(data && { data })
    };

    const logLine = JSON.stringify(logEntry);
    console.log(logLine);

    if (config.logging.log_file_path) {
        fs.appendFileSync(config.logging.log_file_path, logLine + '\n');
    }
}

// ============================================================================
// Lovense API Integration
// ============================================================================

async function sendToLovenseAPI(payload) {
    const apiUrl = config.lan_api?.enabled
        ? `https://${config.lan_api.local_ip}:${config.lan_api.https_port}/command`
        : 'https://api.lovense.com/api/lan/command';

    // Add authentication for cloud API
    if (!config.lan_api?.enabled) {
        payload.token = config.lovense.developer_token;
        payload.uid = config.lovense.user_id;
    }

    if (config.logging?.log_requests) {
        log('info', 'Sending request to Lovense API', { url: apiUrl, payload });
    }

    try {
        const response = await fetch(apiUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(payload)
        });

        const data = await response.json();

        if (config.logging?.log_responses) {
            log('info', 'Received response from Lovense API', data);
        }

        return { status: response.status, data };
    } catch (error) {
        if (config.logging?.log_errors) {
            log('error', 'Error communicating with Lovense API', {
                error: error.message,
                stack: error.stack
            });
        }
        throw error;
    }
}

// ============================================================================
// Routes
// ============================================================================

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        version: '1.0.0'
    });
});

// Main command endpoint
app.post('/lovense/command', async (req, res) => {
    try {
        const { command, action, timeSec, toy, apiVer } = req.body;

        // Validate required fields
        if (!command) {
            return res.status(400).json({
                code: 400,
                type: 'error',
                message: 'Missing required field: command'
            });
        }

        // Check rate limiting (use a placeholder user ID or extract from request)
        const userId = req.body.userId || 'sl-user';
        if (!checkRateLimit(userId)) {
            return res.status(429).json({
                code: 429,
                type: 'error',
                message: 'Rate limit exceeded. Please slow down.'
            });
        }

        // Build payload for Lovense API
        const payload = {
            command,
            ...(action && { action }),
            ...(timeSec !== undefined && { timeSec }),
            ...(toy && { toy }),
            apiVer: apiVer || config.defaults?.api_version || 1
        };

        // Security check: limit maximum intensity
        if (action && config.security?.max_intensity) {
            const intensityMatch = action.match(/(\d+)/);
            if (intensityMatch && parseInt(intensityMatch[1]) > config.security.max_intensity) {
                return res.status(403).json({
                    code: 403,
                    type: 'error',
                    message: `Intensity exceeds maximum allowed (${config.security.max_intensity})`
                });
            }
        }

        // Forward to Lovense API
        const { status, data } = await sendToLovenseAPI(payload);

        res.status(status).json(data);

    } catch (error) {
        log('error', 'Error processing command', {
            error: error.message,
            stack: error.stack
        });

        res.status(500).json({
            code: 500,
            type: 'error',
            message: 'Internal server error',
            ...(process.env.NODE_ENV === 'development' && { error: error.message })
        });
    }
});

// Get toys endpoint
app.post('/lovense/toys', async (req, res) => {
    try {
        const payload = {
            command: 'GetToys',
            apiVer: 1
        };

        const { status, data } = await sendToLovenseAPI(payload);
        res.status(status).json(data);

    } catch (error) {
        log('error', 'Error getting toys', { error: error.message });
        res.status(500).json({
            code: 500,
            type: 'error',
            message: 'Failed to get toy information'
        });
    }
});

// Callback endpoint for Lovense webhooks
app.post('/lovense/callback', (req, res) => {
    log('info', 'Received callback from Lovense', req.body);
    res.status(200).json({ received: true });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        code: 404,
        type: 'error',
        message: 'Endpoint not found'
    });
});

// ============================================================================
// Server Startup
// ============================================================================

function startServer() {
    validateConfig();

    const port = config.middleware.port || 3000;

    if (config.middleware.enable_https) {
        // HTTPS Server (required for Second Life)
        if (!config.middleware.ssl_cert_path || !config.middleware.ssl_key_path) {
            console.error('❌ HTTPS is enabled but SSL certificate paths are not configured');
            process.exit(1);
        }

        const httpsOptions = {
            cert: fs.readFileSync(config.middleware.ssl_cert_path),
            key: fs.readFileSync(config.middleware.ssl_key_path)
        };

        https.createServer(httpsOptions, app).listen(port, () => {
            console.log('═══════════════════════════════════════════════════════');
            console.log('🚀 Lovense Middleware Server (HTTPS)');
            console.log('═══════════════════════════════════════════════════════');
            console.log(`🌐 Listening on: https://localhost:${port}`);
            console.log(`📡 API Mode: ${config.lan_api?.enabled ? 'LAN' : 'Cloud'}`);
            console.log(`🔒 Rate Limiting: ${config.rate_limiting?.enabled ? 'Enabled' : 'Disabled'}`);
            console.log(`📝 Logging: ${config.logging?.enabled ? 'Enabled' : 'Disabled'}`);
            console.log('═══════════════════════════════════════════════════════');
        });
    } else {
        // HTTP Server (for testing only - will NOT work with Second Life)
        app.listen(port, () => {
            console.log('═══════════════════════════════════════════════════════');
            console.log('⚠️  Lovense Middleware Server (HTTP - TESTING ONLY)');
            console.log('═══════════════════════════════════════════════════════');
            console.log(`🌐 Listening on: http://localhost:${port}`);
            console.log('⚠️  WARNING: Second Life requires HTTPS with valid SSL!');
            console.log('═══════════════════════════════════════════════════════');
        });
    }
}

// Handle graceful shutdown
process.on('SIGTERM', () => {
    log('info', 'SIGTERM received, shutting down gracefully');
    process.exit(0);
});

process.on('SIGINT', () => {
    log('info', 'SIGINT received, shutting down gracefully');
    process.exit(0);
});

// Start the server
startServer();
