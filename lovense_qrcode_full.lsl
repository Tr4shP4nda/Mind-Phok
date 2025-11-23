// ============================================================================
// Lovense QR Code Controller - FULL CONTROL VERSION
// ============================================================================
// Complete control interface with all vibration intensities, patterns,
// and advanced features for testing and use.
// ============================================================================

// ============================================================================
// CONFIGURATION
// ============================================================================

string DEVELOPER_TOKEN = "YOUR_DEVELOPER_TOKEN_HERE";
string CALLBACK_URL = "https://webhook.site/your-unique-id";

// ============================================================================
// GLOBAL VARIABLES
// ============================================================================

key httpRequestId;
integer listenHandle;
integer menuChannel;
integer isProcessing = FALSE;

// Storage for linked users: [avatarKey, domain, httpsPort, ...]
list linkedUsers = [];

string currentQrCode = "";
key currentLinkingUser;
key currentMenuUser;  // Track who opened which menu

// Menu definitions
list mainMenuButtons = [
    "💨 Vibrate",
    "🎵 Patterns",
    "⚡ Quick",
    "🎮 Advanced",
    "🔗 Link",
    "⏹️ STOP",
    "ℹ️ Info",
    "❌ Unlink"
];

list vibrateMenuButtons = [
    "Level 1", "Level 5", "Level 10",
    "Level 12", "Level 15", "Level 20",
    "⬅️ Back", "⏹️ Stop"
];

list patternMenuButtons = [
    "Pulse",
    "Wave",
    "Fireworks",
    "Earthquake",
    "⬅️ Back",
    "⏹️ Stop"
];

list quickMenuButtons = [
    "Quick Low",
    "Quick Med",
    "Quick High",
    "Quick Pulse",
    "⬅️ Back",
    "⏹️ Stop"
];

list advancedMenuButtons = [
    "Rotate",
    "Pump",
    "Multi",
    "Custom",
    "⬅️ Back",
    "⏹️ Stop"
];

// ============================================================================
// QR CODE FUNCTIONS
// ============================================================================

string generateUniqueToken(key avatarKey) {
    string timestamp = (string)llGetUnixTime();
    string avatarStr = (string)avatarKey;
    return llGetSubString(llMD5String(avatarStr + timestamp, 0), 0, 15);
}

requestQrCode(key avatarKey) {
    if (DEVELOPER_TOKEN == "YOUR_DEVELOPER_TOKEN_HERE") {
        llRegionSayTo(avatarKey, 0, "❌ Developer token not configured!");
        return;
    }

    currentLinkingUser = avatarKey;
    string avatarName = llKey2Name(avatarKey);
    string uniqueToken = generateUniqueToken(avatarKey);

    string json = "{";
    json += "\"token\":\"" + DEVELOPER_TOKEN + "\"";
    json += ",\"uid\":\"" + (string)avatarKey + "\"";
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

integer isUserLinked(key avatarKey) {
    return (llListFindList(linkedUsers, [(string)avatarKey]) != -1);
}

list getUserConnection(key avatarKey) {
    integer index = llListFindList(linkedUsers, [(string)avatarKey]);
    if (index == -1) return [];
    return [
        llList2String(linkedUsers, index + 1),  // domain
        llList2String(linkedUsers, index + 2)   // port
    ];
}

storeUserConnection(key avatarKey, string domain, string port) {
    integer index = llListFindList(linkedUsers, [(string)avatarKey]);
    if (index != -1) {
        linkedUsers = llDeleteSubList(linkedUsers, index, index + 2);
    }
    linkedUsers += [(string)avatarKey, domain, port];
    llRegionSayTo(avatarKey, 0, "✅ Device linked successfully!");
    llRegionSayTo(avatarKey, 0, "Touch again to open control menu.");
}

unlinkUser(key avatarKey) {
    integer index = llListFindList(linkedUsers, [(string)avatarKey]);
    if (index != -1) {
        linkedUsers = llDeleteSubList(linkedUsers, index, index + 2);
        llRegionSayTo(avatarKey, 0, "✅ Device unlinked.");
    } else {
        llRegionSayTo(avatarKey, 0, "You don't have a linked device.");
    }
}

// ============================================================================
// CONTROL FUNCTIONS
// ============================================================================

sendCommand(key avatarKey, string command, string action, integer timeSec) {
    list connection = getUserConnection(avatarKey);
    if (llGetListLength(connection) == 0) {
        llRegionSayTo(avatarKey, 0, "❌ Device not linked!");
        return;
    }

    string domain = llList2String(connection, 0);
    string port = llList2String(connection, 1);
    string url = "https://" + domain + ":" + port + "/command";

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

    // Give user feedback
    if (action == "Stop") {
        llRegionSayTo(avatarKey, 0, "⏹️ Stopping...");
    } else if (command == "Preset") {
        llRegionSayTo(avatarKey, 0, "🎵 Starting pattern: " + action);
    } else {
        llRegionSayTo(avatarKey, 0, "📤 " + action + " (" + (string)timeSec + "s)");
    }
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

showMenu(key avatarKey, list buttons, string title) {
    cleanupListeners();
    menuChannel = getRandomChannel();
    listenHandle = llListen(menuChannel, "", avatarKey, "");
    currentMenuUser = avatarKey;

    llDialog(avatarKey, title, buttons, menuChannel);
    llSetTimerEvent(60.0);
}

showMainMenu(key avatarKey) {
    string title = "🎮 Lovense Controller\n\n";
    if (isUserLinked(avatarKey)) {
        title += "✅ Device linked and ready!\n\nChoose control:";
    } else {
        title += "❌ No device linked\n\nLink your device first:";
    }
    showMenu(avatarKey, mainMenuButtons, title);
}

showVibrateMenu(key avatarKey) {
    string title = "💨 VIBRATE INTENSITY\n\n";
    title += "Select intensity level (1-20)\n";
    title += "Duration: 15 seconds";
    showMenu(avatarKey, vibrateMenuButtons, title);
}

showPatternMenu(key avatarKey) {
    string title = "🎵 PRESET PATTERNS\n\n";
    title += "Select a built-in pattern\n";
    title += "Duration: 20 seconds";
    showMenu(avatarKey, patternMenuButtons, title);
}

showQuickMenu(key avatarKey) {
    string title = "⚡ QUICK CONTROLS\n\n";
    title += "One-tap shortcuts\n";
    title += "Quick Low: 5/20 for 10s\n";
    title += "Quick Med: 10/20 for 10s\n";
    title += "Quick High: 20/20 for 10s";
    showMenu(avatarKey, quickMenuButtons, title);
}

showAdvancedMenu(key avatarKey) {
    string title = "🎮 ADVANCED CONTROLS\n\n";
    title += "Special functions and combinations\n";
    title += "(Not all toys support all functions)";
    showMenu(avatarKey, advancedMenuButtons, title);
}

// ============================================================================
// MENU HANDLERS
// ============================================================================

handleMainMenu(string message, key avatarKey) {
    if (message == "💨 Vibrate") {
        showVibrateMenu(avatarKey);
    }
    else if (message == "🎵 Patterns") {
        showPatternMenu(avatarKey);
    }
    else if (message == "⚡ Quick") {
        showQuickMenu(avatarKey);
    }
    else if (message == "🎮 Advanced") {
        showAdvancedMenu(avatarKey);
    }
    else if (message == "🔗 Link") {
        requestQrCode(avatarKey);
    }
    else if (message == "⏹️ STOP") {
        sendCommand(avatarKey, "Function", "Stop", 0);
    }
    else if (message == "ℹ️ Info") {
        if (isUserLinked(avatarKey)) {
            list conn = getUserConnection(avatarKey);
            llRegionSayTo(avatarKey, 0, "═══════════════════════════════");
            llRegionSayTo(avatarKey, 0, "DEVICE INFO");
            llRegionSayTo(avatarKey, 0, "═══════════════════════════════");
            llRegionSayTo(avatarKey, 0, "Status: ✅ Linked");
            llRegionSayTo(avatarKey, 0, "Connection: " + llList2String(conn, 0));
            llRegionSayTo(avatarKey, 0, "Port: " + llList2String(conn, 1));
        } else {
            llRegionSayTo(avatarKey, 0, "Status: ❌ Not linked");
        }
        showMainMenu(avatarKey);
    }
    else if (message == "❌ Unlink") {
        unlinkUser(avatarKey);
        showMainMenu(avatarKey);
    }
}

handleVibrateMenu(string message, key avatarKey) {
    if (message == "⬅️ Back") {
        showMainMenu(avatarKey);
    }
    else if (message == "⏹️ Stop") {
        sendCommand(avatarKey, "Function", "Stop", 0);
        showMainMenu(avatarKey);
    }
    else if (llSubStringIndex(message, "Level ") == 0) {
        // Extract level number
        list parts = llParseString2List(message, [" "], []);
        integer level = (integer)llList2String(parts, 1);
        sendCommand(avatarKey, "Function", "Vibrate:" + (string)level, 15);
        showVibrateMenu(avatarKey);  // Show menu again for quick testing
    }
}

handlePatternMenu(string message, key avatarKey) {
    if (message == "⬅️ Back") {
        showMainMenu(avatarKey);
    }
    else if (message == "⏹️ Stop") {
        sendCommand(avatarKey, "Function", "Stop", 0);
        showMainMenu(avatarKey);
    }
    else {
        // Pattern name (lowercase for API)
        string pattern = llToLower(message);
        sendCommand(avatarKey, "Preset", pattern, 20);
        showPatternMenu(avatarKey);  // Show menu again
    }
}

handleQuickMenu(string message, key avatarKey) {
    if (message == "⬅️ Back") {
        showMainMenu(avatarKey);
    }
    else if (message == "⏹️ Stop") {
        sendCommand(avatarKey, "Function", "Stop", 0);
        showMainMenu(avatarKey);
    }
    else if (message == "Quick Low") {
        sendCommand(avatarKey, "Function", "Vibrate:5", 10);
    }
    else if (message == "Quick Med") {
        sendCommand(avatarKey, "Function", "Vibrate:10", 10);
    }
    else if (message == "Quick High") {
        sendCommand(avatarKey, "Function", "Vibrate:20", 10);
    }
    else if (message == "Quick Pulse") {
        sendCommand(avatarKey, "Preset", "pulse", 10);
    }
}

handleAdvancedMenu(string message, key avatarKey) {
    if (message == "⬅️ Back") {
        showMainMenu(avatarKey);
    }
    else if (message == "⏹️ Stop") {
        sendCommand(avatarKey, "Function", "Stop", 0);
        showMainMenu(avatarKey);
    }
    else if (message == "Rotate") {
        sendCommand(avatarKey, "Function", "Rotate:10", 15);
        llRegionSayTo(avatarKey, 0, "Note: Only Nora supports rotation");
    }
    else if (message == "Pump") {
        sendCommand(avatarKey, "Function", "Pump:2", 10);
        llRegionSayTo(avatarKey, 0, "Note: Only Max series supports pump");
    }
    else if (message == "Multi") {
        sendCommand(avatarKey, "Function", "Vibrate:10,Rotate:5", 15);
        llRegionSayTo(avatarKey, 0, "Multi-action (vibrate + rotate)");
    }
    else if (message == "Custom") {
        llRegionSayTo(avatarKey, 0, "Custom patterns coming soon!");
        llRegionSayTo(avatarKey, 0, "For now, use the preset patterns.");
    }
}

// Main menu router
handleMenuSelection(string message, key avatarKey) {
    // Determine which menu we're in based on the message
    if (llListFindList(mainMenuButtons, [message]) != -1) {
        handleMainMenu(message, avatarKey);
    }
    else if (llListFindList(vibrateMenuButtons, [message]) != -1) {
        handleVibrateMenu(message, avatarKey);
    }
    else if (llListFindList(patternMenuButtons, [message]) != -1) {
        handlePatternMenu(message, avatarKey);
    }
    else if (llListFindList(quickMenuButtons, [message]) != -1) {
        handleQuickMenu(message, avatarKey);
    }
    else if (llListFindList(advancedMenuButtons, [message]) != -1) {
        handleAdvancedMenu(message, avatarKey);
    }
}

// ============================================================================
// STATES
// ============================================================================

default {
    state_entry() {
        llOwnerSay("═══════════════════════════════════════");
        llOwnerSay("Lovense QR Code Controller - FULL");
        llOwnerSay("═══════════════════════════════════════");
        llOwnerSay("Touch to open control menu");

        // Listen for manual link commands
        llListen(99, "", NULL_KEY, "");
    }

    touch_start(integer num_detected) {
        key toucher = llDetectedKey(0);
        showMainMenu(toucher);
    }

    listen(integer channel, string name, key id, string message) {
        if (channel == menuChannel && id == currentMenuUser) {
            cleanupListeners();
            handleMenuSelection(message, id);
        }
        else if (channel == 99) {
            // Manual link: /99 link <domain> <port>
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
            // Check if this is a QR code response
            integer qrPos = llSubStringIndex(body, "\"qr\":\"");
            if (qrPos != -1) {
                string afterQr = llGetSubString(body, qrPos + 6, -1);
                integer endPos = llSubStringIndex(afterQr, "\"");
                currentQrCode = llGetSubString(afterQr, 0, endPos - 1);

                llRegionSayTo(currentLinkingUser, 0, "✅ QR Code ready!");
                llLoadURL(currentLinkingUser, "Scan with Lovense Remote app", currentQrCode);

                llRegionSayTo(currentLinkingUser, 0, "\n📱 STEPS:");
                llRegionSayTo(currentLinkingUser, 0, "1. Click the link above");
                llRegionSayTo(currentLinkingUser, 0, "2. Open Lovense Remote app");
                llRegionSayTo(currentLinkingUser, 0, "3. Tap QR scanner icon");
                llRegionSayTo(currentLinkingUser, 0, "4. Scan the QR code");
                llRegionSayTo(currentLinkingUser, 0, "5. Use: /99 link <domain> <port>");
            }
            // Check if this is a command response
            else if (llSubStringIndex(body, "\"result\":true") != -1) {
                llRegionSayTo(currentMenuUser, 0, "✅ Command successful!");
            }
            else if (llSubStringIndex(body, "\"code\":200") != -1) {
                llRegionSayTo(currentMenuUser, 0, "✅ Command sent!");
            }
        }
        else {
            llOwnerSay("❌ HTTP " + (string)status + ": " + body);
        }
    }

    timer() {
        cleanupListeners();
        llSetTimerEvent(0.0);
    }
}
