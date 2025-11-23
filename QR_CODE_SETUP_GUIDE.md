# QR Code Linking Setup Guide

Complete guide for setting up Lovense device linking using QR codes - the most secure and user-friendly method!

## Why Use QR Code Method?

✅ **No token exposure** - Your developer token stays secure
✅ **No 401 errors** - Each user links their own device
✅ **User-friendly** - Just scan a QR code
✅ **More secure** - Users control their own connections
✅ **Production-ready** - Perfect for public/shared objects

## Overview

The QR code flow works like this:

```
1. User touches object → Requests QR code
2. LSL calls Lovense API → Gets QR code URL
3. User opens link → Sees QR code
4. User scans with Lovense Remote app → Links device
5. Lovense sends callback → Your server receives connection info
6. LSL fetches connection info → Stores for that user
7. LSL sends commands → Using stored connection info
```

## Quick Start (3 Options)

### Option A: Using Webhook.site (Easiest - No Coding!)

**Perfect for: Testing, learning, simple setups**

1. **Get a webhook URL:**
   - Go to https://webhook.site
   - Copy your unique URL (e.g., `https://webhook.site/12345678-abcd-...`)

2. **Set as callback URL:**
   - Go to https://www.lovense.com/user/developer/info
   - Paste webhook URL into "Callback URL" field
   - Save

3. **Configure LSL script:**
   ```lsl
   string DEVELOPER_TOKEN = "your_token_here";
   string CALLBACK_URL = "https://webhook.site/your-id";
   ```

4. **Manual linking process:**
   - User touches object → Gets QR code link
   - User scans QR code
   - Go to webhook.site page → See the callback
   - Copy `domain` and `httpsPort` from callback
   - In SL chat: `/99 link <domain> <port>`

**Pros:** No server needed, instant setup
**Cons:** Manual step required for linking

---

### Option B: Deploy Callback Receiver (Recommended)

**Perfect for: Production use, automated linking**

#### Step 1: Deploy the Receiver

**Option B1: Glitch.com (Easiest)**

1. Go to https://glitch.com
2. Click "New Project" → "glitch-hello-node"
3. Delete everything in `server.js`
4. Paste contents of `qr-callback-receiver.js`
5. Click `package.json` and add:
   ```json
   {
     "dependencies": {
       "express": "^4.18.2",
       "body-parser": "^1.20.2"
     }
   }
   ```
6. Your URL: `https://your-project-name.glitch.me`

**Option B2: Replit.com**

1. Go to https://replit.com
2. Create new Repl → Node.js
3. Paste `qr-callback-receiver.js` code
4. Click "Run"
5. Your URL: `https://your-repl-name.replit.app`

**Option B3: Railway.app**

1. Go to https://railway.app
2. New Project → Empty Project
3. Add → Node.js
4. Connect GitHub or paste code
5. Deploy
6. Get URL from Railway dashboard

#### Step 2: Configure Lovense

1. Go to https://www.lovense.com/user/developer/info
2. Set Callback URL: `https://your-deployed-url.com/lovense-callback`
3. Save

#### Step 3: Update LSL Script

```lsl
string DEVELOPER_TOKEN = "your_token_here";
string CALLBACK_URL = "https://your-deployed-url.com/lovense-callback";
string CALLBACK_API = "https://your-deployed-url.com";
```

#### Step 4: Enhanced LSL Script

Use the enhanced version that auto-fetches connection info:

```lsl
// After QR code is scanned, LSL automatically queries:
// GET https://your-deployed-url.com/get-connection/<avatar-uuid>
// Response: {"result":true,"data":{"domain":"...","httpsPort":"..."}}
```

**Pros:** Fully automated, production-ready
**Cons:** Requires deploying a simple server

---

### Option C: LAN API (Simplest Overall!)

**Perfect for: Personal use, same network**

If you just want it to work NOW:

1. Open Lovense Connect on your computer
2. Settings → Developer
3. Copy Local IP and HTTPS Port
4. Use `lovense_standalone.lsl` with METHOD = 1
5. Done!

**Pros:** Zero setup, works instantly
**Cons:** Must be on same network

---

## Detailed Setup: Option B (Recommended)

### 1. Deploy the Callback Receiver

I'll use Glitch as an example:

#### Create Project

1. **Go to Glitch.com** and sign up (free)

2. **Create new project:**
   - Click "New Project"
   - Select "glitch-hello-node"

3. **Replace server.js:**
   - Click on `server.js` in the file list
   - Delete all contents
   - Paste the entire contents of `qr-callback-receiver.js`

4. **Update package.json:**
   - Click on `package.json`
   - Replace the `dependencies` section with:
   ```json
   "dependencies": {
     "express": "^4.18.2",
     "body-parser": "^1.20.2"
   }
   ```

5. **Name your project:**
   - Click on project name at top left
   - Choose something memorable: `my-lovense-callback`

6. **Get your URL:**
   - Click "Share" button
   - Copy "Live Site" URL
   - Format: `https://my-lovense-callback.glitch.me`

#### Test the Receiver

1. **Check status:**
   - Open: `https://your-project.glitch.me/status`
   - Should see: `{"status":"online","connectedUsers":0,...}`

2. **If it works:** ✅ Your callback receiver is ready!

### 2. Configure Lovense Developer Portal

1. **Go to:** https://www.lovense.com/user/developer/info

2. **Set Callback URL:**
   ```
   https://your-project.glitch.me/lovense-callback
   ```

3. **Copy your Developer Token** (you'll need it for LSL)

4. **Save settings**

### 3. Configure LSL Script

Open `lovense_qrcode.lsl` and update:

```lsl
// Your developer token
string DEVELOPER_TOKEN = "paste_your_token_here";

// Your deployed callback receiver
string CALLBACK_URL = "https://your-project.glitch.me/lovense-callback";

// For fetching connection info
string CALLBACK_API = "https://your-project.glitch.me";
```

### 4. Deploy to Second Life

1. **Create an object** in Second Life
2. **Add the script:**
   - Right-click object → Edit
   - Content tab → New Script
   - Paste `lovense_qrcode.lsl`
   - Save

3. **Test it:**
   - Touch the object
   - Click "Link Device"
   - You should see "QR Code generated!"
   - Click the link to see QR code

### 5. Link Your Device

1. **Open Lovense Remote** app on your phone

2. **Tap the QR code scanner:**
   - Look for camera icon or "Scan QR Code"

3. **Scan the QR code** from the link

4. **Device links automatically!**
   - Your callback receiver gets the connection info
   - LSL fetches it and stores it
   - You're ready to use the controller!

---

## Enhanced LSL Script (Auto-Fetch)

Here's an enhanced version that automatically fetches connection info after QR scan:

```lsl
// Add this to your script:

string CALLBACK_API = "https://your-project.glitch.me";

// After user scans QR code, poll for connection info
pollForConnection(key avatarKey) {
    string url = CALLBACK_API + "/get-connection/" + (string)avatarKey;

    list headers = [
        HTTP_METHOD, "GET",
        HTTP_VERIFY_CERT, TRUE
    ];

    httpRequestId = llHTTPRequest(url, headers, "");
}

// In http_response, add:
http_response(key request_id, integer status, list metadata, string body) {
    // ... existing code ...

    // Check if this is a connection fetch response
    if (llSubStringIndex(body, "\"domain\":") != -1) {
        // Parse domain and port
        integer domainPos = llSubStringIndex(body, "\"domain\":\"");
        if (domainPos != -1) {
            string afterDomain = llGetSubString(body, domainPos + 10, -1);
            integer domainEnd = llSubStringIndex(afterDomain, "\"");
            string domain = llGetSubString(afterDomain, 0, domainEnd - 1);

            integer portPos = llSubStringIndex(body, "\"httpsPort\":\"");
            string afterPort = llGetSubString(body, portPos + 13, -1);
            integer portEnd = llSubStringIndex(afterPort, "\"");
            string port = llGetSubString(afterPort, 0, portEnd - 1);

            // Store connection
            storeUserConnection(currentLinkingUser, domain, port);
        }
    }
}

// After showing QR code, start polling:
llSetTimerEvent(5.0);  // Check every 5 seconds

timer() {
    if (currentLinkingUser != NULL_KEY && !isUserLinked(currentLinkingUser)) {
        pollForConnection(currentLinkingUser);
    } else {
        llSetTimerEvent(0.0);  // Stop polling
    }
}
```

---

## Troubleshooting

### QR Code Doesn't Generate

**Error: "Invalid token"**
- Check your developer token is correct
- Try regenerating token in developer portal

**Error: Timeout or no response**
- Verify Lovense API is accessible
- Check your internet connection

### QR Code Generated But Scan Fails

**"Invalid QR code" in app**
- Make sure using Lovense Remote app (not Connect)
- Try updating the app
- Check QR code image loads fully

### Callback Not Received

**Check callback receiver:**
```
https://your-project.glitch.me/status
```
Should show: `"status":"online"`

**Check Lovense developer portal:**
- Callback URL is set correctly
- URL is HTTPS (not HTTP)
- No typos in URL

**Check Glitch logs:**
- Click "Tools" → "Logs" in Glitch
- Watch for incoming requests when QR is scanned

### Connection Info Not Stored

**If using webhook.site:**
- Manually enter connection info with `/99 link <domain> <port>`

**If using callback receiver:**
- Check receiver is online: `/status` endpoint
- Verify callback was received: `/list-connections` endpoint
- Check LSL is polling: Add debug output to script

---

## Security Notes

✅ **Good security practices:**
- Developer token never exposed to users
- Each user links their own device
- Connection info stored per-user
- Users can unlink anytime

⚠️ **Remember:**
- Don't share your developer token publicly
- Use HTTPS for callback URL
- Consider adding authentication to callback receiver
- Clean up old connections periodically

---

## Cost Comparison

| Method | Setup | Cost | Complexity |
|--------|-------|------|------------|
| Webhook.site | 2 min | Free | Very Easy |
| Glitch/Replit | 10 min | Free | Easy |
| Railway/Heroku | 15 min | Free tier | Medium |
| Own server | 30+ min | $5-20/mo | Hard |
| LAN API | 2 min | Free | Very Easy |

---

## Next Steps

Once QR code linking is working:

1. **Customize the menu** - Add your own patterns
2. **Add access control** - Whitelist specific users
3. **Create patterns** - Custom vibration sequences
4. **Build HUD** - Attach controller to screen
5. **Add features** - Timers, random modes, etc.

---

## FAQ

**Q: Do users need developer accounts?**
A: No! Only you need a developer account. Users just scan and link.

**Q: Can multiple users use the same object?**
A: Yes! Each user links their own device independently.

**Q: How long do links last?**
A: Until the user unlinks or the receiver restarts (use database for persistence).

**Q: Can I use this for commercial purposes?**
A: Check Lovense's terms of service for commercial API usage.

**Q: What if my callback receiver goes down?**
A: Users will need to re-link. Use a reliable hosting service or database storage.

**Q: Can I avoid running a server?**
A: Yes! Use webhook.site with manual linking, or use LAN API instead.

---

## Support

- **Script issues:** Check TROUBLESHOOTING.md
- **Callback receiver:** Check server logs
- **Lovense API:** Contact Lovense support
- **GitHub:** Open an issue in the repository

---

**You're all set!** The QR code method is the most user-friendly and secure approach. Your users will love how easy it is! 🎉
