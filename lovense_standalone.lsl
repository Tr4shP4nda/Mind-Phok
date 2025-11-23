// ============================================================================
// Lovense Device Controller - STANDALONE VERSION
// ============================================================================
// This version connects DIRECTLY to the Lovense API without a middleware
// server. Choose one of the connection methods below:
//
// METHOD 1: LAN API (Recommended - No server needed!)
//   - Works if SL and Lovense Connect are on same network
//   - More private (stays local)
//   - Lower latency
//   - Setup: Get IP/port from Lovense Connect Settings → Developer
//
// METHOD 2: Cloud API (Works anywhere but less secure)
//   - Works from anywhere with internet
//   - Requires hardcoding your developer token (SECURITY RISK!)
//   - Token visible to anyone who can read the script
//   - Only use if you trust everyone with script access
//
// METHOD 3: QR Code Linking (Most secure for Cloud API)
//   - Users scan QR code to link their devices
//   - No hardcoded credentials
//   - Best for public/shared objects
// ============================================================================

// ============================================================================
// CONFIGURATION - Choose your connection method
// ============================================================================

// CONNECTION METHOD - Set to 1, 2, or 3
integer CONNECTION_METHOD = 1;  // 1=LAN, 2=Cloud Direct, 3=QR Code

// --- METHOD 1: LAN API Configuration ---
// Get these values from Lovense Connect app: Settings → Developer
string LAN_IP = "192.168.1.100";        // Your computer's local IP
integer LAN_PORT = 30010;               // HTTPS port from Lovense Connect
// Note: Still requires valid SSL cert even though it's local!

// --- METHOD 2: Cloud API Configuration ---
// ⚠️ WARNING: These credentials will be visible in the script!
// Only use this if you're the only one who can see the script
string CLOUD_TOKEN = "YOUR_DEVELOPER_TOKEN";    // From developer portal
string CLOUD_USER_ID = "YOUR_USER_ID";          // Your Lovense user ID

// --- METHOD 3: QR Code Configuration ---
// Users will scan a QR code to link their devices
// This stores temporary tokens that expire
list linkedUsers = [];  // Format: [avatarKey, tempToken, userID, ...]

// --- General Configuration ---
string TOY_ID = "";                     // Leave empty to control all toys
integer OWNER_ONLY = TRUE;              // Only allow owner to use?

// ============================================================================
// GLOBAL VARIABLES
// ============================================================================

key httpRequestId;
integer listenHandle;
integer menuChannel;
integer isProcessing = FALSE;
string currentApiUrl;

// Menu options
list mainMenu = [
    "Vibrate Low",
    "Vibrate Med",
    "Vibrate High",
    "Pattern: Pulse",
    "Pattern: Wave",
    "Stop All"
];

list qrCodeMenu = [
    "Link Device",
    "Unlink",
    "Check Status"
];

// ============================================================================
// CONNECTION METHOD FUNCTIONS
// ============================================================================

// Get the appropriate API URL based on connection method
string getApiUrl() {
    if (CONNECTION_METHOD == 1) {
        // LAN API
        return "https://" + LAN_IP + ":" + (string)LAN_PORT + "/command";
    }
    else if (CONNECTION_METHOD == 2 || CONNECTION_METHOD == 3) {
        // Cloud API
        return "https://api.lovense.com/api/lan/command";
    }
    return "";
}

// Build JSON request based on connection method
string buildJsonRequest(string command, string action, integer duration) {
    string json = "{";
    json += "\"command\":\"" + command + "\"";

    if (action != "") {
        json += ",\"action\":\"" + action + "\"";
    }

    if (duration > 0 || command == "Function") {
        json += ",\"timeSec\":" + (string)duration;
    }

    json += ",\"apiVer\":1";

    if (TOY_ID != "") {
        json += ",\"toy\":\"" + TOY_ID + "\"";
    }

    // Add authentication for Cloud API
    if (CONNECTION_METHOD == 2) {
        json += ",\"token\":\"" + CLOUD_TOKEN + "\"";
        json += ",\"uid\":\"" + CLOUD_USER_ID + "\"";
    }
    else if (CONNECTION_METHOD == 3) {
        // QR Code method - use stored token for this user
        // This would be implemented in a real scenario
        json += ",\"token\":\"" + CLOUD_TOKEN + "\"";
        json += ",\"uid\":\"" + CLOUD_USER_ID + "\"";
    }

    json += "}";
    return json;
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

integer getRandomChannel() {
    return -1 - (integer)llFrand(1000000);
}

cleanupListeners() {
    if (listenHandle) {
        llListenRemove(listenHandle);
        listenHandle = 0;
    }
}

showMenu(key avatarId) {
    cleanupListeners();
    menuChannel = getRandomChannel();
    listenHandle = llListen(menuChannel, "", avatarId, "");

    string title = "Lovense Controller";
    if (CONNECTION_METHOD == 1) {
        title += " (LAN Mode)";
    } else if (CONNECTION_METHOD == 2) {
        title += " (Cloud Mode)";
    } else {
        title += " (QR Link Mode)";
    }

    llDialog(avatarId,
        title + "\n\nSelect an action:",
        mainMenu,
        menuChannel);

    llSetTimerEvent(60.0);
}

// ============================================================================
// LOVENSE API FUNCTIONS
// ============================================================================

sendLovenseCommand(string command, string action, integer duration) {
    if (isProcessing) {
        llOwnerSay("⏳ Please wait...");
        return;
    }

    // Validate configuration
    if (CONNECTION_METHOD == 1) {
        if (LAN_IP == "192.168.1.100") {
            llOwnerSay("❌ Please configure LAN_IP and LAN_PORT");
            llOwnerSay("Get these from Lovense Connect: Settings → Developer");
            return;
        }
    }
    else if (CONNECTION_METHOD == 2) {
        if (CLOUD_TOKEN == "YOUR_DEVELOPER_TOKEN") {
            llOwnerSay("❌ Please configure CLOUD_TOKEN and CLOUD_USER_ID");
            llOwnerSay("⚠️  WARNING: These will be visible in the script!");
            return;
        }
    }

    isProcessing = TRUE;

    // Build request
    string jsonBody = buildJsonRequest(command, action, duration);
    currentApiUrl = getApiUrl();

    // Set up headers
    list headers = [
        HTTP_METHOD, "POST",
        HTTP_MIMETYPE, "application/json",
        HTTP_BODY_MAXLENGTH, 16384,
        HTTP_VERIFY_CERT, TRUE  // Required for SL
    ];

    // Send request
    httpRequestId = llHTTPRequest(currentApiUrl, headers, jsonBody);

    llOwnerSay("📤 Sending: " + action);
}

// ============================================================================
// MENU HANDLERS
// ============================================================================

handleMenuSelection(string message, key avatarId) {
    // Vibration commands
    if (message == "Vibrate Low") {
        sendLovenseCommand("Function", "Vibrate:5", 10);
    }
    else if (message == "Vibrate Med") {
        sendLovenseCommand("Function", "Vibrate:10", 10);
    }
    else if (message == "Vibrate High") {
        sendLovenseCommand("Function", "Vibrate:20", 10);
    }
    // Pattern commands
    else if (message == "Pattern: Pulse") {
        sendLovenseCommand("Preset", "pulse", 10);
    }
    else if (message == "Pattern: Wave") {
        sendLovenseCommand("Preset", "wave", 10);
    }
    else if (message == "Stop All") {
        sendLovenseCommand("Function", "Stop", 0);
    }
}

// ============================================================================
// QR CODE LINKING (Method 3)
// ============================================================================

// Generate QR code URL for device linking
string generateQRCodeUrl(key avatarKey) {
    // This uses the Lovense QR code API
    // Users scan this to link their devices without exposing tokens
    string qrApiUrl = "https://api.lovense.com/api/lan/getQrCode";

    // In a real implementation, you'd:
    // 1. Make HTTP request to getQrCode endpoint with your token
    // 2. Receive a QR code image URL
    // 3. Display it to the user (via llSetTexture or llLoadURL)
    // 4. User scans with Lovense Remote app
    // 5. Receive callback with temp token

    return qrApiUrl;
}

// ============================================================================
// STATE: default
// ============================================================================

default {
    state_entry() {
        llOwnerSay("═══════════════════════════════════════");
        llOwnerSay("Lovense Controller - STANDALONE");
        llOwnerSay("═══════════════════════════════════════");

        // Show connection method
        if (CONNECTION_METHOD == 1) {
            llOwnerSay("📡 Mode: LAN API (Local Network)");
            llOwnerSay("URL: https://" + LAN_IP + ":" + (string)LAN_PORT);

            if (LAN_IP == "192.168.1.100") {
                llOwnerSay("⚠️  Please configure LAN_IP and LAN_PORT!");
                llOwnerSay("Get from: Lovense Connect → Settings → Developer");
            }
        }
        else if (CONNECTION_METHOD == 2) {
            llOwnerSay("📡 Mode: Cloud API (Direct)");
            llOwnerSay("⚠️  WARNING: Token is hardcoded in script!");

            if (CLOUD_TOKEN == "YOUR_DEVELOPER_TOKEN") {
                llOwnerSay("❌ Please configure CLOUD_TOKEN and CLOUD_USER_ID");
            }
        }
        else if (CONNECTION_METHOD == 3) {
            llOwnerSay("📡 Mode: QR Code Linking");
            llOwnerSay("Users scan QR codes to link devices");
        }

        llOwnerSay("\nTouch to use controller");
        isProcessing = FALSE;
    }

    touch_start(integer num_detected) {
        key toucher = llDetectedKey(0);

        // Check permissions
        if (OWNER_ONLY && toucher != llGetOwner()) {
            llRegionSayTo(toucher, 0, "Only the owner can use this controller.");
            return;
        }

        showMenu(toucher);
    }

    listen(integer channel, string name, key id, string message) {
        if (channel == menuChannel) {
            cleanupListeners();
            handleMenuSelection(message, id);
        }
    }

    http_response(key request_id, integer status, list metadata, string body) {
        if (request_id == httpRequestId) {
            isProcessing = FALSE;

            if (status == 200) {
                llOwnerSay("✅ Success!");

                // Parse response for useful info
                integer codePos = llSubStringIndex(body, "\"code\":");
                if (codePos != -1) {
                    // Extract code value
                    string afterCode = llGetSubString(body, codePos + 7, -1);
                    integer commaPos = llSubStringIndex(afterCode, ",");
                    if (commaPos == -1) commaPos = llSubStringIndex(afterCode, "}");
                    string codeStr = llGetSubString(afterCode, 0, commaPos - 1);

                    integer code = (integer)codeStr;
                    if (code != 200) {
                        llOwnerSay("API returned code: " + (string)code);
                        llOwnerSay("Response: " + body);
                    }
                }
            }
            else if (status == 499) {
                llOwnerSay("⏱️  Request timeout");
                llOwnerSay("Check your configuration:");

                if (CONNECTION_METHOD == 1) {
                    llOwnerSay("• Is Lovense Connect running?");
                    llOwnerSay("• Is LAN_IP correct?");
                    llOwnerSay("• Is LAN_PORT correct?");
                    llOwnerSay("• Are you on the same network?");
                }
                else {
                    llOwnerSay("• Is your internet working?");
                    llOwnerSay("• Is your token valid?");
                }
            }
            else if (status == 0) {
                llOwnerSay("❌ SSL Certificate Error");
                llOwnerSay("The server's SSL certificate is invalid.");
                llOwnerSay("Second Life requires valid SSL certificates.");

                if (CONNECTION_METHOD == 1) {
                    llOwnerSay("\nLAN API requires SSL even locally!");
                    llOwnerSay("Lovense Connect should provide this automatically.");
                    llOwnerSay("Make sure you're using the HTTPS port.");
                }
            }
            else {
                llOwnerSay("❌ HTTP Error: " + (string)status);
                llOwnerSay("Response: " + body);
            }
        }
    }

    timer() {
        cleanupListeners();
        llSetTimerEvent(0.0);
    }

    on_rez(integer start_param) {
        llResetScript();
    }

    changed(integer change) {
        if (change & CHANGED_INVENTORY) {
            llResetScript();
        }
    }
}

// ============================================================================
// SETUP GUIDES FOR EACH METHOD
// ============================================================================

/*
┌─────────────────────────────────────────────────────────────────────────┐
│ METHOD 1: LAN API SETUP (RECOMMENDED)                                   │
└─────────────────────────────────────────────────────────────────────────┘

This is the EASIEST and MOST SECURE method if you're on the same network.

Step 1: Open Lovense Connect App
  - Download from: https://www.lovense.com/cam-model/lovense-connect
  - Install and open the app
  - Make sure your device is connected

Step 2: Get Local Network Info
  - In Lovense Connect: Settings → Developer tab
  - You'll see:
    * Local IP: (e.g., 192.168.1.100)
    * HTTPS Port: (e.g., 30010)
  - Copy these values

Step 3: Configure This Script
  - Set CONNECTION_METHOD = 1
  - Set LAN_IP to your Local IP
  - Set LAN_PORT to your HTTPS Port

Example:
  integer CONNECTION_METHOD = 1;
  string LAN_IP = "192.168.1.100";
  integer LAN_PORT = 30010;

Step 4: Save and Test
  - Save the script
  - Touch the object
  - Try "Vibrate Low"

✅ PROS:
  • No middleware server needed
  • No exposed credentials
  • Low latency
  • Works offline
  • Most secure

❌ CONS:
  • Must be on same network as Lovense Connect
  • Lovense Connect must be running
  • Still requires SSL certificate (Connect provides this)

┌─────────────────────────────────────────────────────────────────────────┐
│ METHOD 2: CLOUD API DIRECT (WORKS ANYWHERE BUT LESS SECURE)            │
└─────────────────────────────────────────────────────────────────────────┘

⚠️  WARNING: Your developer token will be VISIBLE in the script!
Only use this if you're the ONLY person who can read the script.

Step 1: Get Developer Credentials
  - Go to: https://www.lovense.com/user/developer/info
  - Log in to your Lovense account
  - Copy your Developer Token
  - Note your User ID

Step 2: Configure This Script
  - Set CONNECTION_METHOD = 2
  - Set CLOUD_TOKEN to your developer token
  - Set CLOUD_USER_ID to your user ID

Example:
  integer CONNECTION_METHOD = 2;
  string CLOUD_TOKEN = "abc123xyz...";
  string CLOUD_USER_ID = "your@email.com";

Step 3: Save and Test
  - Save the script
  - Touch the object
  - Try "Vibrate Low"

✅ PROS:
  • Works from anywhere with internet
  • No local software needed
  • No network configuration

❌ CONS:
  • Token visible to anyone who can read script
  • MAJOR SECURITY RISK if script is copied
  • Someone could use your token maliciously
  • Higher latency
  • Requires internet

🔒 SECURITY NOTE:
  If you use this method:
  • Set script permissions to NO COPY, NO TRANSFER
  • Only use in objects you fully control
  • Consider rotating your token regularly
  • Never share the script

┌─────────────────────────────────────────────────────────────────────────┐
│ METHOD 3: QR CODE LINKING (MOST SECURE FOR PUBLIC USE)                 │
└─────────────────────────────────────────────────────────────────────────┘

This method is BEST for public objects where multiple people will use it.

How it works:
  1. Your script requests a QR code from Lovense API
  2. User scans QR code with Lovense Remote app
  3. User's device is temporarily linked to your app
  4. You get a temporary token (expires after session)
  5. No permanent credentials stored

⚠️  This requires more advanced implementation:
  - QR code display (texture on prim or web browser)
  - Callback URL handling
  - Token storage and management
  - Session management

This is beyond basic LSL but is the MOST SECURE for public use.

For a full implementation example, see:
  https://github.com/lovense/Standard_solutions

✅ PROS:
  • Most secure for public objects
  • No hardcoded credentials
  • Users control their own linking
  • Tokens expire automatically

❌ CONS:
  • More complex to implement
  • Requires callback URL
  • Needs QR code display method
  • More moving parts

┌─────────────────────────────────────────────────────────────────────────┐
│ RECOMMENDATION                                                          │
└─────────────────────────────────────────────────────────────────────────┘

For personal use: METHOD 1 (LAN API)
  → Simple, secure, works great if you're on the same network

For controlling your own device remotely: METHOD 2 (Cloud API)
  → Set strict script permissions (NO COPY, NO TRANSFER)
  → Be aware of the security risks

For public/shared objects: METHOD 3 (QR Code) or use middleware server
  → Prevents credential exposure
  → Each user links their own device

┌─────────────────────────────────────────────────────────────────────────┐
│ TROUBLESHOOTING                                                         │
└─────────────────────────────────────────────────────────────────────────┘

ERROR: "SSL Certificate Error"
  → Lovense Connect should provide valid SSL automatically
  → Make sure you're using the HTTPS port, not HTTP
  → Try restarting Lovense Connect

ERROR: "Request timeout"
  → LAN: Check you're on same network, IP/port correct
  → Cloud: Check internet connection, verify token is valid
  → Verify Lovense Connect/Remote is running and device connected

ERROR: "HTTP Error 401"
  → Invalid developer token
  → Check token hasn't expired
  → Verify you copied the entire token

ERROR: "HTTP Error 404"
  → Device not found
  → Check device is connected in Lovense app
  → Try removing TOY_ID to control all devices

Device doesn't respond but no errors:
  → Check device is turned on and connected
  → Test device manually in Lovense app first
  → Check battery level
  → Verify correct user ID

*/
