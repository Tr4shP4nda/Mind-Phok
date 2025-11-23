// ============================================================================
// Simple Lovense QR Code Callback Receiver
// ============================================================================
// This is a minimal Node.js server that receives Lovense callbacks and
// provides a simple API for LSL to fetch connection info.
//
// Installation:
//   npm install express body-parser
//
// Run:
//   node qr-callback-receiver.js
//
// Or use a free hosting service like:
//   - Glitch.com
//   - Replit.com
//   - Railway.app
// ============================================================================

const express = require('express');
const bodyParser = require('body-parser');
const app = express();

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Storage for user connections
// In production, use a database. For now, in-memory storage.
const userConnections = new Map();

// ============================================================================
// CALLBACK ENDPOINT - Lovense sends callbacks here
// ============================================================================

app.post('/lovense-callback', (req, res) => {
    console.log('Received callback from Lovense:');
    console.log(JSON.stringify(req.body, null, 2));

    const { uid, utoken, domain, httpsPort, wsPort, toys, platform, appType } = req.body;

    if (!uid || !domain || !httpsPort) {
        console.error('Missing required fields in callback');
        return res.status(400).json({ error: 'Missing required fields' });
    }

    // Store connection info
    userConnections.set(uid, {
        domain,
        httpsPort,
        wsPort,
        utoken,
        toys,
        platform,
        appType,
        timestamp: Date.now()
    });

    console.log(`Stored connection for user: ${uid}`);
    console.log(`Domain: ${domain}, Port: ${httpsPort}`);

    // Respond to Lovense
    res.json({
        result: true,
        message: 'Connection saved'
    });
});

// ============================================================================
// INFO ENDPOINT - LSL queries this to get connection info
// ============================================================================

app.get('/get-connection/:uid', (req, res) => {
    const uid = req.params.uid;
    const connection = userConnections.get(uid);

    if (!connection) {
        return res.status(404).json({
            result: false,
            message: 'User not found. Have they scanned the QR code?'
        });
    }

    res.json({
        result: true,
        data: {
            domain: connection.domain,
            httpsPort: connection.httpsPort,
            wsPort: connection.wsPort,
            timestamp: connection.timestamp
        }
    });
});

// ============================================================================
// STATUS ENDPOINT - Check if server is running
// ============================================================================

app.get('/status', (req, res) => {
    res.json({
        status: 'online',
        connectedUsers: userConnections.size,
        timestamp: Date.now()
    });
});

// ============================================================================
// LIST ENDPOINT - See all connected users (for debugging)
// ============================================================================

app.get('/list-connections', (req, res) => {
    const connections = [];
    userConnections.forEach((value, key) => {
        connections.push({
            uid: key,
            domain: value.domain,
            port: value.httpsPort,
            timestamp: value.timestamp
        });
    });

    res.json({
        count: connections.length,
        connections
    });
});

// ============================================================================
// CLEANUP - Remove old connections (optional)
// ============================================================================

// Clean up connections older than 24 hours
setInterval(() => {
    const now = Date.now();
    const maxAge = 24 * 60 * 60 * 1000; // 24 hours

    userConnections.forEach((value, key) => {
        if (now - value.timestamp > maxAge) {
            console.log(`Removing old connection for user: ${key}`);
            userConnections.delete(key);
        }
    });
}, 60 * 60 * 1000); // Run every hour

// ============================================================================
// START SERVER
// ============================================================================

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log('═══════════════════════════════════════════════════════');
    console.log('Lovense QR Code Callback Receiver');
    console.log('═══════════════════════════════════════════════════════');
    console.log(`Server running on port ${PORT}`);
    console.log('');
    console.log('Endpoints:');
    console.log(`  POST   /lovense-callback          (for Lovense callbacks)`);
    console.log(`  GET    /get-connection/:uid       (for LSL to query)`);
    console.log(`  GET    /status                    (server status)`);
    console.log(`  GET    /list-connections          (debug: list all)`);
    console.log('');
    console.log('Set this as your callback URL in Lovense developer portal:');
    console.log(`  https://your-domain.com/lovense-callback`);
    console.log('═══════════════════════════════════════════════════════');
});

// ============================================================================
// DEPLOYMENT NOTES
// ============================================================================

/*
OPTION 1: Deploy to Glitch (Free, Easy)
---------------------------------------
1. Go to https://glitch.com
2. Create new Node.js project
3. Paste this code into server.js
4. Add to package.json dependencies:
   {
     "express": "^4.18.2",
     "body-parser": "^1.20.2"
   }
5. Your URL: https://your-project.glitch.me/lovense-callback
6. Set that as callback URL in Lovense developer portal

OPTION 2: Deploy to Replit (Free)
----------------------------------
1. Go to https://replit.com
2. Create new Node.js repl
3. Paste this code
4. Click "Run"
5. Your URL: https://your-repl.replit.app/lovense-callback

OPTION 3: Deploy to Railway (Free tier available)
--------------------------------------------------
1. Go to https://railway.app
2. New Project → Deploy from GitHub
3. Push this code to GitHub
4. Railway auto-deploys
5. Get your URL from Railway dashboard

OPTION 4: Your own server
--------------------------
1. Install Node.js
2. Run: npm install express body-parser
3. Run: node qr-callback-receiver.js
4. Use ngrok or similar for HTTPS:
   ngrok http 3000
5. Use ngrok URL as callback

IMPORTANT: Callback URL MUST be HTTPS!
*/
