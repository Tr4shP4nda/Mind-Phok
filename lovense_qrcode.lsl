// ============================================================================
// Lovense QR Code Linking Method - LSL Script
// ============================================================================
// This script uses the QR code method to link user devices without exposing
// credentials. Users scan a QR code to link their devices.
//
// SETUP REQUIRED:
// 1. Set up callback URL (see SETUP_GUIDE.md)
// 2. Configure your developer token below
// 3. Deploy and use!
// ============================================================================

// ============================================================================
// CONFIGURATION
// ============================================================================

// Your developer token (only used to generate QR codes, not exposed to users)
string DEVELOPER_TOKEN = "YOUR_DEVELOPER_TOKEN_HERE";

// Your callback URL (where Lovense sends connection info)
// This can be a simple webhook service - see setup guide
string CALLBACK_URL = "https://webhook.site/your-unique-id";

// Or if you set up the simple receiver:
// string CALLBACK_URL = "https://your-domain.com/lovense-callback";

// ============================================================================
// GLOBAL VARIABLES
// ============================================================================

key httpRequestId;
integer listenHandle;
integer menuChannel;
integer isProcessing = FALSE;

// Storage for linked users
// Format: [avatarKey, domain, httpsPort, avatarKey, domain, httpsPort, ...]
list linkedUsers = [];

// Current QR code info
string currentQrCode = "";
key currentLinkingUser;

// ============================================================================
// QR CODE LINKING FUNCTIONS
// ============================================================================

// Generate a unique token for this linking session
string generateUniqueToken(key avatarKey) {
    // Create a unique token using avatar key and timestamp
    string timestamp = (string)llGetUnixTime();
    string avatarStr = (string)avatarKey;

    // Simple hash (you can make this more complex)
    string token = llGetSubString(llMD5String(avatarStr + timestamp, 0), 0, 15);
    return token;
}

// Request a QR code for a user to scan
requestQrCode(key avatarKey) {
    if (DEVELOPER_TOKEN == "YOUR_DEVELOPER_TOKEN_HERE") {
        llRegionSayTo(avatarKey, 0, "❌ Developer token not configured!");
        return;
    }

    currentLinkingUser = avatarKey;
    string avatarName = llKey2Name(avatarKey);
    string uniqueToken = generateUniqueToken(avatarKey);

    // Build the request
    string json = "{";
    json += "\"token\":\"" + DEVELOPER_TOKEN + "\"";
    json += ",\"uid\":\"" + (string)avatarKey + "\"";  // Use avatar UUID as UID
    json += ",\"uname\":\"" + avatarName + "\"";
    json += ",\"utoken\":\"" + uniqueToken + "\"";
    json += ",\"v\":2";
    json += "}";

    list headers = [
        HTTP_METHOD, "POST",
        HTTP_MIMETYPE, "application/json",
        HTTP_BODY_MAXLENGTH, 16384,
        HTTP_VERIFY_CERT, TRUE
    ];

    llRegionSayTo(avatarKey, 0, "📱 Requesting QR code...");
    httpRequestId = llHTTPRequest("https://api.lovense.com/api/lan/getQrCode", headers, json);
    isProcessing = TRUE;
}

// Check if a user is already linked
integer isUserLinked(key avatarKey) {
    integer index = llListFindList(linkedUsers, [(string)avatarKey]);
    return (index != -1);
}

// Get connection info for a linked user
list getUserConnection(key avatarKey) {
    integer index = llListFindList(linkedUsers, [(string)avatarKey]);
    if (index == -1) return [];

    // Return [domain, port]
    return [
        llList2String(linkedUsers, index + 1),  // domain
        llList2String(linkedUsers, index + 2)   // port
    ];
}

// Store user connection info (manually entered or from callback)
storeUserConnection(key avatarKey, string domain, string port) {
    // Remove if already exists
    integer index = llListFindList(linkedUsers, [(string)avatarKey]);
    if (index != -1) {
        linkedUsers = llDeleteSubList(linkedUsers, index, index + 2);
    }

    // Add new entry
    linkedUsers += [(string)avatarKey, domain, port];

    llRegionSayTo(avatarKey, 0, "✅ Device linked successfully!");
    llRegionSayTo(avatarKey, 0, "You can now use the controller.");
}

// ============================================================================
// DEVICE CONTROL FUNCTIONS
// ============================================================================

sendCommandToUser(key avatarKey, string command, string action, integer timeSec) {
    list connection = getUserConnection(avatarKey);
    if (llGetListLength(connection) == 0) {
        llRegionSayTo(avatarKey, 0, "❌ Device not linked. Please link first!");
        return;
    }

    string domain = llList2String(connection, 0);
    string port = llList2String(connection, 1);
    string url = "https://" + domain + ":" + port + "/command";

    // Build command
    string json = "{";
    json += "\"command\":\"" + command + "\"";
    if (action != "") {
        json += ",\"action\":\"" + action + "\"";
    }
    json += ",\"timeSec\":" + (string)timeSec;
    json += ",\"apiVer\":1";
    json += "}";

    list headers = [
        HTTP_METHOD, "POST",
        HTTP_MIMETYPE, "application/json",
        HTTP_VERIFY_CERT, TRUE
    ];

    httpRequestId = llHTTPRequest(url, headers, json);
    llRegionSayTo(avatarKey, 0, "📤 Sending: " + action);
}

// ============================================================================
// MENU FUNCTIONS
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

showMainMenu(key avatarKey) {
    cleanupListeners();
    menuChannel = getRandomChannel();
    listenHandle = llListen(menuChannel, "", avatarKey, "");

    list buttons;
    if (isUserLinked(avatarKey)) {
        buttons = [
            "Vibrate Low",
            "Vibrate Med",
            "Vibrate High",
            "Pattern: Pulse",
            "Pattern: Wave",
            "Stop",
            "Unlink Device",
            "Status"
        ];
    } else {
        buttons = [
            "Link Device",
            "Manual Setup",
            "Help"
        ];
    }

    llDialog(avatarKey,
        "Lovense Controller (QR Code Method)\n\nSelect an action:",
        buttons,
        menuChannel);

    llSetTimerEvent(60.0);
}

handleMenuSelection(string message, key avatarKey) {
    if (message == "Link Device") {
        requestQrCode(avatarKey);
    }
    else if (message == "Manual Setup") {
        llRegionSayTo(avatarKey, 0, "After scanning the QR code in another method,");
        llRegionSayTo(avatarKey, 0, "you'll receive connection info (domain and port).");
        llRegionSayTo(avatarKey, 0, "Type in chat: /99 link <domain> <port>");
        llRegionSayTo(avatarKey, 0, "Example: /99 link 192-168-1-100.lovense.club 30010");
    }
    else if (message == "Unlink Device") {
        integer index = llListFindList(linkedUsers, [(string)avatarKey]);
        if (index != -1) {
            linkedUsers = llDeleteSubList(linkedUsers, index, index + 2);
            llRegionSayTo(avatarKey, 0, "✅ Device unlinked.");
        }
        showMainMenu(avatarKey);
    }
    else if (message == "Help") {
        llRegionSayTo(avatarKey, 0, "═══════════════════════════════════════");
        llRegionSayTo(avatarKey, 0, "QR CODE LINKING HELP");
        llRegionSayTo(avatarKey, 0, "═══════════════════════════════════════");
        llRegionSayTo(avatarKey, 0, "1. Click 'Link Device'");
        llRegionSayTo(avatarKey, 0, "2. Click the link to open QR code");
        llRegionSayTo(avatarKey, 0, "3. Scan with Lovense Remote app");
        llRegionSayTo(avatarKey, 0, "4. Connection info auto-saved (if webhook set up)");
        llRegionSayTo(avatarKey, 0, "   OR use Manual Setup to enter info");
    }
    // Control commands
    else if (message == "Vibrate Low") {
        sendCommandToUser(avatarKey, "Function", "Vibrate:5", 10);
    }
    else if (message == "Vibrate Med") {
        sendCommandToUser(avatarKey, "Function", "Vibrate:10", 10);
    }
    else if (message == "Vibrate High") {
        sendCommandToUser(avatarKey, "Function", "Vibrate:20", 10);
    }
    else if (message == "Pattern: Pulse") {
        sendCommandToUser(avatarKey, "Preset", "pulse", 10);
    }
    else if (message == "Pattern: Wave") {
        sendCommandToUser(avatarKey, "Function", "wave", 10);
    }
    else if (message == "Stop") {
        sendCommandToUser(avatarKey, "Function", "Stop", 0);
    }
    else if (message == "Status") {
        if (isUserLinked(avatarKey)) {
            list conn = getUserConnection(avatarKey);
            llRegionSayTo(avatarKey, 0, "✅ Device linked");
            llRegionSayTo(avatarKey, 0, "Connection: " + llList2String(conn, 0));
        } else {
            llRegionSayTo(avatarKey, 0, "❌ No device linked");
        }
    }
}

// ============================================================================
// STATES
// ============================================================================

default {
    state_entry() {
        llOwnerSay("═══════════════════════════════════════");
        llOwnerSay("Lovense QR Code Controller");
        llOwnerSay("═══════════════════════════════════════");
        llOwnerSay("Touch to link your device");

        // Listen for manual setup commands
        llListen(99, "", NULL_KEY, "");
    }

    touch_start(integer num_detected) {
        key toucher = llDetectedKey(0);
        showMainMenu(toucher);
    }

    listen(integer channel, string name, key id, string message) {
        if (channel == menuChannel) {
            cleanupListeners();
            handleMenuSelection(message, id);
        }
        else if (channel == 99) {
            // Manual link command: /99 link <domain> <port>
            if (llSubStringIndex(message, "link ") == 0) {
                list parts = llParseString2List(message, [" "], []);
                if (llGetListLength(parts) >= 3) {
                    string domain = llList2String(parts, 1);
                    string port = llList2String(parts, 2);
                    storeUserConnection(id, domain, port);
                }
            }
        }
    }

    http_response(key request_id, integer status, list metadata, string body) {
        if (request_id != httpRequestId) return;

        isProcessing = FALSE;

        if (status == 200) {
            // Parse response for QR code URL
            // Response format: {"result":true,"code":200,"message":"Success","data":{"qr":"https://..."}}

            integer qrPos = llSubStringIndex(body, "\"qr\":\"");
            if (qrPos != -1) {
                string afterQr = llGetSubString(body, qrPos + 6, -1);
                integer endPos = llSubStringIndex(afterQr, "\"");
                currentQrCode = llGetSubString(afterQr, 0, endPos - 1);

                llRegionSayTo(currentLinkingUser, 0, "✅ QR Code generated!");
                llRegionSayTo(currentLinkingUser, 0, "Click the link below to see QR code:");
                llLoadURL(currentLinkingUser, "Scan this QR code with Lovense Remote app", currentQrCode);

                llRegionSayTo(currentLinkingUser, 0, "\n📱 INSTRUCTIONS:");
                llRegionSayTo(currentLinkingUser, 0, "1. Open Lovense Remote app");
                llRegionSayTo(currentLinkingUser, 0, "2. Tap 'Scan QR Code' or camera icon");
                llRegionSayTo(currentLinkingUser, 0, "3. Scan the QR code from the link");
                llRegionSayTo(currentLinkingUser, 0, "4. Connection will be saved automatically");
                llRegionSayTo(currentLinkingUser, 0, "\nOr use Manual Setup if callback not working.");
            } else {
                llRegionSayTo(currentLinkingUser, 0, "❌ Could not parse QR code");
                llRegionSayTo(currentLinkingUser, 0, "Response: " + body);
            }
        } else {
            llRegionSayTo(currentLinkingUser, 0, "❌ Error: " + (string)status);
            llRegionSayTo(currentLinkingUser, 0, "Response: " + body);
        }
    }

    timer() {
        cleanupListeners();
        llSetTimerEvent(0.0);
    }
}

// ============================================================================
// CALLBACK WEBHOOK INTEGRATION
// ============================================================================

/*
When a user scans the QR code, Lovense sends a callback to your CALLBACK_URL
with this format:

{
  "uid": "user_id_you_sent",
  "utoken": "unique_token_you_sent",
  "domain": "192-168-1-100.lovense.club",
  "httpsPort": "30010",
  "wsPort": "30010",
  "appVersion": "4.0.0",
  "toys": {
    "toy_id": {
      "nickName": "My Lush",
      "name": "lush",
      "id": "toy_id",
      "status": 1
    }
  },
  "platform": "ios",
  "appType": "remote"
}

You need to:
1. Receive this at your CALLBACK_URL
2. Parse domain and httpsPort
3. Store them for the user (by uid)
4. LSL can then use them to send commands

See the callback receiver script in the repo for a simple implementation.
*/
