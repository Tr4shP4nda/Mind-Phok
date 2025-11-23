# Quick Start Guide

Get up and running with the Lovense + Second Life integration in 5 minutes!

## Prerequisites Checklist

- [ ] Lovense account with developer access
- [ ] Second Life account
- [ ] Node.js 16+ installed (for middleware server)
- [ ] Domain with valid SSL certificate (or Let's Encrypt)
- [ ] At least one Lovense device for testing

## Step-by-Step Setup

### Step 1: Get Your Lovense Developer Credentials (2 minutes)

1. Go to https://www.lovense.com/user/developer/info
2. Log in with your Lovense account
3. Copy your **Developer Token**
4. Note your **User ID** (usually your email or username)
5. Set a callback URL (optional): `https://your-domain.com/lovense/callback`

### Step 2: Set Up the Middleware Server (5 minutes)

```bash
# Clone the repository
git clone https://github.com/Tr4shP4nda/Mind-Phok.git
cd Mind-Phok

# Install dependencies
npm install

# Copy and configure the config file
cp config.example.json config.json
nano config.json  # or use your favorite editor
```

Edit `config.json`:
```json
{
  "lovense": {
    "developer_token": "paste-your-token-here",
    "user_id": "your-user-id-here"
  },
  "middleware": {
    "server_url": "https://your-domain.com/lovense/command",
    "port": 3000,
    "enable_https": true,
    "ssl_cert_path": "/path/to/fullchain.pem",
    "ssl_key_path": "/path/to/privkey.pem"
  }
}
```

### Step 3: Start the Server

```bash
npm start
```

You should see:
```
═══════════════════════════════════════════════════════
🚀 Lovense Middleware Server (HTTPS)
═══════════════════════════════════════════════════════
🌐 Listening on: https://localhost:3000
📡 API Mode: Cloud
🔒 Rate Limiting: Enabled
📝 Logging: Enabled
═══════════════════════════════════════════════════════
```

### Step 4: Test Your Server

```bash
curl -X POST https://your-domain.com/lovense/command \
  -H "Content-Type: application/json" \
  -d '{
    "command": "GetToys",
    "apiVer": 1
  }'
```

Expected response:
```json
{
  "code": 200,
  "type": "ok",
  "data": {
    "toys": [...]
  }
}
```

### Step 5: Configure the LSL Script (3 minutes)

1. Open `lovense_controller.lsl` in a text editor
2. Edit the configuration section:

```lsl
string SERVER_URL = "https://your-domain.com/lovense/command";
string DEVELOPER_TOKEN = "your-token-here";  // Optional for middleware
string USER_ID = "your-user-id-here";        // Optional for middleware
```

3. Copy the entire script

### Step 6: Deploy to Second Life (2 minutes)

1. Log in to Second Life
2. Create a new object:
   - Build menu → Create → Cube
   - Right-click the cube → Edit
3. Add the script:
   - Go to the "Content" tab
   - Click "New Script"
   - Delete the default script
   - Paste your configured `lovense_controller.lsl`
   - Save (Ctrl+S or Cmd+S)
4. Check the script output:
   - You should see "Lovense Controller Initialized"

### Step 7: Test It! (1 minute)

1. Touch your cube in Second Life
2. A menu should appear with options like:
   - Vibrate Low
   - Vibrate Med
   - Vibrate High
   - Pattern: Pulse
   - etc.
3. Select "Vibrate Low"
4. Your Lovense device should vibrate!

## Troubleshooting

### "HTTP Error 499" - Request Timeout

**Problem**: The LSL script can't reach your server.

**Solutions**:
- ✅ Verify your server URL is correct and publicly accessible
- ✅ Check your firewall allows incoming connections on your port
- ✅ Test with `curl` from another machine to verify accessibility

### "SSL Certificate Validation Error"

**Problem**: Second Life doesn't trust your SSL certificate.

**Solutions**:
- ✅ Use a valid SSL certificate from Let's Encrypt or a trusted CA
- ✅ Self-signed certificates will NOT work with Second Life
- ✅ Verify your certificate chain is complete

### Device Not Responding

**Problem**: Commands succeed but device doesn't vibrate.

**Solutions**:
- ✅ Check device is connected to Lovense Remote/Connect app
- ✅ Verify you're using the correct User ID
- ✅ Test the device manually in the Lovense app first
- ✅ Check device battery level

### "Invalid Token" Error

**Problem**: API returns 401 Invalid Token.

**Solutions**:
- ✅ Verify you copied the entire developer token (no spaces/newlines)
- ✅ Check the token hasn't expired
- ✅ Ensure you're logged into the correct Lovense account

## Alternative: LAN API Setup (No Server Required!)

If you're running Second Life on the same network as Lovense Connect:

1. Open Lovense Connect app
2. Go to Settings → Developer
3. Note the local IP and HTTPS port (e.g., `192.168.1.100:30010`)
4. Edit your LSL script:

```lsl
string SERVER_URL = "https://192.168.1.100:30010/command";
```

5. In `config.json`, enable LAN mode:

```json
{
  "lan_api": {
    "enabled": true,
    "local_ip": "192.168.1.100",
    "https_port": 30010
  }
}
```

**Note**: You still need a valid SSL certificate even for local connections!

## Next Steps

Now that you have the basic setup working:

1. **Customize the menu** - Add your own patterns and intensities
2. **Add access control** - Implement user whitelists
3. **Create patterns** - Design custom vibration patterns
4. **Build interfaces** - Create HUDs, gesture controls, or chat commands
5. **Monitor status** - Use the "Status" command to check battery levels
6. **Safety features** - Add emergency stop buttons

## Tips for Development

- **Test with low intensities first** - Start at 5/20, not 20/20
- **Use the Status command** - Check device status regularly
- **Implement rate limiting** - Don't spam commands
- **Add error handling** - Always handle HTTP errors gracefully
- **Respect privacy** - Get explicit consent before controlling devices
- **Log everything** - Helps with debugging issues

## Security Reminders

⚠️ **IMPORTANT**:
- Never share your developer token publicly
- Never commit `config.json` to version control
- Always get explicit consent before device control
- Implement proper access control in production
- Use HTTPS everywhere (required for Second Life)

## Getting Help

- **Documentation**: See [README.md](README.md) and [API_REFERENCE.md](API_REFERENCE.md)
- **Issues**: https://github.com/Tr4shP4nda/Mind-Phok/issues
- **Lovense Docs**: https://github.com/lovense/Standard_solutions
- **LSL Reference**: http://wiki.secondlife.com/wiki/LSL_Portal

## Success Checklist

You're all set up when you can:

- [x] Server starts without errors
- [x] `/health` endpoint returns 200 OK
- [x] LSL script shows "Lovense Controller Initialized"
- [x] Touch menu appears in Second Life
- [x] "Vibrate Low" makes device vibrate
- [x] "Stop All" stops vibration
- [x] "Status" returns device info

**Congratulations! You're now controlling Lovense devices from Second Life! 🎉**
