// ============================================================================
// Lovense Callback Debugger
// ============================================================================
// This version shows EVERYTHING to help debug callback issues
// ============================================================================

string DEVELOPER_TOKEN = "YOUR_DEVELOPER_TOKEN_HERE";

key qrRequestId;
key urlRequestId;
key httpRequestId;

string CALLBACK_URL = "";
integer callbackActive = FALSE;

list linkedUsers = [];
key currentLinkingUser;

// ============================================================================
// DEBUG LOGGING
// ============================================================================

debug(string message) {
    llOwnerSay("[DEBUG] " + message);
}

// ============================================================================
// BASIC FUNCTIONS
// ============================================================================

string generateUniqueToken(key avatarKey) {
    string timestamp = (string)llGetUnixTime();
    string avatarStr = (string)avatarKey;
    return llGetSubString(llMD5String(avatarStr + timestamp, 0), 0, 15);
}

storeUserConnection(key avatarKey, string domain, string port) {
    integer index = llListFindList(linkedUsers, [(string)avatarKey]);
    if (index != -1) {
        linkedUsers = llDeleteSubList(linkedUsers, index, index + 2);
    }
    linkedUsers += [(string)avatarKey, domain, port];

    llOwnerSay("═══════════════════════════════════════");
    llOwnerSay("✅ DEVICE LINKED!");
    llOwnerSay("═══════════════════════════════════════");
    llOwnerSay("User: " + llKey2Name(avatarKey));
    llOwnerSay("Domain: " + domain);
    llOwnerSay("Port: " + port);
    llOwnerSay("═══════════════════════════════════════");

    llRegionSayTo(avatarKey, 0, "✅ Device linked successfully!");
}

// ============================================================================
// REQUEST QR CODE
// ============================================================================

requestQrCode(key avatarKey) {
    if (DEVELOPER_TOKEN == "YOUR_DEVELOPER_TOKEN_HERE") {
        llOwnerSay("❌ Configure DEVELOPER_TOKEN first!");
        return;
    }

    if (!callbackActive) {
        debug("No callback URL yet - requesting one");
        currentLinkingUser = avatarKey;
        urlRequestId = llRequestURL();
        return;
    }

    debug("Generating QR code for: " + llKey2Name(avatarKey));
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

    debug("QR request JSON: " + json);

    list headers = [
        HTTP_METHOD, "POST",
        HTTP_MIMETYPE, "application/json",
        HTTP_BODY_MAXLENGTH, 16384,
        HTTP_VERIFY_CERT, TRUE
    ];

    llOwnerSay("📱 Requesting QR code...");
    qrRequestId = llHTTPRequest("https://api.lovense.com/api/lan/getQrCode", headers, json);
}

// ============================================================================
// STATES
// ============================================================================

default {
    state_entry() {
        llOwnerSay("═══════════════════════════════════════");
        llOwnerSay("LOVENSE CALLBACK DEBUGGER");
        llOwnerSay("═══════════════════════════════════════");
        llOwnerSay("This shows all events to help debug");
        llOwnerSay("\nCommands:");
        llOwnerSay("  /1 link    - Request QR code");
        llOwnerSay("  /1 status  - Show current status");
        llOwnerSay("  /1 test    - Test callback URL");
        llOwnerSay("\nListening on channel 1...");

        llListen(1, "", NULL_KEY, "");
    }

    listen(integer channel, string name, key id, string message) {
        if (channel == 1) {
            if (message == "link") {
                requestQrCode(id);
            }
            else if (message == "status") {
                llOwnerSay("═══════════════════════════════════════");
                llOwnerSay("STATUS");
                llOwnerSay("═══════════════════════════════════════");
                llOwnerSay("Callback active: " + (string)callbackActive);
                llOwnerSay("Callback URL: " + CALLBACK_URL);
                llOwnerSay("Linked users: " + (string)(llGetListLength(linkedUsers) / 3));
                llOwnerSay("═══════════════════════════════════════");
            }
            else if (message == "test") {
                llOwnerSay("Testing callback URL reception...");
                llOwnerSay("Try sending a POST request to:");
                llOwnerSay(CALLBACK_URL);
            }
        }
    }

    http_response(key request_id, integer status, list metadata, string body) {
        debug("http_response received");
        debug("Request ID: " + (string)request_id);
        debug("Status: " + (string)status);
        debug("Body length: " + (string)llStringLength(body));

        if (request_id == qrRequestId) {
            llOwnerSay("═══════════════════════════════════════");
            llOwnerSay("QR CODE RESPONSE");
            llOwnerSay("═══════════════════════════════════════");
            llOwnerSay("Status: " + (string)status);
            llOwnerSay("Body: " + body);
            llOwnerSay("═══════════════════════════════════════");

            if (status == 200) {
                integer qrPos = llSubStringIndex(body, "\"qr\":\"");
                if (qrPos != -1) {
                    string afterQr = llGetSubString(body, qrPos + 6, -1);
                    integer endPos = llSubStringIndex(afterQr, "\"");
                    string qrCode = llGetSubString(afterQr, 0, endPos - 1);

                    llOwnerSay("✅ QR Code URL:");
                    llOwnerSay(qrCode);
                    llLoadURL(currentLinkingUser, "Scan with Lovense Remote", qrCode);

                    llOwnerSay("\n📱 SCAN THE QR CODE NOW");
                    llOwnerSay("⏳ Waiting for callback...");
                    llOwnerSay("\nIf nothing happens after scan:");
                    llOwnerSay("1. Check callback URL is set in portal");
                    llOwnerSay("2. Type: /1 status");
                }
            }
        }
    }

    http_request(key id, string method, string body) {
        llOwnerSay("═══════════════════════════════════════");
        llOwnerSay("HTTP_REQUEST EVENT!");
        llOwnerSay("═══════════════════════════════════════");
        llOwnerSay("Method: " + method);
        llOwnerSay("Body length: " + (string)llStringLength(body));
        llOwnerSay("Body preview: " + llGetSubString(body, 0, 200));
        llOwnerSay("═══════════════════════════════════════");

        if (method == URL_REQUEST_GRANTED) {
            CALLBACK_URL = body;
            callbackActive = TRUE;

            llOwnerSay("═══════════════════════════════════════");
            llOwnerSay("📡 CALLBACK URL RECEIVED!");
            llOwnerSay("═══════════════════════════════════════");
            llOwnerSay("\n🔴 CRITICAL - DO THIS NOW:");
            llOwnerSay("\n1. Go to:");
            llOwnerSay("   https://www.lovense.com/user/developer/info");
            llOwnerSay("\n2. Find 'Callback URL' field");
            llOwnerSay("\n3. Paste this EXACT URL:");
            llOwnerSay("\n   " + CALLBACK_URL);
            llOwnerSay("\n4. SAVE the settings");
            llOwnerSay("\n5. Come back and type: /1 link");
            llOwnerSay("\n═══════════════════════════════════════");
            llOwnerSay("⚠️  The URL above MUST match EXACTLY!");
            llOwnerSay("═══════════════════════════════════════");
        }
        else if (method == URL_REQUEST_DENIED) {
            llOwnerSay("❌ URL REQUEST DENIED!");
            llOwnerSay("Script may need to be reset");
        }
        else if (method == "POST") {
            llOwnerSay("═══════════════════════════════════════");
            llOwnerSay("🎉 CALLBACK RECEIVED FROM LOVENSE!");
            llOwnerSay("═══════════════════════════════════════");
            llOwnerSay("Full body:");
            llOwnerSay(body);
            llOwnerSay("═══════════════════════════════════════");

            // Parse uid
            integer uidPos = llSubStringIndex(body, "\"uid\":\"");
            string uid = "";
            if (uidPos != -1) {
                string afterUid = llGetSubString(body, uidPos + 7, -1);
                integer uidEnd = llSubStringIndex(afterUid, "\"");
                uid = llGetSubString(afterUid, 0, uidEnd - 1);
                debug("Parsed UID: " + uid);
            } else {
                debug("❌ No UID found in callback");
            }

            // Parse domain
            integer domainPos = llSubStringIndex(body, "\"domain\":\"");
            string domain = "";
            if (domainPos != -1) {
                string afterDomain = llGetSubString(body, domainPos + 10, -1);
                integer domainEnd = llSubStringIndex(afterDomain, "\"");
                domain = llGetSubString(afterDomain, 0, domainEnd - 1);
                debug("Parsed domain: " + domain);
            } else {
                debug("❌ No domain found in callback");
            }

            // Parse httpsPort
            integer portPos = llSubStringIndex(body, "\"httpsPort\":\"");
            string port = "";
            if (portPos != -1) {
                string afterPort = llGetSubString(body, portPos + 13, -1);
                integer portEnd = llSubStringIndex(afterPort, "\"");
                port = llGetSubString(afterPort, 0, portEnd - 1);
                debug("Parsed port: " + port);
            } else {
                debug("❌ No httpsPort found in callback");
            }

            if (uid != "" && domain != "" && port != "") {
                llOwnerSay("✅ Successfully parsed all fields!");
                key avatarKey = (key)uid;
                storeUserConnection(avatarKey, domain, port);

                // Send success response
                llHTTPResponse(id, 200, "{\"result\":true,\"message\":\"Connected\"}");
            } else {
                llOwnerSay("❌ Failed to parse callback!");
                llOwnerSay("Missing: " +
                    (uid == "" ? "uid " : "") +
                    (domain == "" ? "domain " : "") +
                    (port == "" ? "port" : ""));

                // Still send response
                llHTTPResponse(id, 200, "{\"result\":false,\"message\":\"Parse error\"}");
            }
        }
        else if (method == "GET") {
            llOwnerSay("Received GET request (probably a test)");
            llHTTPResponse(id, 200, "Lovense callback receiver is working!");
        }
        else {
            llOwnerSay("Received " + method + " request");
            llOwnerSay("Body: " + body);
            llHTTPResponse(id, 200, "OK");
        }
    }

    on_rez(integer start_param) {
        llResetScript();
    }
}
