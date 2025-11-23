# Advanced 401 Fixes: When Your Token IS Correct

If you're **absolutely sure** your token is correct (no copy/paste issues) but still getting:
```json
{"result":false,"code":401,"message":"Invalid token!"}
```

Then the issue is likely one of these:

## Root Cause #1: Token & UID Mismatch

The **most common** cause when the token itself is valid.

### The Problem
Your `token` and `uid` must belong to the **same Lovense account**. If they don't match, you'll get 401.

### How It Happens
```
Scenario: You have two Lovense accounts
- Account A (your@email.com) - where you got the developer token
- Account B (other@email.com) - where the device is registered

You use:
- token from Account A ✓
- uid from Account B ✗
Result: 401 "Invalid token"
```

### The Fix

1. **Go to developer portal** while logged into the account with the devices:
   - https://www.lovense.com/user/developer/info

2. **Make sure you're logged into the RIGHT account:**
   - Check the email/username shown in top right
   - This MUST be the account that owns the devices

3. **Get BOTH from the SAME page:**
   - Developer Token → copy this
   - User ID / UID → copy this
   - They must be from the same logged-in account!

4. **Verify device ownership:**
   - Open Lovense Remote app
   - Check you're logged into the SAME account
   - Verify your device appears in the app

### How to Check

```lsl
// Add this to your script to verify
state_entry() {
    llOwnerSay("Account check:");
    llOwnerSay("Token account: [check developer portal]");
    llOwnerSay("UID account: " + CLOUD_USER_ID);
    llOwnerSay("Device account: [check Remote app]");
    llOwnerSay("\n^^^ All three MUST match! ^^^");
}
```

---

## Root Cause #2: UID Format Is Wrong

### The Problem
The `uid` field might need a different format than you're using.

### Possible UID Formats

Lovense uses different UID formats depending on context:

```
Format 1: Email address
"uid": "your@email.com"

Format 2: Numeric ID
"uid": "12345678"

Format 3: Username
"uid": "yourusername"

Format 4: Alphanumeric hash
"uid": "abc123def456"
```

### The Fix

1. **Check the developer portal page carefully:**
   - Look for fields labeled: "User ID", "UID", "Your ID", "Account ID"
   - Copy EXACTLY what's shown (might not be your email!)

2. **Try different formats:**
   - If using email, try without the email
   - If using username, try the email instead
   - Check if there's a numeric ID option

3. **Look in Lovense Remote app:**
   - Settings → About or Account
   - May show your actual UID

### Test Script

```lsl
// Test different UID formats
list possibleUIDs = [
    "your@email.com",        // Email
    "yourusername",          // Username
    "12345678",              // Numeric (if you have one)
    "firstName.lastName"     // Name format
];

// Script cycles through them automatically
```

---

## Root Cause #3: Callback URL Not Set

### The Problem
Some Lovense API features **require** a callback URL to be set in your developer settings, even if you're not using callbacks.

### The Fix

1. **Go to:** https://www.lovense.com/user/developer/info

2. **Find "Callback URL" field**

3. **Set ANY valid HTTPS URL:**
   ```
   Examples (use any of these):
   https://example.com/callback
   https://your-website.com/lovense
   https://webhook.site/[get-unique-url]
   ```

   Note: It must be HTTPS, but it doesn't need to exist or work!

4. **Save settings**

5. **Try your API call again**

### Why This Matters
Even for "direct" API calls, Lovense may validate that you have a callback URL configured as part of your developer account verification.

---

## Root Cause #4: Developer Account Not Verified

### The Problem
Your developer account may need additional verification or approval.

### Check Account Status

1. **Go to:** https://www.lovense.com/user/developer/info

2. **Look for account status indicators:**
   - "Account Status: Active" ✓
   - "Account Status: Pending" ✗
   - "Verification Required" ✗
   - Any warning messages

3. **Check email** for verification requests from Lovense

### The Fix

- Complete any verification steps requested
- Verify your email address
- Wait for account approval (may take 24-48 hours)
- Contact Lovense support if stuck in "Pending"

---

## Root Cause #5: API Endpoint Mismatch

### The Problem
You might be using an endpoint that doesn't support direct token auth.

### Try Alternative Endpoints

The official endpoint should be:
```
https://api.lovense.com/api/lan/command
```

But you can try:
```
https://api.lovense.com/api/lan/v2/command
https://api.lovense-api.com/api/lan/command
```

### Or Use QR Code Flow Instead

The **QR Code method** doesn't use your developer token directly:

1. **Generate QR code:**
   ```
   POST https://api.lovense.com/api/lan/getQrCode
   {
     "token": "your_developer_token",
     "uid": "your_uid",
     "uname": "display_name",
     "utoken": "random_string_you_generate",
     "v": 2
   }
   ```

2. **User scans QR code** with Lovense Remote app

3. **You receive callback** with connection info

4. **Send commands** to the callback-provided endpoint

This method avoids the 401 issue entirely!

---

## Root Cause #6: Token Type Mismatch

### The Problem
There might be different "types" of tokens for different API access levels.

### Check Token Details

On the developer portal page, look for:
- "API Type": Standard, Premium, Cam, etc.
- "Access Level": Basic, Advanced, etc.
- Any mentions of "upgrade" or "request access"

### The Fix

- You may need to apply for higher-level API access
- Check if there's an "API Key" vs "Developer Token" distinction
- Contact Lovense support to verify your access level

---

## Root Cause #7: Regional/Account Restrictions

### The Problem
Your account or region may have API restrictions.

### Possible Issues

1. **Geographic restrictions:**
   - Some regions may have limited API access
   - Try using a VPN to test

2. **Account age:**
   - New accounts may have temporary restrictions
   - Wait 24-48 hours after account creation

3. **Usage limits:**
   - Check if there are request limits
   - You may have hit a rate limit

---

## Diagnostic Checklist

Work through this systematically:

- [ ] Token and UID from the **exact same** logged-in account
- [ ] Device is registered in that account (check Remote app)
- [ ] Developer portal shows account as "Active"
- [ ] Callback URL is set (even if you don't use it)
- [ ] Email address is verified
- [ ] Account is more than 24 hours old
- [ ] Tried exact UID format from developer portal
- [ ] Tried alternative UID formats (email, username, ID)
- [ ] No typos in token or UID (paste into notepad to verify)
- [ ] Using correct endpoint URL
- [ ] Device is online and connected in Remote app

---

## The Nuclear Option: Start Fresh

If nothing works:

1. **Create a brand new Lovense account:**
   - Use a different email
   - Fresh account, fresh devices

2. **Register your device to the new account**

3. **Get developer token from the new account**

4. **Use the new account's UID**

5. **Test with the new credentials**

This eliminates any legacy account issues.

---

## Alternative: Use LAN API Instead

If Cloud API continues to fail, **LAN API is much simpler:**

```lsl
// LAN API - NO token or UID needed!
integer CONNECTION_METHOD = 1;
string LAN_IP = "192.168.1.100";  // From Lovense Connect
integer LAN_PORT = 30010;          // From Lovense Connect

// That's it! No authentication headaches!
```

**Advantages:**
- No token/UID issues
- No account verification needed
- Works immediately
- More secure (local only)

**Requirements:**
- Same network as computer running Lovense Connect
- Lovense Connect app must be running

---

## Get Help from Lovense

If you've tried everything:

1. **Contact Lovense Support:**
   - Go to: https://www.lovense.com/
   - Click "Contact Us" or "Support"
   - Explain you're a developer getting 401 errors

2. **Include this info:**
   - "I'm getting 401 'Invalid token' errors"
   - "Token and UID are from the same account"
   - "Account appears active in developer portal"
   - "Device is connected in Remote app"
   - "I've tried [list what you tried]"

3. **Ask them to verify:**
   - Is my developer account fully activated?
   - Are there any restrictions on my account?
   - What should my UID format be?
   - Is my token valid and active?

---

## Success Stories

What actually fixed it for others:

**"It was the UID!"**
> "My UID was showing as my email, but I needed to use my username instead. Check both!"

**"Callback URL was missing"**
> "Even though I wasn't using callbacks, I had to set a callback URL in developer settings."

**"Wrong account"**
> "I had two accounts - token from one, device in the other. Made sure both were from same account."

**"Account not verified"**
> "My account was in 'pending verification' status. Completed verification and it worked immediately."

**"Just switched to LAN API"**
> "Cloud API was a nightmare. LAN API worked instantly with zero configuration."

---

## Final Thoughts

The Lovense API can be tricky with authentication. If you've verified:
- ✅ Token is correct (no copy/paste issues)
- ✅ Token and UID from same account
- ✅ Account is active
- ✅ Callback URL is set

And it STILL doesn't work, seriously consider:
1. **Using LAN API** instead (way easier!)
2. **Using QR Code flow** (no token issues)
3. **Contacting Lovense support** (they can check server-side)

Don't bang your head against the wall for days - sometimes it's an issue on their end that only they can fix!
