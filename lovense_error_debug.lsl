// ============================================================================
// Lovense Controller - Enhanced Error Handling
// ============================================================================
// Shows detailed error info to help troubleshoot connection issues
// ============================================================================

string DEVELOPER_TOKEN = "YOUR_DEVELOPER_TOKEN_HERE";

key httpRequestId;
key qrRequestId;
key urlRequestId;

integer listenHandle;
integer menuChannel;

list linkedUsers = [];

string currentQrCode = "";
key currentLinkingUser;
key currentMenuUser;

string CALLBACK_URL = "";
integer callbackActive = FALSE;

// Track last command for error reporting
string lastCommand = "";
string lastAction = "";

// ============================================================================
// USER MANAGEMENT
// ============================================================================

string generateUniqueToken(key avatarKey) {
    string timestamp = (string)llGetUnixTime();
    string avatarStr = (string)avatarKey;
    return llGetSubString(llMD5String(avatarStr + timestamp, 0), 0, 15);
}

integer isUserLinked(key avatarKey) {
    integer index = llListFindList(linkedUsers, [(string)avatarKey]);
    if (index != -1) {
        return TRUE;
    }
    return FALSE;
}

list getUserConnection(key avatarKey) {
    integer index = llListFindList(linkedUsers, [(string)avatarKey]);
    if (index == -1) {
        return [];
    }

    string domain = llList2String(linkedUsers, index + 1);
    string port = llList2String(linkedUsers, index + 2);
    return [domain, port];
}

storeUserConnection(key avatarKey, string domain, string port) {
    integer index = llListFindList(linkedUsers, [(string)avatarKey]);
    if (index != -1) {
        linkedUsers = llDeleteSubList(linkedUsers, index, index + 2);
    }

    linkedUsers = linkedUsers + [(string)avatarKey, domain, port];

    llRegionSayTo(avatarKey, 0, "✅ Device linked!");
    llRegionSayTo(avatarKey, 0, "📡 " + domain + ":" + port);

    // Test the connection immediately
    llRegionSayTo(avatarKey, 0, "\n🔍 Testing connection...");
    sendCommand(avatarKey, "Function", "Vibrate:1", 2);
}

unlinkUser(key avatarKey) {
    integer index = llListFindList(linkedUsers, [(string)avatarKey]);
    if (index != -1) {
        linkedUsers = llDeleteSubList(linkedUsers, index, index + 2);
        llRegionSayTo(avatarKey, 0, "✅ Device unlinked");
    }

    if (llGetListLength(linkedUsers) == 0) {
        if (callbackActive == TRUE) {
            llReleaseURL(CALLBACK_URL);
            CALLBACK_URL = "";
            callbackActive = FALSE;
            llOwnerSay("📡 Callback URL released");
        }
    }
}

// ============================================================================
// CALLBACK URL
// ============================================================================

requestCallbackURL(key avatarKey) {
    currentLinkingUser = avatarKey;
    llRegionSayTo(avatarKey, 0, "📡 Requesting callback URL...");
    urlRequestId = llRequestURL();
}

// ============================================================================
// QR CODE
// ============================================================================

requestQrCode(key avatarKey) {
    if (DEVELOPER_TOKEN == "YOUR_DEVELOPER_TOKEN_HERE") {
        llRegionSayTo(avatarKey, 0, "❌ Configure DEVELOPER_TOKEN!");
        return;
    }

    if (callbackActive == FALSE) {
        requestCallbackURL(avatarKey);
        return;
    }

    currentLinkingUser = avatarKey;
    string avatarName = llKey2Name(avatarKey);
    string uniqueToken = generateUniqueToken(avatarKey);

    string json = "{";
    json = json + "\"token\":\"" + DEVELOPER_TOKEN + "\"";
    json = json + ",\"uid\":\"" + (string)avatarKey + "\"";
    json = json + ",\"uname\":\"" + avatarName + "\"";
    json = json + ",\"utoken\":\"" + uniqueToken + "\"";
    json = json + ",\"v\":2";
    json = json + "}";

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
// DEVICE CONTROL WITH DETAILED ERROR HANDLING
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

    // Store for error reporting
    lastCommand = command;
    lastAction = action;
    currentMenuUser = avatarKey;

    string json = "{";
    json = json + "\"command\":\"" + command + "\"";
    if (action != "") {
        json = json + ",\"action\":\"" + action + "\"";
    }
    json = json + ",\"timeSec\":" + (string)timeSec;
    json = json + ",\"apiVer\":1";
    json = json + "}";

    list headers = [
        HTTP_METHOD, "POST",
        HTTP_MIMETYPE, "application/json",
        HTTP_VERIFY_CERT, TRUE
    ];

    llOwnerSay("📤 Sending to: " + url);
    llOwnerSay("📤 Command: " + json);

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
// MENU
// ============================================================================

integer getRandomChannel() {
    integer randomNum = (integer)llFrand(1000000);
    return (0 - 1 - randomNum);
}

cleanupListeners() {
    if (listenHandle != 0) {
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

    integer linked = isUserLinked(avatarKey);

    if (linked == TRUE) {
        title = title + "✅ Device linked!\n\nSelect:";
        buttons = [
            "Low (5)",
            "Med (10)",
            "High (20)",
            "Pulse",
            "Wave",
            "Test (1)",
            "STOP",
            "Relink",
            "Unlink",
            "Debug"
        ];
    } else {
        title = title + "❌ Not linked\n\nLink device:";
        buttons = [
            "🔗 Link"
        ];
    }

    llDialog(avatarKey, title, buttons, menuChannel);
    llSetTimerEvent(60.0);
}

handleMenuSelection(string message, key avatarKey) {
    if (message == "🔗 Link") {
        requestQrCode(avatarKey);
    }
    else if (message == "Test (1)") {
        llRegionSayTo(avatarKey, 0, "Testing with vibrate level 1 for 3 seconds...");
        sendCommand(avatarKey, "Function", "Vibrate:1", 3);
    }
    else if (message == "Low (5)") {
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
    else if (message == "STOP") {
        sendCommand(avatarKey, "Function", "Stop", 0);
    }
    else if (message == "Relink") {
        unlinkUser(avatarKey);
        llRegionSayTo(avatarKey, 0, "Device unlinked. Click Link to reconnect.");
        showMainMenu(avatarKey);
        return;
    }
    else if (message == "Unlink") {
        unlinkUser(avatarKey);
        showMainMenu(avatarKey);
        return;
    }
    else if (message == "Debug") {
        list conn = getUserConnection(avatarKey);
        llRegionSayTo(avatarKey, 0, "═══════════════════════════════");
        llRegionSayTo(avatarKey, 0, "DEBUG INFO");
        llRegionSayTo(avatarKey, 0, "═══════════════════════════════");
        llRegionSayTo(avatarKey, 0, "Domain: " + llList2String(conn, 0));
        llRegionSayTo(avatarKey, 0, "Port: " + llList2String(conn, 1));
        llRegionSayTo(avatarKey, 0, "URL: https://" + llList2String(conn, 0) + ":" + llList2String(conn, 1) + "/command");
        llRegionSayTo(avatarKey, 0, "\nIs device still connected?");
        llRegionSayTo(avatarKey, 0, "Check Lovense Remote app!");
        showMainMenu(avatarKey);
        return;
    }

    showMainMenu(avatarKey);
}

// ============================================================================
// STATE
// ============================================================================

default {
    state_entry() {
        llOwnerSay("═══════════════════════════════════════");
        llOwnerSay("Lovense Controller - Debug Version");
        llOwnerSay("═══════════════════════════════════════");
        llOwnerSay("Shows detailed error messages");
        llOwnerSay("\nTouch to start");
    }

    touch_start(integer num_detected) {
        key toucher = llDetectedKey(0);
        showMainMenu(toucher);
    }

    listen(integer channel, string name, key id, string message) {
        if (channel == menuChannel) {
            if (id == currentMenuUser) {
                cleanupListeners();
                handleMenuSelection(message, id);
            }
        }
    }

    http_response(key request_id, integer status, list metadata, string body) {
        if (request_id == qrRequestId) {
            if (status == 200) {
                integer qrPos = llSubStringIndex(body, "\"qr\":\"");
                if (qrPos != -1) {
                    string afterQr = llGetSubString(body, qrPos + 6, -1);
                    integer endPos = llSubStringIndex(afterQr, "\"");
                    currentQrCode = llGetSubString(afterQr, 0, endPos - 1);

                    llRegionSayTo(currentLinkingUser, 0, "✅ QR Code ready!");
                    llLoadURL(currentLinkingUser, "Scan with Lovense Remote", currentQrCode);
                    llRegionSayTo(currentLinkingUser, 0, "📱 Scan QR → Wait for auto-link");
                }
            }
        }
        else if (request_id == httpRequestId) {
            llOwnerSay("═══════════════════════════════════════");
            llOwnerSay("COMMAND RESPONSE");
            llOwnerSay("═══════════════════════════════════════");
            llOwnerSay("Status: " + (string)status);
            llOwnerSay("Body: " + body);
            llOwnerSay("═══════════════════════════════════════");

            if (status == 200) {
                llRegionSayTo(currentMenuUser, 0, "✅ Command successful!");
            }
            else if (status == 499) {
                llRegionSayTo(currentMenuUser, 0, "═══════════════════════════════");
                llRegionSayTo(currentMenuUser, 0, "❌ TIMEOUT ERROR (499)");
                llRegionSayTo(currentMenuUser, 0, "═══════════════════════════════");
                llRegionSayTo(currentMenuUser, 0, "Device not responding!");
                llRegionSayTo(currentMenuUser, 0, "\nPossible causes:");
                llRegionSayTo(currentMenuUser, 0, "1. Device disconnected from app");
                llRegionSayTo(currentMenuUser, 0, "2. Lovense Remote app closed");
                llRegionSayTo(currentMenuUser, 0, "3. Network connection lost");
                llRegionSayTo(currentMenuUser, 0, "4. Device turned off");
                llRegionSayTo(currentMenuUser, 0, "\n💡 FIX:");
                llRegionSayTo(currentMenuUser, 0, "• Open Lovense Remote app");
                llRegionSayTo(currentMenuUser, 0, "• Check device is connected (green)");
                llRegionSayTo(currentMenuUser, 0, "• Try clicking 'Relink' if needed");
            }
            else if (status == 0) {
                llRegionSayTo(currentMenuUser, 0, "❌ SSL CERTIFICATE ERROR");
                llRegionSayTo(currentMenuUser, 0, "The connection domain has an invalid certificate");
                llRegionSayTo(currentMenuUser, 0, "This usually means the device disconnected.");
                llRegionSayTo(currentMenuUser, 0, "\nTry: Click 'Relink' and scan QR again");
            }
            else {
                llRegionSayTo(currentMenuUser, 0, "❌ HTTP Error: " + (string)status);
                llRegionSayTo(currentMenuUser, 0, "Response: " + body);
            }
        }
    }

    http_request(key id, string method, string body) {
        if (method == URL_REQUEST_GRANTED) {
            CALLBACK_URL = body;
            callbackActive = TRUE;

            llOwnerSay("═══════════════════════════════════════");
            llOwnerSay("📡 CALLBACK URL:");
            llOwnerSay(CALLBACK_URL);
            llOwnerSay("═══════════════════════════════════════");
            llOwnerSay("Set this at:");
            llOwnerSay("https://www.lovense.com/user/developer/info");
            llOwnerSay("═══════════════════════════════════════");

            llRegionSayTo(currentLinkingUser, 0, "📡 Callback URL ready - check chat");
        }
        else if (method == "POST") {
            llOwnerSay("📨 Callback from Lovense!");

            string uid = "";
            string domain = "";
            string port = "";

            integer uidPos = llSubStringIndex(body, "\"uid\":\"");
            if (uidPos != -1) {
                string afterUid = llGetSubString(body, uidPos + 7, -1);
                integer uidEnd = llSubStringIndex(afterUid, "\"");
                uid = llGetSubString(afterUid, 0, uidEnd - 1);
            }

            integer domainPos = llSubStringIndex(body, "\"domain\":\"");
            if (domainPos != -1) {
                string afterDomain = llGetSubString(body, domainPos + 10, -1);
                integer domainEnd = llSubStringIndex(afterDomain, "\"");
                domain = llGetSubString(afterDomain, 0, domainEnd - 1);
            }

            integer portPos = llSubStringIndex(body, "\"httpsPort\":\"");
            if (portPos != -1) {
                string afterPort = llGetSubString(body, portPos + 13, -1);
                integer portEnd = llSubStringIndex(afterPort, "\"");
                port = llGetSubString(afterPort, 0, portEnd - 1);
            }

            if (uid != "") {
                if (domain != "") {
                    if (port != "") {
                        llOwnerSay("✅ Linking: " + domain + ":" + port);
                        key avatarKey = (key)uid;
                        storeUserConnection(avatarKey, domain, port);
                        llHTTPResponse(id, 200, "{\"result\":true}");
                        return;
                    }
                }
            }

            llHTTPResponse(id, 200, "{\"result\":false}");
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
            llResetScript();
        }
    }
}
