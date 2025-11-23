# Fix: Invalid Token Error

If you're getting this exact response:
```json
{"result":false,"code":401,"message":"Invalid token!"}
```

You're successfully connecting to Lovense servers, but your token is invalid.

## Step-by-Step Fix

### Step 1: Get a Fresh Token

The token may have expired or been regenerated. Get a new one:

1. **Go to:** https://www.lovense.com/user/developer/info
2. **Log in** with your Lovense account (the one that owns the devices)
3. **Click "Regenerate Token"** (this creates a fresh token)
4. **Click the "Copy" button** next to the token (don't select manually)

### Step 2: Verify Token Format

Before pasting into your script, check the token:

1. **Paste into a text editor first** (Notepad, TextEdit, etc.)
2. **Check for:**
   - No spaces before or after the token
   - No newline characters (should be one single line)
   - Token is typically 30-50+ characters long
   - Contains letters, numbers, possibly dashes/underscores

**Example of what it should look like:**
```
abcdef123456789ghijklmnop-qrstuvwxyz_0123456789
```

**NOT like this:**
```
abcdef123456789
ghijklmnop         ← ❌ Has newline!
```

**NOT like this:**
```
 abcdef123456789   ← ❌ Has spaces!
```

### Step 3: Update Your LSL Script Correctly

```lsl
// Make sure you're using Cloud API method
integer CONNECTION_METHOD = 2;

// Paste your fresh token here (the ENTIRE thing, one line)
string CLOUD_TOKEN = "paste_your_copied_token_here";

// Also verify your User ID
string CLOUD_USER_ID = "your_user_id_or_email";
```

### Step 4: Verify User ID

The User ID must match the account that owns the token:

1. On the same page (developer info), look for "User ID" or "UID"
2. This might be:
   - Your email address
   - A numeric ID
   - Your username
3. Copy this exactly

### Step 5: Test with Simple Request

Use this minimal test to verify:

```lsl
// Test script
default {
    touch_start(integer num) {
        string url = "https://api.lovense.com/api/lan/command";

        string body = "{\"command\":\"GetToys\",\"apiVer\":1,\"token\":\"YOUR_TOKEN\",\"uid\":\"YOUR_UID\"}";

        list headers = [
            HTTP_METHOD, "POST",
            HTTP_MIMETYPE, "application/json"
        ];

        llHTTPRequest(url, headers, body);
        llOwnerSay("Request sent...");
    }

    http_response(key id, integer status, list meta, string body) {
        llOwnerSay("Status: " + (string)status);
        llOwnerSay("Response: " + body);
    }
}
```

Replace `YOUR_TOKEN` and `YOUR_UID` with your actual values.

**Expected responses:**

✅ **Success:**
```json
{"result":true,"code":200,"message":"Success","data":{...}}
```

❌ **Still invalid:**
```json
{"result":false,"code":401,"message":"Invalid token!"}
```

## Common Issues & Solutions

### Issue 1: Token Was Copied Wrong

**Symptoms:** Token looks correct but still fails

**Fix:**
1. Don't manually select the token text
2. Use the **Copy button** on the developer portal
3. Or triple-click to select entire line, then copy
4. Paste into text editor to verify it's one line

### Issue 2: Old Token Still in Use

**Symptoms:** You updated the token but still get 401

**Fix:**
1. After changing the script, **save it** (Ctrl+S / Cmd+S)
2. The script needs to recompile
3. Or delete the script and add it fresh
4. Check the script actually has your new token (read it back)

### Issue 3: Wrong Lovense Account

**Symptoms:** Token is valid but device doesn't respond

**Fix:**
1. Make sure you're logged into the **correct** Lovense account
2. The account must **own** the devices you're trying to control
3. Check in Lovense Remote app that the device is listed
4. The token and devices must belong to the **same** account

### Issue 4: Token Type Mismatch

**Symptoms:** Have multiple tokens, not sure which to use

**Fix:**
1. Use the token from the **Developer** section
2. NOT from any other API or integration
3. The page should be: https://www.lovense.com/user/developer/info
4. Section should say "Developer Token" or "API Token"

### Issue 5: Formatting in LSL Script

**Symptoms:** Token works in curl/Postman but not in LSL

**Fix:**

Make sure the token is in quotes and on one line:

```lsl
// ✅ CORRECT
string CLOUD_TOKEN = "abc123xyz789fulltoken";

// ❌ WRONG - broken across lines
string CLOUD_TOKEN = "abc123
xyz789";

// ❌ WRONG - missing quotes
string CLOUD_TOKEN = abc123xyz789;

// ❌ WRONG - has spaces
string CLOUD_TOKEN = "abc123 xyz789";
```

### Issue 6: Special Characters in Token

**Symptoms:** Token has unusual characters

**Fix:**
1. Lovense tokens are alphanumeric with possibly dashes/underscores
2. If your token has quotes or other special characters, you may need to escape them
3. But typically, just copying from the portal should work

## Advanced Verification

### Test Token with curl (Outside of SL)

To verify the token works at all:

```bash
curl -X POST https://api.lovense.com/api/lan/command \
  -H "Content-Type: application/json" \
  -d '{
    "command": "GetToys",
    "apiVer": 1,
    "token": "YOUR_TOKEN_HERE",
    "uid": "YOUR_UID_HERE"
  }'
```

**If this returns 401:** Token is definitely invalid, regenerate it
**If this returns 200:** Token is valid, issue is in LSL script

### Check Developer Portal Settings

On the developer info page, verify:

1. **Token is not blank** - click "Show Token" if hidden
2. **Callback URL** - can be anything, doesn't affect API calls
3. **Status** - account should be active/verified

### Still Not Working?

Try these:

1. **Log out and back in** to Lovense account
2. **Clear browser cache** before copying token
3. **Try a different browser** when copying token
4. **Contact Lovense support** - token system might have issues

## Working Example

Here's a complete working example with proper formatting:

```lsl
// Lovense Cloud API - Correct Format
integer CONNECTION_METHOD = 2;

// Token from https://www.lovense.com/user/developer/info
// Example (yours will be different):
string CLOUD_TOKEN = "9d8f7a6b5c4e3d2f1a0b9c8d7e6f5a4b3c2d1e0f";

// User ID from same page
string CLOUD_USER_ID = "user@example.com";

// Rest of the script...
default {
    state_entry() {
        llOwnerSay("Token length: " + (string)llStringLength(CLOUD_TOKEN));
        // Should be 30-50+ characters

        // Check for common issues
        if (llSubStringIndex(CLOUD_TOKEN, " ") != -1) {
            llOwnerSay("ERROR: Token has spaces!");
        }
        if (llSubStringIndex(CLOUD_TOKEN, "\n") != -1) {
            llOwnerSay("ERROR: Token has newlines!");
        }
        if (CLOUD_TOKEN == "YOUR_DEVELOPER_TOKEN") {
            llOwnerSay("ERROR: Token not set!");
        }
    }

    touch_start(integer num) {
        // Build request
        string json = "{";
        json += "\"command\":\"GetToys\"";
        json += ",\"apiVer\":1";
        json += ",\"token\":\"" + CLOUD_TOKEN + "\"";
        json += ",\"uid\":\"" + CLOUD_USER_ID + "\"";
        json += "}";

        llOwnerSay("Sending: " + json);

        list headers = [
            HTTP_METHOD, "POST",
            HTTP_MIMETYPE, "application/json"
        ];

        key req = llHTTPRequest("https://api.lovense.com/api/lan/command",
                                headers, json);
        llOwnerSay("Request sent, waiting...");
    }

    http_response(key id, integer status, list meta, string body) {
        llOwnerSay("═══════════════════════════════");
        llOwnerSay("Status: " + (string)status);
        llOwnerSay("Response: " + body);
        llOwnerSay("═══════════════════════════════");

        if (llSubStringIndex(body, "\"result\":true") != -1) {
            llOwnerSay("✅ SUCCESS! Token is valid!");
        } else if (llSubStringIndex(body, "Invalid token") != -1) {
            llOwnerSay("❌ Token is invalid - regenerate it!");
        }
    }
}
```

## Quick Checklist

Before asking for more help, verify:

- [ ] Token was regenerated (fresh) in last 5 minutes
- [ ] Token copied using Copy button (not manual selection)
- [ ] Token is ONE line with NO spaces
- [ ] Token is 30+ characters long
- [ ] User ID matches the account that owns token
- [ ] Device is connected in Lovense Remote app
- [ ] Tested token with curl (if possible)
- [ ] Saved LSL script after changing token
- [ ] Script recompiled (no syntax errors)

---

If you've done ALL of the above and still get 401, the issue may be:
- Lovense account problem (contact support)
- API service disruption (check status)
- Regional restrictions (VPN might help)

But 99% of the time, it's just a copy/paste issue with the token! 😊
