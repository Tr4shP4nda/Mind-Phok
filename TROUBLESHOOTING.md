# Troubleshooting Guide

This guide helps you resolve common issues with the Lovense + Second Life integration.

## Quick Diagnosis Tool

Use `lovense_debug.lsl` to automatically diagnose your issue:
1. Replace your current script with `lovense_debug.lsl`
2. Touch the object
3. Read the detailed diagnostic output
4. Follow the recommended fixes

## 401 Unauthorized Error

**This is the most common error!** A 401 error means authentication failed.

### The #1 Cause: Wrong Method Configuration

The most common mistake is using **LAN API settings with Cloud API authentication** or vice versa.

#### Are you using LAN API (METHOD 1)?

If `CONNECTION_METHOD = 1`, your request should **NOT** include token or uid:

```lsl
// ✅ CORRECT for LAN API
{
  "command": "Function",
  "action": "Vibrate:10",
  "timeSec": 10,
  "apiVer": 1
}
// NO token, NO uid!
```

```lsl
// ❌ WRONG for LAN API
{
  "command": "Function",
  "action": "Vibrate:10",
  "timeSec": 10,
  "apiVer": 1,
  "token": "...",    // ← Remove this!
  "uid": "..."       // ← Remove this!
}
```

**Fix:**
1. Make sure you're using the HTTPS port (usually 30010, NOT 20010)
2. Remove token and uid from your request
3. Verify you're on the same network as Lovense Connect

#### Are you using Cloud API (METHOD 2)?

If `CONNECTION_METHOD = 2`, your request **MUST** include valid token and uid:

```lsl
// ✅ CORRECT for Cloud API
{
  "command": "Function",
  "action": "Vibrate:10",
  "timeSec": 10,
  "apiVer": 1,
  "token": "your_actual_token",
  "uid": "your_user_id"
}
```

**Fix:**
1. Get a fresh token from https://www.lovense.com/user/developer/info
2. Copy the ENTIRE token (use the copy button, don't select manually)
3. Check for spaces or newlines in the token
4. Verify the User ID is correct

### LAN API - 401 Error Checklist

- [ ] Lovense Connect app is running
- [ ] Device is connected in Lovense Connect (green indicator)
- [ ] You're on the same WiFi/network as the computer running Connect
- [ ] Using the **HTTPS port** (30010), not HTTP port (20010)
- [ ] IP address matches exactly what's shown in Connect → Settings → Developer
- [ ] **NOT including** token or uid in the request
- [ ] Firewall allows connections to the port

**How to verify your settings:**

1. Open Lovense Connect
2. Settings (gear icon) → Developer tab
3. Look for "Local Network Info":
   ```
   HTTP:  192.168.1.100:20010
   HTTPS: 192.168.1.100:30010  ← Use this!
   ```
4. Use the IP and **HTTPS** port in your script

### Cloud API - 401 Error Checklist

- [ ] Token copied from developer portal
- [ ] Token has no spaces, newlines, or extra characters
- [ ] User ID is correct
- [ ] Device is connected in Lovense Remote app
- [ ] Device belongs to the account matching the token
- [ ] Internet connection is working
- [ ] Token hasn't expired (generate a new one to test)

**How to get fresh credentials:**

1. Go to https://www.lovense.com/user/developer/info
2. Click "Regenerate Token" to get a new one
3. Click the **Copy** button (don't manually select)
4. Paste directly into your script
5. Also copy the User ID / UID field

### Common Token Issues

**Problem:** Token looks like this in script:
```lsl
string CLOUD_TOKEN = "abc123
xyz789";  // ❌ Has newline!
```

**Fix:** Token should be on ONE line:
```lsl
string CLOUD_TOKEN = "abc123xyz789";  // ✅ Correct
```

**Problem:** Token has spaces:
```lsl
string CLOUD_TOKEN = " abc123xyz789 ";  // ❌ Has spaces
```

**Fix:** No spaces before or after:
```lsl
string CLOUD_TOKEN = "abc123xyz789";  // ✅ Correct
```

---

## 499 Request Timeout Error

This means Second Life couldn't reach the server at all.

### For LAN API (METHOD 1)

**Possible causes:**
- Lovense Connect not running
- Wrong IP address
- Not on the same network
- Firewall blocking the connection
- Wrong port

**How to fix:**

1. **Verify Lovense Connect is running:**
   - You should see it in your system tray / menu bar
   - Open it and check device is connected

2. **Test the connection manually:**
   - Open a browser on the same computer as SL
   - Try to access: `http://[your-ip]:20010`
   - You should see a Lovense Connect page

3. **Check you're on the same network:**
   - Computer and SL viewer on same WiFi?
   - Try from another device: can it ping the IP?

4. **Verify IP hasn't changed:**
   - Router may assign different IPs when restarting
   - Check Connect → Settings → Developer for current IP

5. **Check firewall:**
   - Windows: Allow Lovense Connect through firewall
   - Mac: System Preferences → Security → Firewall → Allow Lovense Connect

### For Cloud API (METHOD 2)

**Possible causes:**
- No internet connection
- Lovense servers temporarily down
- Firewall blocking HTTPS
- Wrong URL

**How to fix:**

1. **Test internet connection:**
   - Can you browse other websites?
   - Try accessing https://api.lovense.com in browser

2. **Check Lovense server status:**
   - Visit https://www.lovense.com
   - Check their Twitter/social media for outages

3. **Verify the URL:**
   - Should be: `https://api.lovense.com/api/lan/command`
   - Check for typos

---

## 0 SSL Certificate Error

This means the SSL certificate was rejected by Second Life.

### For LAN API

**Cause:** Using HTTP port instead of HTTPS port

**Fix:**
1. Use the **HTTPS** port (usually 30010)
2. In Lovense Connect → Settings → Developer, use the port labeled "HTTPS"
3. Make sure the URL starts with `https://` not `http://`

**Still not working?**
- Restart Lovense Connect
- Update Lovense Connect to the latest version
- Check that Lovense Connect is generating certificates properly

### For Cloud API

This shouldn't happen with Lovense's cloud servers.

**If it does:**
- Try again in a few minutes
- Check your Second Life viewer is up to date
- Contact Lovense support if persistent

---

## 404 Not Found Error

**Cause:** Wrong API endpoint URL

**Fix:**

For LAN API:
```lsl
// ✅ Correct
string url = "https://192.168.1.100:30010/command";

// ❌ Wrong - missing /command
string url = "https://192.168.1.100:30010";
```

For Cloud API:
```lsl
// ✅ Correct
string url = "https://api.lovense.com/api/lan/command";

// ❌ Wrong - typo
string url = "https://api.lovense.com/api/command";
```

---

## Device Doesn't Respond (No Error)

Command succeeds (200 OK) but device doesn't vibrate.

**Checklist:**

- [ ] Device is turned on
- [ ] Device is connected (check in Lovense app)
- [ ] Device battery is charged (check in app)
- [ ] Correct User ID (for Cloud API)
- [ ] Device belongs to the correct account
- [ ] No other app is controlling the device

**Test manually:**
1. Open Lovense Remote or Lovense Connect
2. Try controlling device from the app
3. If it doesn't work there, it's a device issue
4. If it works there, check User ID in your script

**Check intensity:**
- Some devices are quieter at low intensities
- Try intensity 20 to make sure it's working
- Some toys have different capabilities (vibrate vs rotate)

---

## Script Says "⚠️ Please configure..."

The script detected you haven't configured the required settings.

### For LAN API:

```lsl
// You need to set these:
string LAN_IP = "192.168.1.100";     // ← Your actual IP
integer LAN_PORT = 30010;             // ← Your actual HTTPS port

// Do NOT use the default values!
```

### For Cloud API:

```lsl
// You need to set these:
string CLOUD_TOKEN = "your_actual_token";   // ← Real token from portal
string CLOUD_USER_ID = "your_user_id";       // ← Real user ID

// Do NOT leave the placeholder text!
```

---

## Connection Works Sometimes, Fails Other Times

### For LAN API:

**Cause:** IP address changed

**Fix:**
- Router may reassign IP addresses
- Check Connect → Settings → Developer each time
- OR: Set a static IP for your computer in router settings

### For Cloud API:

**Cause:** Token expired or rate limiting

**Fix:**
- Generate a new token
- Don't send commands too rapidly (wait 500ms between commands)
- Check Lovense server status

---

## Multiple Devices - Wrong One Responding

**Cause:** Not specifying toy ID

**Fix:**

1. Get list of devices:
   ```lsl
   sendLovenseCommand("GetToys", "", 0);
   ```

2. Note the device IDs in the response

3. Specify the toy ID in your request:
   ```lsl
   string TOY_ID = "abc123";  // ID of specific device
   ```

4. Or in JSON:
   ```json
   {
     "command": "Function",
     "action": "Vibrate:10",
     "toy": "abc123"
   }
   ```

---

## Debugging Checklist

When something doesn't work:

1. **Use the debug script** (`lovense_debug.lsl`)
   - Shows exactly what's being sent
   - Diagnoses the issue automatically
   - Provides specific fix recommendations

2. **Check the basics:**
   - Is the device on and charged?
   - Is Lovense app running?
   - Is the device connected in the app?

3. **Verify your method:**
   - LAN API (METHOD 1) = no token/uid in request
   - Cloud API (METHOD 2) = must have token/uid

4. **Test manually first:**
   - Control device from Lovense app
   - If that doesn't work, it's not an API issue

5. **Check the error code:**
   - 401 = Authentication (see above)
   - 499 = Can't reach server (see above)
   - 0 = SSL certificate (see above)
   - 404 = Wrong URL (see above)

---

## Getting Help

Still stuck? Here's how to get help:

### Include This Information:

1. **Which script:** lovense_standalone.lsl or lovense_controller.lsl?
2. **Connection method:** LAN (1) or Cloud (2)?
3. **Error code:** 401, 499, 0, etc.
4. **What you've tried:** List the troubleshooting steps
5. **Debug output:** Run lovense_debug.lsl and share the output

### Where to Get Help:

- **GitHub Issues:** https://github.com/Tr4shP4nda/Mind-Phok/issues
- **Lovense Support:** For device/app issues
- **Second Life Forums:** For LSL scripting issues

### What NOT to share:

- ❌ Your developer token (keep this secret!)
- ❌ Your user ID if it contains personal info
- ✅ Error messages, debug output, configuration (without tokens)

---

## Quick Reference: Error Codes

| Code | Meaning | Most Common Fix |
|------|---------|----------------|
| 200 | Success | Everything's working! |
| 401 | Unauthorized | Check LAN vs Cloud settings, verify token |
| 499 | Timeout | Check IP/URL, verify app is running |
| 0 | SSL Error | Use HTTPS port (30010, not 20010) |
| 404 | Not Found | Check URL has `/command` at end |
| 405 | Method Not Allowed | Make sure using POST, not GET |
| 500 | Server Error | Lovense server issue, try again later |

---

## Prevention Tips

Avoid issues before they happen:

1. **Save your working configuration**
   - Once it works, document your exact settings
   - IP addresses can change after router restarts

2. **For LAN API:**
   - Set static IP on your computer
   - Or use DHCP reservation in router
   - Then the IP won't change

3. **For Cloud API:**
   - Save your token somewhere secure
   - Set script to NO COPY to protect it
   - Rotate token if script gets shared

4. **Test regularly:**
   - Device batteries die
   - Tokens can expire
   - IPs can change
   - Test before relying on it

5. **Keep apps updated:**
   - Update Lovense Connect/Remote
   - Update Second Life viewer
   - Newer versions fix bugs

---

**Remember:** 90% of issues are authentication-related. Double-check your CONNECTION_METHOD matches your setup (LAN vs Cloud) and that you're using the correct authentication for that method!
