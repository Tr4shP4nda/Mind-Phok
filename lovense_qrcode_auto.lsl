// ============================================================================
// Lovense QR Code Controller - AUTO-LINK VERSION
// ============================================================================
// This version automatically polls for connection info after QR code scan
// No manual linking required!
// ============================================================================

// ============================================================================
// CONFIGURATION
// ============================================================================

string DEVELOPER_TOKEN = "YOUR_DEVELOPER_TOKEN_HERE";

// Your callback receiver URL (must support /get-connection endpoint)
string CALLBACK_API = "https://your-project.glitch.me";

// OR if using the simple version, the script will guide you through manual setup

// ============================================================================
// GLOBAL VARIABLES
// ============================================================================

key httpRequestId;
key qrRequestId;
key pollRequestId;

integer listenHandle;
integer menuChannel;
integer isProcessing = FALSE;

list linkedUsers = [];

string currentQrCode = "";
key currentLinkingUser;
key currentMenuUser;

integer pollAttempts = 0;
integer MAX_POLL_ATTEMPTS = 12;  // Poll for 60 seconds (12 * 5s)

// ============================================================================
// USER LINKING FUNCTIONS
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
    llRegionSayTo(avatarKey, 0, "Connection: " + domain + ":" + port);
    llRegionSayTo(avatarKey, 0, "Touch again to use controls!");

    // Stop polling
    llSetTimerEvent(0.0);
    pollAttempts = 0;
}

// ============================================================================
// QR CODE GENERATION
// ============================================================================

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

    llRegionSayTo(avatarKey, 0, "📱 Generating QR code...");
    qrRequestId = llHTTPRequest("https://api.lovense.com/api/lan/getQrCode", headers, json);
}

// ============================================================================
// AUTO-POLLING FOR CONNECTION INFO
// ============================================================================

pollForConnection(key avatarKey) {
    if (CALLBACK_API == "https://your-project.glitch.me") {
        // Not configured for auto-polling
        return;
    }

    string url = CALLBACK_API + "/get-connection/" + (string)avatarKey;

    list headers = [
        HTTP_METHOD, "GET",
        HTTP_VERIFY_CERT, TRUE
    ];

    pollRequestId = llHTTPRequest(url, headers, "");
    pollAttempts++;
}

startPolling(key avatarKey) {
    llRegionSayTo(avatarKey, 0, "🔄 Waiting for QR code scan...");
    llRegionSayTo(avatarKey, 0, "Will check for connection automatically.");
    pollAttempts = 0;
    llSetTimerEvent(5.0);  // Poll every 5 seconds
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

    if (action == "Stop") {
        llRegionSayTo(avatarKey, 0, "⏹️ Stopping...");
    } else {
        llRegionSayTo(avatarKey, 0, "📤 " + action);
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

showQuickMenu(key avatarKey) {
    cleanupListeners();
    menuChannel = getRandomChannel();
    listenHandle = llListen(menuChannel, "", avatarKey, "");
    currentMenuUser = avatarKey;

    list buttons = [
        "Low (5)",
        "Med (10)",
        "High (20)",
        "Pulse",
        "Wave",
        "Fireworks",
        "Earthquake",
        "STOP",
        "Unlink",
        "Link New"
    ];

    string title = "🎮 Lovense Quick Controls\n\n";
    if (isUserLinked(avatarKey)) {
        title += "✅ Device linked!\nSelect command:";
    } else {
        title += "❌ Not linked\nLink device first:";
    }

    llDialog(avatarKey, title, buttons, menuChannel);
    llSetTimerEvent(60.0);
}

handleMenuSelection(string message, key avatarKey) {
    if (message == "Low (5)") {
        sendCommand(avatarKey, "Function", "Vibrate:5", 15);
    }
    else if (message == "Med (10)") {
        sendCommand(avatarKey, "Function", "Vibrate:10", 15);
    }
    else if (message == "High (20)") {
        sendCommand(avatarKey, "Function", "Vibrate:20", 15);
    }
    else if (message == "Pulse") {
        sendCommand(avatarKey, "Preset", "pulse", 20);
    }
    else if (message == "Wave") {
        sendCommand(avatarKey, "Preset", "wave", 20);
    }
    else if (message == "Fireworks") {
        sendCommand(avatarKey, "Preset", "fireworks", 20);
    }
    else if (message == "Earthquake") {
        sendCommand(avatarKey, "Preset", "earthquake", 20);
    }
    else if (message == "STOP") {
        sendCommand(avatarKey, "Function", "Stop", 0);
    }
    else if (message == "Unlink") {
        integer index = llListFindList(linkedUsers, [(string)avatarKey]);
        if (index != -1) {
            linkedUsers = llDeleteSubList(linkedUsers, index, index + 2);
            llRegionSayTo(avatarKey, 0, "✅ Device unlinked.");
        }
        showQuickMenu(avatarKey);
    }
    else if (message == "Link New") {
        requestQrCode(avatarKey);
    }
}

// ============================================================================
// STATE MACHINE
// ============================================================================

default {
    state_entry() {
        llOwnerSay("═══════════════════════════════════════");
        llOwnerSay("Lovense QR Controller - AUTO LINK");
        llOwnerSay("═══════════════════════════════════════");

        if (CALLBACK_API == "https://your-project.glitch.me") {
            llOwnerSay("⚠️  Manual linking mode");
            llOwnerSay("To enable auto-link:");
            llOwnerSay("1. Deploy qr-callback-receiver.js");
            llOwnerSay("2. Set CALLBACK_API to your URL");
        } else {
            llOwnerSay("✅ Auto-link enabled!");
            llOwnerSay("API: " + CALLBACK_API);
        }

        llOwnerSay("\nTouch to link device & control");

        // Listen for manual link commands
        llListen(99, "", NULL_KEY, "");
    }

    touch_start(integer num_detected) {
        key toucher = llDetectedKey(0);
        showQuickMenu(toucher);
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
        // QR Code Response
        if (request_id == qrRequestId) {
            if (status == 200) {
                integer qrPos = llSubStringIndex(body, "\"qr\":\"");
                if (qrPos != -1) {
                    string afterQr = llGetSubString(body, qrPos + 6, -1);
                    integer endPos = llSubStringIndex(afterQr, "\"");
                    currentQrCode = llGetSubString(afterQr, 0, endPos - 1);

                    llRegionSayTo(currentLinkingUser, 0, "✅ QR Code ready!");
                    llLoadURL(currentLinkingUser, "Scan with Lovense Remote", currentQrCode);

                    llRegionSayTo(currentLinkingUser, 0, "\n📱 SCAN THE QR CODE:");
                    llRegionSayTo(currentLinkingUser, 0, "1. Open Lovense Remote app");
                    llRegionSayTo(currentLinkingUser, 0, "2. Tap QR scanner icon");
                    llRegionSayTo(currentLinkingUser, 0, "3. Scan the QR code");

                    if (CALLBACK_API != "https://your-project.glitch.me") {
                        llRegionSayTo(currentLinkingUser, 0, "4. Wait ~10 seconds for auto-link!");
                        startPolling(currentLinkingUser);
                    } else {
                        llRegionSayTo(currentLinkingUser, 0, "4. Check " + CALLBACK_API);
                        llRegionSayTo(currentLinkingUser, 0, "5. Find 'domain' and 'httpsPort'");
                        llRegionSayTo(currentLinkingUser, 0, "6. Type: /99 link <domain> <port>");
                    }
                }
            } else {
                llRegionSayTo(currentLinkingUser, 0, "❌ Error generating QR: " + (string)status);
            }
        }

        // Poll Response
        else if (request_id == pollRequestId) {
            if (status == 200 && llSubStringIndex(body, "\"domain\":") != -1) {
                // Found connection info! Parse it
                integer domainPos = llSubStringIndex(body, "\"domain\":\"");
                if (domainPos != -1) {
                    string afterDomain = llGetSubString(body, domainPos + 10, -1);
                    integer domainEnd = llSubStringIndex(afterDomain, "\"");
                    string domain = llGetSubString(afterDomain, 0, domainEnd - 1);

                    integer portPos = llSubStringIndex(body, "\"httpsPort\":\"");
                    string afterPort = llGetSubString(body, portPos + 13, -1);
                    integer portEnd = llSubStringIndex(afterPort, "\"");
                    string port = llGetSubString(afterPort, 0, portEnd - 1);

                    llRegionSayTo(currentLinkingUser, 0, "🎉 Found connection info!");
                    storeUserConnection(currentLinkingUser, domain, port);
                }
            }
            else if (status == 404) {
                // Not found yet, keep polling
                if (pollAttempts < MAX_POLL_ATTEMPTS) {
                    llRegionSayTo(currentLinkingUser, 0, "⏳ Still waiting... (" + (string)pollAttempts + "/" + (string)MAX_POLL_ATTEMPTS + ")");
                } else {
                    llRegionSayTo(currentLinkingUser, 0, "⏱️ Timeout - use manual link");
                    llRegionSayTo(currentLinkingUser, 0, "Check callback URL and type:");
                    llRegionSayTo(currentLinkingUser, 0, "/99 link <domain> <port>");
                    llSetTimerEvent(0.0);
                }
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

    timer() {
        if (currentLinkingUser != NULL_KEY && !isUserLinked(currentLinkingUser)) {
            if (pollAttempts < MAX_POLL_ATTEMPTS) {
                pollForConnection(currentLinkingUser);
            } else {
                llRegionSayTo(currentLinkingUser, 0, "⏱️ Polling timeout");
                llSetTimerEvent(0.0);
            }
        } else {
            // Cleanup timer for menu
            cleanupListeners();
            llSetTimerEvent(0.0);
        }
    }
}
