// ============================================================================
// Lovense API Endpoint Tester
// ============================================================================
// This script tests MULTIPLE possible API formats to find which one works
// with your token
// ============================================================================

string DEVELOPER_TOKEN = "YOUR_TOKEN_HERE";  // Your actual token
string USER_ID = "YOUR_UID_HERE";             // Your actual UID

integer testIndex = 0;
key currentRequest;

// Different endpoints and formats to try
list testEndpoints = [
    "https://api.lovense.com/api/lan/command",
    "https://api.lovense.com/api/lan/v2/command",
    "https://api.lovense-api.com/api/lan/command",
    "https://apps.lovense-api.com/api/command"
];

list testFormats = [
    // Format 1: Standard format
    "{\"token\":\"TOKEN\",\"uid\":\"UID\",\"command\":\"GetToys\",\"apiVer\":1}",

    // Format 2: With developerToken instead of token
    "{\"developerToken\":\"TOKEN\",\"uid\":\"UID\",\"command\":\"GetToys\",\"apiVer\":1}",

    // Format 3: With userId instead of uid
    "{\"token\":\"TOKEN\",\"userId\":\"UID\",\"command\":\"GetToys\",\"apiVer\":1}",

    // Format 4: With dToken (developer token)
    "{\"dToken\":\"TOKEN\",\"uid\":\"UID\",\"command\":\"GetToys\",\"apiVer\":1}",

    // Format 5: application/x-www-form-urlencoded format
    "token=TOKEN&uid=UID&command=GetToys&apiVer=1"
];

runNextTest() {
    if (testIndex >= llGetListLength(testEndpoints)) {
        llOwnerSay("\n═══════════════════════════════════════");
        llOwnerSay("ALL TESTS COMPLETE");
        llOwnerSay("═══════════════════════════════════════");
        llOwnerSay("\nIf none worked, you may need to:");
        llOwnerSay("1. Use the QR code linking method");
        llOwnerSay("2. Set up a callback URL first");
        llOwnerSay("3. Or use the LAN API instead");
        return;
    }

    string endpoint = llList2String(testEndpoints, testIndex);

    llOwnerSay("\n───────────────────────────────────────");
    llOwnerSay("TEST #" + (string)(testIndex + 1));
    llOwnerSay("Endpoint: " + endpoint);
    llOwnerSay("───────────────────────────────────────");

    // Try each format with this endpoint
    integer i;
    for (i = 0; i < llGetListLength(testFormats); i++) {
        string format = llList2String(testFormats, i);
        string body = llDumpList2String(llParseStringKeepNulls(format, ["TOKEN"], []), DEVELOPER_TOKEN);
        body = llDumpList2String(llParseStringKeepNulls(body, ["UID"], []), USER_ID);

        llOwnerSay("\n  Format " + (string)(i + 1) + ":");
        llOwnerSay("  " + body);

        list headers;
        if (i == 4) {
            // Form-urlencoded format
            headers = [
                HTTP_METHOD, "POST",
                HTTP_MIMETYPE, "application/x-www-form-urlencoded"
            ];
        } else {
            // JSON format
            headers = [
                HTTP_METHOD, "POST",
                HTTP_MIMETYPE, "application/json"
            ];
        }

        currentRequest = llHTTPRequest(endpoint, headers, body);

        // Wait for response before next test
        return;
    }
}

default {
    state_entry() {
        llOwnerSay("═══════════════════════════════════════");
        llOwnerSay("LOVENSE API ENDPOINT TESTER");
        llOwnerSay("═══════════════════════════════════════");

        if (DEVELOPER_TOKEN == "YOUR_TOKEN_HERE") {
            llOwnerSay("❌ Configure DEVELOPER_TOKEN first!");
            return;
        }

        llOwnerSay("\nThis will test multiple endpoints and");
        llOwnerSay("formats to find what works with your token.");
        llOwnerSay("\nTouch to start...");
    }

    touch_start(integer num) {
        if (llDetectedKey(0) == llGetOwner()) {
            testIndex = 0;
            llOwnerSay("\nStarting tests...\n");
            runNextTest();
        }
    }

    http_response(key id, integer status, list meta, string body) {
        if (id != currentRequest) return;

        llOwnerSay("  → Status: " + (string)status);
        llOwnerSay("  → Response: " + body);

        if (status == 200 && llSubStringIndex(body, "\"result\":true") != -1) {
            llOwnerSay("\n  ✅✅✅ SUCCESS! THIS FORMAT WORKS! ✅✅✅");
            llOwnerSay("  Use this endpoint and format in your script!");
        } else if (llSubStringIndex(body, "Invalid token") != -1) {
            llOwnerSay("  ❌ Invalid token response");
        } else if (status == 404) {
            llOwnerSay("  ❌ Endpoint not found");
        }

        // Small delay before next test
        llSleep(1.0);

        // Continue to next test
        testIndex++;
        runNextTest();
    }
}

// ============================================================================
// ALTERNATIVE: Check if you need QR Code Flow
// ============================================================================

/*
If ALL tests fail with 401, you might need the QR Code flow:

Step 1: Get QR Code
URL: https://api.lovense.com/api/lan/getQrCode
POST: {
  "token": "your_developer_token",
  "uid": "your_uid",
  "uname": "username",
  "utoken": "random_token_you_generate",
  "v": 2
}

Response includes:
- QR code URL
- User scans with Lovense Remote app
- You receive callback to your registered callback URL
- Callback contains domain/port to send commands to

Step 2: Send Commands
URL: https://{domain_from_callback}:{port_from_callback}/command
POST: {
  "command": "Function",
  "action": "Vibrate:10",
  "timeSec": 10,
  "apiVer": 1
}

Note: This requires setting up a callback URL in your developer settings!
*/
