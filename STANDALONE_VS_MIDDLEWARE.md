# Standalone vs Middleware: Which Should You Use?

This guide helps you choose between the standalone LSL approach and the middleware server approach.

## Quick Decision Chart

```
Do you want to control your own device from SL?
├─ Are you on the same network as your computer running Lovense Connect?
│  ├─ YES → Use STANDALONE (LAN API) ✅ BEST OPTION
│  └─ NO → Read security concerns below
│
└─ Do you want others to control your device?
   └─ Use MIDDLEWARE SERVER or QR CODE method
```

## Comparison Table

| Feature | Standalone (LAN) | Standalone (Cloud) | Middleware Server |
|---------|------------------|--------------------|--------------------|
| **Setup Complexity** | ⭐⭐☆☆☆ Easy | ⭐☆☆☆☆ Very Easy | ⭐⭐⭐⭐☆ Complex |
| **Security** | ⭐⭐⭐⭐⭐ Excellent | ⭐☆☆☆☆ Poor | ⭐⭐⭐⭐☆ Good |
| **Requires Server** | ❌ No | ❌ No | ✅ Yes |
| **Works Remotely** | ❌ No | ✅ Yes | ✅ Yes |
| **Latency** | ⭐⭐⭐⭐⭐ Lowest | ⭐⭐⭐☆☆ Medium | ⭐⭐⭐☆☆ Medium |
| **Privacy** | ⭐⭐⭐⭐⭐ Best | ⭐⭐☆☆☆ Poor | ⭐⭐⭐⭐☆ Good |
| **Credential Exposure** | ✅ None | ❌ High Risk | ✅ Protected |
| **Multi-User Support** | ⚠️ Limited | ⚠️ Limited | ✅ Excellent |
| **Rate Limiting** | ⚠️ Manual | ⚠️ Manual | ✅ Automatic |
| **Logging** | ❌ Basic | ❌ Basic | ✅ Advanced |

## Detailed Comparison

### Standalone - LAN API Method

**Use this when:**
- ✅ You're controlling your own device
- ✅ Your computer and Second Life are on the same network
- ✅ You want the simplest, most secure setup
- ✅ You want lowest latency
- ✅ Privacy is important

**Don't use when:**
- ❌ You need to control devices remotely
- ❌ Multiple users need different device access
- ❌ You need advanced logging/monitoring

**Setup Steps:**
1. Open Lovense Connect → Settings → Developer
2. Copy Local IP and HTTPS Port
3. Set in LSL script: `LAN_IP` and `LAN_PORT`
4. Done!

**Example Configuration:**
```lsl
integer CONNECTION_METHOD = 1;  // LAN API
string LAN_IP = "192.168.1.100";
integer LAN_PORT = 30010;
```

**Pros:**
- 🔒 Most secure - no credentials exposed
- 🚀 Lowest latency (local network)
- 🔌 Works offline
- 📦 No server needed
- 💰 No hosting costs
- 🛡️ No credential management

**Cons:**
- 📍 Must be on same network
- 💻 Lovense Connect must be running
- 🌐 Can't control remotely
- 👤 Limited multi-user support

**Security Rating:** ⭐⭐⭐⭐⭐ Excellent
- No credentials in script
- Local network only
- SSL encrypted

---

### Standalone - Cloud API Method

**Use this when:**
- ⚠️ You understand the security risks
- ⚠️ You're the ONLY person with script access
- ✅ You need remote access
- ✅ You can't use LAN API
- ✅ You don't want to manage a server

**Don't use when:**
- ❌ Others can read the script
- ❌ Script might be copied
- ❌ You need production security
- ❌ Multiple users need access

**Setup Steps:**
1. Get developer token from https://www.lovense.com/user/developer/info
2. Set in LSL script: `CLOUD_TOKEN` and `CLOUD_USER_ID`
3. Set script to NO COPY, NO TRANSFER
4. Done!

**Example Configuration:**
```lsl
integer CONNECTION_METHOD = 2;  // Cloud API
string CLOUD_TOKEN = "your_token_here";
string CLOUD_USER_ID = "your_user_id";
```

**Pros:**
- 🌍 Works from anywhere
- 📦 No server needed
- 💰 No hosting costs
- ⚡ Quick setup

**Cons:**
- ⚠️ **MAJOR SECURITY RISK** - token visible in script
- 🔓 Anyone with script access can steal credentials
- 🎯 Token could be used to control your devices
- 📜 Script must be NO COPY to prevent spreading
- 🚨 If script leaks, must regenerate token

**Security Rating:** ⭐☆☆☆☆ Poor
- Credentials hardcoded in script
- Visible to anyone who can read script
- Risk of credential theft

**🔴 CRITICAL WARNING:**
```
If you use this method and your script gets copied, someone
could use your token to control your Lovense devices without
your permission!

ONLY use this if:
✓ You're the ONLY person with script access
✓ Script permissions are NO COPY, NO TRANSFER
✓ You accept the security risk
✓ You can regenerate the token if compromised
```

---

### Middleware Server Method

**Use this when:**
- ✅ Multiple users need access
- ✅ You need production-level security
- ✅ You need advanced features (logging, rate limiting)
- ✅ You want centralized control
- ✅ You can manage a server

**Don't use when:**
- ❌ You want the simplest setup
- ❌ You can't manage/afford a server
- ❌ You only need personal use

**Setup Steps:**
1. Set up a server with valid SSL certificate
2. Deploy middleware (Node.js example provided)
3. Configure server with your Lovense credentials
4. Point LSL script to your server URL
5. Done!

**Example Configuration:**
```lsl
// In LSL script
string SERVER_URL = "https://your-server.com/lovense/command";

// On server (config.json)
{
  "lovense": {
    "developer_token": "your_token",
    "user_id": "your_user_id"
  }
}
```

**Pros:**
- 🔒 Secure - credentials not in LSL
- 👥 Multi-user support
- 📊 Advanced logging
- 🛡️ Rate limiting
- 🎛️ Centralized control
- 🔧 Customizable
- 🌍 Works remotely

**Cons:**
- 🖥️ Requires server setup
- 💰 Hosting costs
- 🔧 More maintenance
- ⚙️ More complex
- 🌐 Requires valid SSL certificate

**Security Rating:** ⭐⭐⭐⭐☆ Good
- Credentials secured on server
- Not visible in LSL script
- Access control possible
- Can implement additional security layers

---

## Security Comparison

### Credential Exposure Risk

**LAN API (Standalone):**
```
✅ NO credentials in script
✅ Local network only
✅ SSL encrypted
Risk Level: MINIMAL
```

**Cloud API (Standalone):**
```
❌ Developer token in script
❌ User ID in script
❌ Anyone with script access can see/use
Risk Level: HIGH
```

**Middleware Server:**
```
✅ NO credentials in LSL script
✅ Credentials secured on server
✅ Server access controlled
⚠️ Server must be secured
Risk Level: LOW
```

### Attack Vectors

| Attack Vector | LAN | Cloud | Middleware |
|--------------|-----|-------|------------|
| Script copying | ✅ Safe | ❌ Credentials stolen | ✅ Safe |
| Network sniffing | ✅ Local only | ⚠️ SSL encrypted | ⚠️ SSL encrypted |
| Token theft | ✅ No token | ❌ Easy | ✅ Protected |
| Unauthorized use | ✅ Network required | ❌ Token = full access | ✅ Server controls |

## Performance Comparison

### Latency

```
LAN API:          SL → Local Network → Device
                  ⚡ ~50-100ms (fastest)

Cloud API:        SL → Lovense Cloud → Device
                  ⏱️ ~200-500ms (medium)

Middleware:       SL → Your Server → Lovense Cloud → Device
                  ⏱️ ~300-600ms (slowest)
```

### Reliability

**LAN API:**
- ✅ No internet dependency
- ⚠️ Lovense Connect must be running
- ⚠️ Must be on same network

**Cloud API:**
- ⚠️ Internet required
- ⚠️ Lovense servers must be up
- ✅ No local software needed

**Middleware:**
- ⚠️ Internet required
- ⚠️ Your server must be up
- ⚠️ Lovense servers must be up
- ✅ You control middleware uptime

## Cost Comparison

| Method | Initial Cost | Ongoing Cost | Total (1 year) |
|--------|--------------|--------------|----------------|
| **LAN API** | $0 | $0 | **$0** |
| **Cloud API** | $0 | $0 | **$0** |
| **Middleware** | ~$5-50 | ~$5-10/month | **$60-170** |

Middleware costs depend on hosting:
- Shared hosting: ~$5-10/month
- VPS: ~$5-20/month
- Cloud (AWS/GCP): ~$10-50/month

## Feature Comparison

| Feature | LAN | Cloud | Middleware |
|---------|-----|-------|------------|
| Basic vibration control | ✅ | ✅ | ✅ |
| Pattern control | ✅ | ✅ | ✅ |
| Device status | ✅ | ✅ | ✅ |
| Multi-device | ✅ | ✅ | ✅ |
| Rate limiting | ⚠️ Manual | ⚠️ Manual | ✅ Auto |
| Access control | ⚠️ Basic | ⚠️ Basic | ✅ Advanced |
| Logging | ❌ | ❌ | ✅ |
| Analytics | ❌ | ❌ | ✅ Possible |
| Webhooks | ❌ | ❌ | ✅ |
| Custom patterns | ✅ | ✅ | ✅ Enhanced |

## Recommendations by Use Case

### Personal Use - Same Network
```
📍 RECOMMENDED: Standalone LAN API

Why:
✓ Simplest setup
✓ Most secure
✓ Best performance
✓ Zero cost

Use: lovense_standalone.lsl with METHOD 1
```

### Personal Use - Remote Access
```
⚠️  OPTIONS:

Option A: Standalone Cloud API (if you accept risks)
  - Quick setup
  - Security risks
  - Use with NO COPY script

Option B: Middleware Server (more secure)
  - Better security
  - More setup
  - Ongoing costs

Recommendation: Middleware if security matters
```

### Public/Multi-User Object
```
📍 RECOMMENDED: Middleware Server + QR Code

Why:
✓ No credential exposure
✓ Users control their own devices
✓ Production-ready security
✓ Multi-user support

Alternative: QR Code linking (more complex)
```

### Development/Testing
```
📍 RECOMMENDED: Standalone LAN API

Why:
✓ Quick iteration
✓ No server needed
✓ Easy debugging
✓ Can switch to middleware for production
```

## Migration Paths

### Starting Simple → Scaling Up

```
Phase 1: Development
└─ Standalone LAN API
   └─ Quick testing and development

Phase 2: Personal Remote Use
├─ Option A: Standalone Cloud (risks accepted)
└─ Option B: Migrate to Middleware

Phase 3: Public Release
└─ Middleware Server + proper auth
   └─ Production-ready security
```

### Code Changes Required

**LAN → Cloud Standalone:**
```lsl
// Change only this:
integer CONNECTION_METHOD = 1;  // Change to 2
// Add credentials
```

**Standalone → Middleware:**
```lsl
// Change URL:
string SERVER_URL = "https://your-server.com/lovense/command";
// Remove credentials (handled by server)
```

## Summary: Which Should You Choose?

### Choose LAN API if:
- ✅ Personal use only
- ✅ Same network as Lovense Connect
- ✅ Want simplest setup
- ✅ Security is important
- ✅ Want best performance

### Choose Cloud API if:
- ⚠️ Need remote access
- ⚠️ Accept security risks
- ⚠️ Only YOU can see the script
- ⚠️ Can't run a server

### Choose Middleware if:
- ✅ Multiple users
- ✅ Production environment
- ✅ Need advanced features
- ✅ Security is critical
- ✅ Can manage a server

## Final Recommendation

**For 90% of users: Start with LAN API**

It's the perfect balance of:
- Simplicity (easy setup)
- Security (no exposed credentials)
- Performance (lowest latency)
- Cost (free)

If you outgrow it, you can always migrate to middleware later!

---

**Questions?** See the troubleshooting sections in:
- `lovense_standalone.lsl` (bottom of file)
- `lovense_controller.lsl` (original version)
- `README.md` (project overview)
