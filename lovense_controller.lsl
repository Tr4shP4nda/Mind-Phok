// ============================================================================
// Lovense Device Controller for Second Life
// ============================================================================
// This script demonstrates how to control Lovense devices using their API
// from within Second Life using Linden Scripting Language (LSL).
//
// Features:
// - Touch menu interface for device control
// - Multiple vibration patterns
// - Direct intensity control
// - Stop functionality
// - Error handling and user feedback
//
// Setup Instructions:
// 1. Get your developer token from: https://www.lovense.com/user/developer/info
// 2. Set up a middleware server (see README.md) or use LAN API
// 3. Configure the constants below with your server details
// 4. Add this script to an object in Second Life
// ============================================================================

// ============================================================================
// CONFIGURATION - Modify these values for your setup
// ============================================================================

// Your middleware server URL (MUST be HTTPS with valid SSL certificate)
// Second Life requires HTTPS endpoints with valid certificates
string SERVER_URL = "https://your-server.example.com/lovense/command";

// Your Lovense developer token (get from developer dashboard)
string DEVELOPER_TOKEN = "YOUR_DEVELOPER_TOKEN_HERE";

// User ID (the Lovense user ID you want to control)
string USER_ID = "USER_ID_HERE";

// Optional: Specific toy ID (leave empty to control all toys)
string TOY_ID = "";

// ============================================================================
// GLOBAL VARIABLES
// ============================================================================

key httpRequestId;              // Stores the key from the current HTTP request
integer listenHandle;           // Handle for listen events
integer menuChannel;            // Dynamic channel for menu dialogs
integer isProcessing = FALSE;   // Prevents multiple simultaneous requests

// Menu options
list mainMenu = [
    "Vibrate Low",
    "Vibrate Med",
    "Vibrate High",
    "Pattern: Pulse",
    "Pattern: Wave",
    "Pattern: Earthquake",
    "Stop All",
    "Status"
];

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Generate a random negative channel for dialog menus
integer getRandomChannel() {
    return -1 - (integer)llFrand(1000000);
}

// Clean up any existing listeners
cleanupListeners() {
    if (listenHandle) {
        llListenRemove(listenHandle);
        listenHandle = 0;
    }
}

// Display the main control menu to a user
showMenu(key avatarId) {
    cleanupListeners();
    menuChannel = getRandomChannel();
    listenHandle = llListen(menuChannel, "", avatarId, "");

    llDialog(avatarId,
        "Lovense Device Controller\n\nSelect an action:",
        mainMenu,
        menuChannel);

    // Auto-cleanup listener after 60 seconds
    llSetTimerEvent(60.0);
}

// Build JSON string for API request
// LSL doesn't have native JSON encoding, so we build it manually
string buildJsonRequest(string command, string action, integer duration) {
    string json = "{";
    json += "\"command\":\"" + command + "\"";
    json += ",\"action\":\"" + action + "\"";
    json += ",\"timeSec\":" + (string)duration;
    json += ",\"apiVer\":1";

    // Add toy ID if specified
    if (TOY_ID != "") {
        json += ",\"toy\":\"" + TOY_ID + "\"";
    }

    // For server-based API (uncomment if using server API instead of LAN)
    // json += ",\"token\":\"" + DEVELOPER_TOKEN + "\"";
    // json += ",\"uid\":\"" + USER_ID + "\"";

    json += "}";
    return json;
}

// Send HTTP POST request to Lovense API
sendLovenseCommand(string command, string action, integer duration) {
    if (isProcessing) {
        llOwnerSay("⏳ Please wait, processing previous request...");
        return;
    }

    // Validate configuration
    if (SERVER_URL == "https://your-server.example.com/lovense/command") {
        llOwnerSay("❌ ERROR: Please configure SERVER_URL in the script");
        return;
    }

    isProcessing = TRUE;

    // Build the JSON payload
    string jsonBody = buildJsonRequest(command, action, duration);

    // Set up HTTP headers
    list headers = [
        HTTP_METHOD, "POST",
        HTTP_MIMETYPE, "application/json",
        HTTP_BODY_MAXLENGTH, 16384,
        HTTP_VERIFY_CERT, TRUE
    ];

    // Send the request
    httpRequestId = llHTTPRequest(SERVER_URL, headers, jsonBody);

    llOwnerSay("📤 Sending command: " + action);
}

// Handle menu selections
handleMenuSelection(string message, key avatarId) {
    // Vibration intensity commands
    if (message == "Vibrate Low") {
        sendLovenseCommand("Function", "Vibrate:5", 10);
    }
    else if (message == "Vibrate Med") {
        sendLovenseCommand("Function", "Vibrate:10", 10);
    }
    else if (message == "Vibrate High") {
        sendLovenseCommand("Function", "Vibrate:20", 10);
    }
    // Pattern commands (use Preset command type)
    else if (message == "Pattern: Pulse") {
        sendLovenseCommand("Preset", "pulse", 10);
    }
    else if (message == "Pattern: Wave") {
        sendLovenseCommand("Preset", "wave", 10);
    }
    else if (message == "Pattern: Earthquake") {
        sendLovenseCommand("Preset", "earthquake", 10);
    }
    // Stop all devices
    else if (message == "Stop All") {
        sendLovenseCommand("Function", "Stop", 0);
    }
    // Get device status
    else if (message == "Status") {
        sendLovenseCommand("GetToys", "", 0);
    }
}

// Parse and display HTTP response
handleHttpResponse(integer status, string body) {
    isProcessing = FALSE;

    if (status == 200) {
        // Success!
        llOwnerSay("✅ Command successful!");

        // Try to extract code from JSON response
        // Simple string parsing since LSL doesn't have JSON parsing
        integer codePos = llSubStringIndex(body, "\"code\"");
        if (codePos != -1) {
            llOwnerSay("Response: " + body);
        }
    }
    else if (status == 499) {
        // Request timeout
        llOwnerSay("⏱️ Request timed out. Check your server connection.");
    }
    else {
        // Error occurred
        llOwnerSay("❌ HTTP Error " + (string)status);
        llOwnerSay("Response: " + body);
    }
}

// ============================================================================
// STATE: default
// ============================================================================

default {
    state_entry() {
        llOwnerSay("═══════════════════════════════════════");
        llOwnerSay("Lovense Controller Initialized");
        llOwnerSay("═══════════════════════════════════════");
        llOwnerSay("Touch this object to control devices");

        // Check if configuration is set
        if (SERVER_URL == "https://your-server.example.com/lovense/command") {
            llOwnerSay("⚠️  WARNING: Server URL not configured!");
            llOwnerSay("Please edit the script and set SERVER_URL");
        }

        if (DEVELOPER_TOKEN == "YOUR_DEVELOPER_TOKEN_HERE") {
            llOwnerSay("⚠️  WARNING: Developer token not configured!");
            llOwnerSay("Get your token from: https://www.lovense.com/user/developer/info");
        }

        isProcessing = FALSE;
    }

    touch_start(integer num_detected) {
        // Show menu to the person who touched the object
        key toucher = llDetectedKey(0);

        // Only allow owner to use the controller (optional - remove this check to allow anyone)
        if (toucher == llGetOwner()) {
            showMenu(toucher);
        }
        else {
            llRegionSayTo(toucher, 0, "Only the owner can use this controller.");
        }
    }

    listen(integer channel, string name, key id, string message) {
        if (channel == menuChannel) {
            cleanupListeners();
            handleMenuSelection(message, id);
        }
    }

    http_response(key request_id, integer status, list metadata, string body) {
        // Verify this is the response we're waiting for
        if (request_id == httpRequestId) {
            handleHttpResponse(status, body);
        }
    }

    timer() {
        // Cleanup listener after timeout
        cleanupListeners();
        llSetTimerEvent(0.0);
    }

    on_rez(integer start_param) {
        // Reset script when object is rezzed
        llResetScript();
    }

    changed(integer change) {
        if (change & CHANGED_INVENTORY) {
            // Reset script if inventory changes
            llResetScript();
        }
    }
}

// ============================================================================
// ADVANCED USAGE EXAMPLES
// ============================================================================
/*
// Example 1: Custom vibration pattern
// To create a custom pattern, you would use the Pattern command with a rule string:
sendLovenseCommand("Pattern", "V:1;F:v;S:1000#", 0);
// This requires building the pattern string according to Lovense pattern syntax

// Example 2: Rotating toys
sendLovenseCommand("Function", "Rotate:10", 10);

// Example 3: Multi-action command
sendLovenseCommand("Function", "Vibrate:10,Rotate:5", 10);

// Example 4: Pump action (for specific toys)
sendLovenseCommand("Function", "Pump:2", 5);

// Example 5: Get toy information
// The response will include battery level, toy type, and connection status
sendLovenseCommand("GetToys", "", 0);
*/

// ============================================================================
// NOTES & LIMITATIONS
// ============================================================================
/*
1. SSL Certificate Requirement:
   - Second Life REQUIRES valid SSL certificates for HTTPS requests
   - Self-signed certificates will NOT work
   - Use Let's Encrypt or similar for free valid certificates

2. Middleware Server:
   - You typically need a middleware server between SL and Lovense API
   - This server handles authentication and forwards requests
   - See README.md for middleware server examples

3. LAN API Alternative:
   - If you're on the same network as the Lovense Connect app
   - You can use the LAN API directly (no server needed)
   - Get the local IP and port from Lovense Connect settings

4. Rate Limiting:
   - Be mindful of API rate limits
   - Don't spam commands too quickly
   - The script includes a simple isProcessing flag to prevent overlapping requests

5. User Privacy:
   - Always get explicit consent before controlling someone's device
   - Implement proper authentication/authorization
   - Consider adding access control lists (ACLs)

6. Testing:
   - Test with your own devices first
   - Use low intensities during initial testing
   - Implement proper error handling for production use
*/
