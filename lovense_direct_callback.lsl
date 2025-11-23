// ============================================================================
// Lovense QR Code Controller - DIRECT CALLBACK VERSION
// ============================================================================
// Uses llRequestURL() to receive Lovense callbacks directly in LSL!
// No external servers needed for callbacks!
// ============================================================================

// ============================================================================
// CONFIGURATION
// ============================================================================

string DEVELOPER_TOKEN = "YOUR_DEVELOPER_TOKEN_HERE";

// ============================================================================
// GLOBAL VARIABLES
// ============================================================================

key httpRequestId;
key qrRequestId;
key urlRequestId;

integer listenHandle;
integer menuChannel;

list linkedUsers = [];  // [avatarKey, domain, httpsPort, ...]

string currentQrCode = "";
key currentLinkingUser;
key currentMenuUser;

// Dynamic callback URL
string CALLBACK_URL = "";
integer callbackActive = FALSE;

// ============================================================================
// USER MANAGEMENT
// ============================================================================

string generateUniqueToken(key avatarKey) {
    string timestamp = (string)llGetUnixTime();
    string avatarStr = (string)avatarKey;
    return llGetSubString(llMD5String(avatarStr + timestamp, 0), 0, 15);
}

integer isUserLinked(key avatarKey) {
    return (llListFindList(linkedUsers, [(string)avatarKey]) != -1);
}

list getUserConnection(key avatarKey) {
    integer index = llListFindList(linkedUsers, [(string)avatarKey]);
    if (index == -1) return [];
    return [
        llList2String(linkedUsers, index + 1),
        llList2String(linkedUsers, index + 2)
    ];
}

storeUserConnection(key avatarKey, string domain, string port) {
    integer index = llListFindList(linkedUsers, [(string)avatarKey]);
    if (index != -1) {
        linkedUsers = llDeleteSubList(linkedUsers, index, index + 2);
    }
    linkedUsers += [(string)avatarKey, domain, port];

    llRegionSayTo(avatarKey, 0, "✅ Device linked successfully!");
    llRegionSayTo(avatarKey, 0, "📡 Connection: " + domain + ":" + port);
    llRegionSayTo(avatarKey, 0, "🎮 Touch again to use controls!");
}

unlinkUser(key avatarKey) {
    integer index = llListFindList(linkedUsers, [(string)avatarKey]);
    if (index != -1) {
        linkedUsers = llDeleteSubList(linkedUsers, index, index + 2);
        llRegionSayTo(avatarKey, 0, "✅ Device unlinked");
    }

    // If no users left, release the callback URL
    if (llGetListLength(linkedUsers) == 0 && callbackActive) {
        llReleaseURL(CALLBACK_URL);
        CALLBACK_URL = "";
        callbackActive = FALSE;
        llOwnerSay("📡 Callback URL released (no active users)");
    }
}

// ============================================================================
// CALLBACK URL MANAGEMENT
// ============================================================================

requestCallbackURL(key avatarKey) {
    currentLinkingUser = avatarKey;
    llRegionSayTo(avatarKey, 0, "📡 Setting up callback URL...");
    urlRequestId = llRequestURL();
}

// ============================================================================
// QR CODE GENERATION
// ============================================================================

requestQrCode(key avatarKey) {
    if (DEVELOPER_TOKEN == "YOUR_DEVELOPER_TOKEN_HERE") {
        llRegionSayTo(avatarKey, 0, "❌ Please configure DEVELOPER_TOKEN!");
        return;
    }

    if (!callbackActive) {
        llRegionSayTo(avatarKey, 0, "📡 First time setup - requesting callback URL...");
        requestCallbackURL(avatarKey);
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

    llRegionSayTo(avatarKey, 0, "📱 Generating QR code...");
    qrRequestId = llHTTPRequest("https://api.lovense.com/api/lan/getQrCode", headers, json);
}

// ============================================================================
// DEVICE CONTROL
// ============================================================================

sendCommand(key avatarKey, string command, string action, integer timeSec) {
    list connection = getUserConnection(avatarKey);
    if (llGetListLength(connection) == 0) {
        llRegionSayTo(avatarKey, 0, "❌ Device not linked! Link first.");
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

    if (action == "Stop") {
        llRegionSayTo(avatarKey, 0, "⏹️ Stopping...");
    } else if (command == "Preset") {
        llRegionSayTo(avatarKey, 0, "🎵 " + action);
    } else {
        llRegionSayTo(avatarKey, 0, "📤 " + action);
    }
}

// ============================================================================
// MENU SYSTEM
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
    currentMenuUser = avatarKey;

    list buttons;
    string title = "🎮 Lovense Controller\n\n";

    if (isUserLinked(avatarKey)) {
        title += "✅ Device linked!\n\nQuick controls:";
        buttons = [
            "Low (5)",
            "Med (10)",
            "High (20)",
            "Pulse",
            "Wave",
            "Fireworks",
            "Earthquake",
            "STOP",
            "Unlink",
            "Info"
        ];
    } else {
        title += "❌ No device linked\n\nLink your device:";
        buttons = [
            "🔗 Link Device",
            "ℹ️ Help"
        ];
    }

    llDialog(avatarKey, title, buttons, menuChannel);
    llSetTimerEvent(60.0);
}

handleMenuSelection(string message, key avatarKey) {
    if (message == "🔗 Link Device") {
        requestQrCode(avatarKey);
    }
    else if (message == "Low (5)") {
        sendCommand(avatarKey, "Function", "Vibrate:5", 15);
        showMainMenu(avatarKey);
    }
    else if (message == "Med (10)") {
        sendCommand(avatarKey, "Function", "Vibrate:10", 15);
        showMainMenu(avatarKey);
    }
    else if (message == "High (20)") {
        sendCommand(avatarKey, "Function", "Vibrate:20", 15);
        showMainMenu(avatarKey);
    }
    else if (message == "Pulse") {
        sendCommand(avatarKey, "Preset", "pulse", 20);
        showMainMenu(avatarKey);
    }
    else if (message == "Wave") {
        sendCommand(avatarKey, "Preset", "wave", 20);
        showMainMenu(avatarKey);
    }
    else if (message == "Fireworks") {
        sendCommand(avatarKey, "Preset", "fireworks", 20);
        showMainMenu(avatarKey);
    }
    else if (message == "Earthquake") {
        sendCommand(avatarKey, "Preset", "earthquake", 20);
        showMainMenu(avatarKey);
    }
    else if (message == "STOP") {
        sendCommand(avatarKey, "Function", "Stop", 0);
        showMainMenu(avatarKey);
    }
    else if (message == "Unlink") {
        unlinkUser(avatarKey);
        showMainMenu(avatarKey);
    }
    else if (message == "Info") {
        if (isUserLinked(avatarKey)) {
            list conn = getUserConnection(avatarKey);
            llRegionSayTo(avatarKey, 0, "═══════════════════════════════");
            llRegionSayTo(avatarKey, 0, "DEVICE INFO");
            llRegionSayTo(avatarKey, 0, "═══════════════════════════════");
            llRegionSayTo(avatarKey, 0, "Status: ✅ Linked");
            llRegionSayTo(avatarKey, 0, "Domain: " + llList2String(conn, 0));
            llRegionSayTo(avatarKey, 0, "Port: " + llList2String(conn, 1));
        }
        showMainMenu(avatarKey);
    }
    else if (message == "ℹ️ Help") {
        llRegionSayTo(avatarKey, 0, "═══════════════════════════════");
        llRegionSayTo(avatarKey, 0, "HOW TO LINK");
        llRegionSayTo(avatarKey, 0, "═══════════════════════════════");
        llRegionSayTo(avatarKey, 0, "1. Click '🔗 Link Device'");
        llRegionSayTo(avatarKey, 0, "2. Set callback URL in Lovense portal");
        llRegionSayTo(avatarKey, 0, "3. Click the QR code link");
        llRegionSayTo(avatarKey, 0, "4. Scan with Lovense Remote app");
        llRegionSayTo(avatarKey, 0, "5. Device links automatically!");
        showMainMenu(avatarKey);
    }
}

// ============================================================================
// STATE
// ============================================================================

default {
    state_entry() {
        llOwnerSay("═══════════════════════════════════════");
        llOwnerSay("Lovense Controller - DIRECT CALLBACK");
        llOwnerSay("═══════════════════════════════════════");
        llOwnerSay("✨ Uses llRequestURL for callbacks!");
        llOwnerSay("No external servers needed!");
        llOwnerSay("\nTouch to start");
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
    }

    // ========================================================================
    // HTTP REQUEST - Outgoing requests
    // ========================================================================

    http_response(key request_id, integer status, list metadata, string body) {
        // QR Code Response
        if (request_id == qrRequestId) {
            if (status == 200) {
                integer qrPos = llSubStringIndex(body, "\"qr\":\"");
                if (qrPos != -1) {
                    string afterQr = llGetSubString(body, qrPos + 6, -1);
                    integer endPos = llSubStringIndex(afterQr, "\"");
                    currentQrCode = llGetSubString(afterQr, 0, endPos - 1);

                    llRegionSayTo(currentLinkingUser, 0, "✅ QR Code ready!");
                    llLoadURL(currentLinkingUser, "Scan with Lovense Remote app", currentQrCode);

                    llRegionSayTo(currentLinkingUser, 0, "\n📱 INSTRUCTIONS:");
                    llRegionSayTo(currentLinkingUser, 0, "1. Open Lovense Remote app");
                    llRegionSayTo(currentLinkingUser, 0, "2. Tap QR code scanner");
                    llRegionSayTo(currentLinkingUser, 0, "3. Scan the QR code");
                    llRegionSayTo(currentLinkingUser, 0, "4. Device will link automatically!");
                    llRegionSayTo(currentLinkingUser, 0, "\n⏳ Waiting for scan...");
                }
            } else {
                llRegionSayTo(currentLinkingUser, 0, "❌ QR generation failed: " + (string)status);
                llRegionSayTo(currentLinkingUser, 0, "Response: " + body);
            }
        }

        // Control Command Response
        else if (request_id == httpRequestId) {
            if (status == 200) {
                llRegionSayTo(currentMenuUser, 0, "✅ Command sent!");
            } else {
                llRegionSayTo(currentMenuUser, 0, "❌ Error: " + (string)status);
            }
        }
    }

    // ========================================================================
    // HTTP REQUEST - Incoming callbacks from Lovense
    // ========================================================================

    http_request(key id, string method, string body) {
        if (method == URL_REQUEST_GRANTED) {
            CALLBACK_URL = body;
            callbackActive = TRUE;

            llOwnerSay("═══════════════════════════════════════");
            llOwnerSay("📡 CALLBACK URL READY!");
            llOwnerSay("═══════════════════════════════════════");
            llOwnerSay("\n⚠️  IMPORTANT - ONE-TIME SETUP:");
            llOwnerSay("\n1. Go to: https://www.lovense.com/user/developer/info");
            llOwnerSay("\n2. Set Callback URL to:");
            llOwnerSay("   " + CALLBACK_URL);
            llOwnerSay("\n3. Save settings");
            llOwnerSay("\n4. Come back and click 'Link Device'");
            llOwnerSay("\n═══════════════════════════════════════");

            llRegionSayTo(currentLinkingUser, 0, "📡 Callback URL generated!");
            llRegionSayTo(currentLinkingUser, 0, "Check chat for setup instructions.");
            llRegionSayTo(currentLinkingUser, 0, "\nAfter setting callback URL in portal,");
            llRegionSayTo(currentLinkingUser, 0, "touch again and select 'Link Device'");
        }
        else if (method == URL_REQUEST_DENIED) {
            llOwnerSay("❌ URL request denied!");
            llRegionSayTo(currentLinkingUser, 0, "❌ Couldn't get callback URL");
            llRegionSayTo(currentLinkingUser, 0, "The script may need to be reset");
        }
        else if (method == "POST") {
            // This is a callback from Lovense!
            llOwnerSay("📨 Received callback from Lovense!");
            llOwnerSay("Body: " + body);

            // Parse the callback
            // Expected format: {"uid":"...","domain":"...","httpsPort":"...","toys":{...}}

            // Extract UID
            integer uidPos = llSubStringIndex(body, "\"uid\":\"");
            string uid = "";
            if (uidPos != -1) {
                string afterUid = llGetSubString(body, uidPos + 7, -1);
                integer uidEnd = llSubStringIndex(afterUid, "\"");
                uid = llGetSubString(afterUid, 0, uidEnd - 1);
            }

            // Extract domain
            integer domainPos = llSubStringIndex(body, "\"domain\":\"");
            string domain = "";
            if (domainPos != -1) {
                string afterDomain = llGetSubString(body, domainPos + 10, -1);
                integer domainEnd = llSubStringIndex(afterDomain, "\"");
                domain = llGetSubString(afterDomain, 0, domainEnd - 1);
            }

            // Extract httpsPort
            integer portPos = llSubStringIndex(body, "\"httpsPort\":\"");
            string port = "";
            if (portPos != -1) {
                string afterPort = llGetSubString(body, portPos + 13, -1);
                integer portEnd = llSubStringIndex(afterPort, "\"");
                port = llGetSubString(afterPort, 0, portEnd - 1);
            }

            if (uid != "" && domain != "" && port != "") {
                llOwnerSay("✅ Parsed callback:");
                llOwnerSay("  UID: " + uid);
                llOwnerSay("  Domain: " + domain);
                llOwnerSay("  Port: " + port);

                // Store connection for this user
                key avatarKey = (key)uid;
                storeUserConnection(avatarKey, domain, port);
            } else {
                llOwnerSay("❌ Failed to parse callback");
            }

            // Send response to Lovense
            llHTTPResponse(id, 200, "{\"result\":true,\"message\":\"Connection saved\"}");
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
        if (change & CHANGED_REGION) {
            // URL becomes invalid if we change regions
            llResetScript();
        }
    }
}
