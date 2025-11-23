// ============================================================================
// Lovense API Troubleshooting & Debug Script
// ============================================================================
// Use this script to diagnose 401 errors and other connection issues
//
// This script provides detailed debugging output to help identify the problem
// ============================================================================

// ============================================================================
// CONFIGURATION
// ============================================================================

// Which method are you trying to use?
integer CONNECTION_METHOD = 1;  // 1=LAN, 2=Cloud

// --- LAN API Settings ---
string LAN_IP = "192.168.1.100";
integer LAN_PORT = 30010;

// --- Cloud API Settings ---
string CLOUD_TOKEN = "YOUR_DEVELOPER_TOKEN";
string CLOUD_USER_ID = "YOUR_USER_ID";

// ============================================================================
// DEBUG SETTINGS
// ============================================================================

integer DEBUG_MODE = TRUE;  // Set to FALSE to disable verbose output

// ============================================================================
// GLOBAL VARIABLES
// ============================================================================

key httpRequestId;
integer testStep = 0;

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

debug(string message) {
    if (DEBUG_MODE) {
        llOwnerSay("[DEBUG] " + message);
    }
}

// ============================================================================
// IMPORTANT: LAN vs CLOUD API DIFFERENCES
// ============================================================================

/*
THIS IS THE MOST COMMON ISSUE:

❌ WRONG - Using LAN API (METHOD 1) with token/uid:
{
    "command": "Function",
    "action": "Vibrate:10",
    "token": "abc123",     // ← DON'T include for LAN!
    "uid": "user@email"    // ← DON'T include for LAN!
}

✅ CORRECT - LAN API request (NO token/uid):
{
    "command": "Function",
    "action": "Vibrate:10",
    "timeSec": 10,
    "apiVer": 1
}

✅ CORRECT - Cloud API request (WITH token/uid):
{
    "command": "Function",
    "action": "Vibrate:10",
    "timeSec": 10,
    "apiVer": 1,
    "token": "your_actual_token_here",
    "uid": "your_user_id_here"
}
*/

string buildJsonRequest(string command, string action, integer duration) {
    string json = "{";
    json += "\"command\":\"" + command + "\"";

    if (action != "") {
        json += ",\"action\":\"" + action + "\"";
    }

    json += ",\"timeSec\":" + (string)duration;
    json += ",\"apiVer\":1";

    // CRITICAL: Only add token/uid for Cloud API (METHOD 2)
    if (CONNECTION_METHOD == 2) {
        debug("Adding token and uid for Cloud API");
        json += ",\"token\":\"" + CLOUD_TOKEN + "\"";
        json += ",\"uid\":\"" + CLOUD_USER_ID + "\"";
    } else {
        debug("NOT adding token/uid for LAN API");
    }

    json += "}";
    return json;
}

string getApiUrl() {
    if (CONNECTION_METHOD == 1) {
        return "https://" + LAN_IP + ":" + (string)LAN_PORT + "/command";
    } else {
        return "https://api.lovense.com/api/lan/command";
    }
}

// ============================================================================
// TEST FUNCTIONS
// ============================================================================

runDiagnostics() {
    llOwnerSay("═══════════════════════════════════════");
    llOwnerSay("LOVENSE API DIAGNOSTICS");
    llOwnerSay("═══════════════════════════════════════");

    // Check connection method
    llOwnerSay("\n1. CONNECTION METHOD:");
    if (CONNECTION_METHOD == 1) {
        llOwnerSay("   ✓ Using LAN API (Local Network)");
        llOwnerSay("   → URL: https://" + LAN_IP + ":" + (string)LAN_PORT + "/command");
        llOwnerSay("   → Auth: None needed (local)");

        // Validate LAN settings
        if (LAN_IP == "192.168.1.100") {
            llOwnerSay("   ⚠️  Using default IP - did you configure this?");
        }

        llOwnerSay("\n   CHECKLIST FOR LAN API:");
        llOwnerSay("   □ Lovense Connect app is running");
        llOwnerSay("   □ Device is connected in Lovense Connect");
        llOwnerSay("   □ You're on the same network as the computer");
        llOwnerSay("   □ LAN_IP matches the IP in Connect → Settings → Developer");
        llOwnerSay("   □ LAN_PORT matches the HTTPS port (NOT HTTP port!)");

    } else {
        llOwnerSay("   ✓ Using Cloud API");
        llOwnerSay("   → URL: https://api.lovense.com/api/lan/command");
        llOwnerSay("   → Auth: Token + UID required");

        // Validate Cloud settings
        if (CLOUD_TOKEN == "YOUR_DEVELOPER_TOKEN") {
            llOwnerSay("   ❌ Token not configured!");
        } else {
            integer tokenLen = llStringLength(CLOUD_TOKEN);
            llOwnerSay("   ✓ Token set (length: " + (string)tokenLen + ")");

            // Check for common token issues
            if (llSubStringIndex(CLOUD_TOKEN, " ") != -1) {
                llOwnerSay("   ⚠️  WARNING: Token contains spaces!");
            }
            if (llSubStringIndex(CLOUD_TOKEN, "\n") != -1) {
                llOwnerSay("   ⚠️  WARNING: Token contains newlines!");
            }
        }

        if (CLOUD_USER_ID == "YOUR_USER_ID") {
            llOwnerSay("   ❌ User ID not configured!");
        } else {
            llOwnerSay("   ✓ User ID set: " + CLOUD_USER_ID);
        }

        llOwnerSay("\n   CHECKLIST FOR CLOUD API:");
        llOwnerSay("   □ Token copied from https://www.lovense.com/user/developer/info");
        llOwnerSay("   □ Token has no spaces or newlines");
        llOwnerSay("   □ User ID is correct (check developer portal)");
        llOwnerSay("   □ Device is connected in Lovense Remote app");
        llOwnerSay("   □ Internet connection is working");
    }

    // Show sample request
    llOwnerSay("\n2. SAMPLE REQUEST:");
    string sampleJson = buildJsonRequest("GetToys", "", 0);
    llOwnerSay("   " + sampleJson);

    // Show what will be sent
    llOwnerSay("\n3. TEST REQUEST:");
    llOwnerSay("   Sending GetToys command to test connection...");

    // Send test request
    testStep = 1;
    sendTestRequest("GetToys", "", 0);
}

sendTestRequest(string command, string action, integer duration) {
    string url = getApiUrl();
    string jsonBody = buildJsonRequest(command, action, duration);

    debug("URL: " + url);
    debug("Body: " + jsonBody);

    list headers = [
        HTTP_METHOD, "POST",
        HTTP_MIMETYPE, "application/json",
        HTTP_BODY_MAXLENGTH, 16384,
        HTTP_VERIFY_CERT, TRUE
    ];

    httpRequestId = llHTTPRequest(url, headers, jsonBody);
    llOwnerSay("   → Request sent, waiting for response...");
}

// ============================================================================
// PARSE 401 ERROR DETAILS
// ============================================================================

analyzeError(string body) {
    llOwnerSay("\n═══════════════════════════════════════");
    llOwnerSay("ERROR ANALYSIS");
    llOwnerSay("═══════════════════════════════════════");

    llOwnerSay("\nResponse body: " + body);

    // Common 401 causes
    llOwnerSay("\nCOMMON CAUSES OF 401 ERROR:");

    if (CONNECTION_METHOD == 1) {
        llOwnerSay("\n❌ You're using LAN API but getting 401?");
        llOwnerSay("   This usually means one of these:");
        llOwnerSay("");
        llOwnerSay("   1. WRONG PORT");
        llOwnerSay("      → Check you're using HTTPS port, not HTTP port");
        llOwnerSay("      → In Lovense Connect: Settings → Developer");
        llOwnerSay("      → Use the port labeled 'HTTPS' (usually 30010)");
        llOwnerSay("");
        llOwnerSay("   2. WRONG IP ADDRESS");
        llOwnerSay("      → Make sure IP matches exactly what's shown in Connect");
        llOwnerSay("      → Try pinging the IP from another device");
        llOwnerSay("");
        llOwnerSay("   3. NOT ON SAME NETWORK");
        llOwnerSay("      → Your SL viewer and computer must be on same WiFi/LAN");
        llOwnerSay("      → Check both devices show same network name");
        llOwnerSay("");
        llOwnerSay("   4. LOVENSE CONNECT NOT RUNNING");
        llOwnerSay("      → Make sure Lovense Connect app is open");
        llOwnerSay("      → Make sure device is connected in the app");

    } else {
        llOwnerSay("\n❌ You're using Cloud API but getting 401?");
        llOwnerSay("   This usually means one of these:");
        llOwnerSay("");
        llOwnerSay("   1. INVALID TOKEN");
        llOwnerSay("      → Token may have expired - get a new one");
        llOwnerSay("      → Copy the ENTIRE token (no spaces/newlines)");
        llOwnerSay("      → Go to: https://www.lovense.com/user/developer/info");
        llOwnerSay("");
        llOwnerSay("   2. WRONG USER ID");
        llOwnerSay("      → User ID must match the device owner");
        llOwnerSay("      → Check the developer portal for correct UID");
        llOwnerSay("");
        llOwnerSay("   3. TOKEN FORMAT ERROR");
        llOwnerSay("      → Check for spaces before/after token");
        llOwnerSay("      → Check for newline characters");
        llOwnerSay("      → Token length: " + (string)llStringLength(CLOUD_TOKEN));
        llOwnerSay("");
        llOwnerSay("   4. ACCOUNT ISSUE");
        llOwnerSay("      → Make sure you're logged into correct account");
        llOwnerSay("      → Device must be connected in Lovense Remote");
    }

    llOwnerSay("\n═══════════════════════════════════════");
    llOwnerSay("RECOMMENDED FIXES:");
    llOwnerSay("═══════════════════════════════════════");

    if (CONNECTION_METHOD == 1) {
        llOwnerSay("\n1. Open Lovense Connect on your computer");
        llOwnerSay("2. Go to: Settings → Developer");
        llOwnerSay("3. Look for 'Local Network Info' section");
        llOwnerSay("4. Copy EXACTLY:");
        llOwnerSay("   - Local IP address");
        llOwnerSay("   - HTTPS Port (NOT HTTP port!)");
        llOwnerSay("5. Update this script with those exact values");
        llOwnerSay("6. Make sure you're on the same WiFi network");

    } else {
        llOwnerSay("\n1. Go to: https://www.lovense.com/user/developer/info");
        llOwnerSay("2. Copy your token (click to copy, don't manually select)");
        llOwnerSay("3. Paste directly into script (no manual editing)");
        llOwnerSay("4. Copy your User ID / UID");
        llOwnerSay("5. Make sure device is connected in Lovense Remote app");
        llOwnerSay("6. Try generating a NEW token if problem persists");
    }
}

// ============================================================================
// STATE: default
// ============================================================================

default {
    state_entry() {
        llOwnerSay("═══════════════════════════════════════");
        llOwnerSay("LOVENSE API DEBUG TOOL");
        llOwnerSay("═══════════════════════════════════════");
        llOwnerSay("\nThis tool will help diagnose your 401 error.");
        llOwnerSay("Touch to run diagnostics...\n");
    }

    touch_start(integer num_detected) {
        if (llDetectedKey(0) == llGetOwner()) {
            runDiagnostics();
        }
    }

    http_response(key request_id, integer status, list metadata, string body) {
        if (request_id != httpRequestId) return;

        llOwnerSay("\n4. RESPONSE RECEIVED:");
        llOwnerSay("   Status Code: " + (string)status);

        if (status == 200) {
            llOwnerSay("   ✅ SUCCESS! Connection working!");
            llOwnerSay("   Response: " + body);
            llOwnerSay("\n   Your configuration is CORRECT!");
            llOwnerSay("   You can now use the regular script.");

        } else if (status == 401) {
            llOwnerSay("   ❌ 401 UNAUTHORIZED");
            analyzeError(body);

        } else if (status == 499) {
            llOwnerSay("   ❌ REQUEST TIMEOUT (499)");
            llOwnerSay("\n   This means Second Life couldn't reach the server.");
            llOwnerSay("");

            if (CONNECTION_METHOD == 1) {
                llOwnerSay("   POSSIBLE CAUSES:");
                llOwnerSay("   • Wrong IP address (can't find server)");
                llOwnerSay("   • Lovense Connect not running");
                llOwnerSay("   • Firewall blocking connection");
                llOwnerSay("   • Not on same network");
                llOwnerSay("");
                llOwnerSay("   TEST: Can you ping " + LAN_IP + " from another device?");

            } else {
                llOwnerSay("   POSSIBLE CAUSES:");
                llOwnerSay("   • Internet connection down");
                llOwnerSay("   • Lovense servers temporarily unavailable");
                llOwnerSay("   • Firewall blocking outbound HTTPS");
            }

        } else if (status == 0) {
            llOwnerSay("   ❌ SSL CERTIFICATE ERROR (0)");
            llOwnerSay("\n   Second Life rejected the SSL certificate.");
            llOwnerSay("");

            if (CONNECTION_METHOD == 1) {
                llOwnerSay("   FIXES:");
                llOwnerSay("   • Make sure you're using the HTTPS port");
                llOwnerSay("   • Restart Lovense Connect");
                llOwnerSay("   • Update Lovense Connect to latest version");
                llOwnerSay("   • Lovense Connect generates its own SSL cert");

            } else {
                llOwnerSay("   This shouldn't happen with Lovense cloud API.");
                llOwnerSay("   Try again in a few minutes.");
            }

        } else {
            llOwnerSay("   ❌ HTTP ERROR: " + (string)status);
            llOwnerSay("   Response: " + body);
        }
    }
}

// ============================================================================
// STEP-BY-STEP FIX GUIDE
// ============================================================================

/*
═══════════════════════════════════════════════════════════════════════════
HOW TO FIX 401 ERRORS - STEP BY STEP
═══════════════════════════════════════════════════════════════════════════

STEP 1: Identify which method you're using
-------------------------------------------
Are you trying to use:
  A) LAN API (same network) - METHOD 1
  B) Cloud API (remote) - METHOD 2

If you're not sure, answer this:
→ Is Lovense Connect running on a computer on your network?
  YES = Use LAN API (METHOD 1)
  NO = Use Cloud API (METHOD 2)

STEP 2A: Fix LAN API (METHOD 1) - 401 Error
--------------------------------------------
1. Open Lovense Connect on your computer
2. Click the gear icon → Settings
3. Go to the "Developer" tab
4. You should see a section like this:

   ┌─────────────────────────────────┐
   │ Local Network Info              │
   ├─────────────────────────────────┤
   │ HTTP:  192.168.1.100:20010      │
   │ HTTPS: 192.168.1.100:30010      │ ← USE THIS ONE!
   └─────────────────────────────────┘

5. Copy the IP and port from the HTTPS line
6. In your LSL script, set:
   integer CONNECTION_METHOD = 1;
   string LAN_IP = "192.168.1.100";     // Your IP
   integer LAN_PORT = 30010;            // Your HTTPS port

7. Important: Do NOT set CLOUD_TOKEN or CLOUD_USER_ID
   The LAN API doesn't use them!

8. Save and test

STEP 2B: Fix Cloud API (METHOD 2) - 401 Error
----------------------------------------------
1. Go to: https://www.lovense.com/user/developer/info
2. Log in with your Lovense account
3. Find "Developer Token" section
4. Click the COPY button (don't manually select the text)
5. Paste into a text editor first to verify:
   - No spaces before or after
   - No newline characters
   - Should be a long string of letters/numbers

6. Also copy your "User ID" or "UID"

7. In your LSL script, set:
   integer CONNECTION_METHOD = 2;
   string CLOUD_TOKEN = "paste_here";   // Paste the token
   string CLOUD_USER_ID = "paste_here"; // Paste the user ID

8. Remove LAN_IP and LAN_PORT (not needed for cloud)

9. Save and test

STEP 3: Verify the request format
----------------------------------
Use this debug script to see exactly what's being sent.

LAN API should send:
{
  "command": "GetToys",
  "timeSec": 0,
  "apiVer": 1
}
// NO token or uid!

Cloud API should send:
{
  "command": "GetToys",
  "timeSec": 0,
  "apiVer": 1,
  "token": "your_token_here",
  "uid": "your_uid_here"
}
// WITH token and uid!

STEP 4: Still getting 401?
---------------------------
For LAN API:
  → Try restarting Lovense Connect
  → Make sure device is connected (green light in app)
  → Verify you're on the same WiFi network
  → Try accessing http://[your-ip]:[http-port] in a browser

For Cloud API:
  → Generate a NEW token in the developer portal
  → Verify the device is in your account
  → Make sure device is online in Lovense Remote app
  → Try logging out and back into Lovense account

STEP 5: Different error?
-------------------------
0 = SSL Certificate Error
  → Use HTTPS port, not HTTP port
  → Update Lovense Connect

499 = Timeout
  → Can't reach the server
  → Check IP/URL is correct
  → Check firewall settings

404 = Not Found
  → Wrong URL/endpoint
  → Check you're using /command at the end

═══════════════════════════════════════════════════════════════════════════
*/
