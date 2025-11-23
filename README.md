# Mind-Phok: Lovense API Integration for Second Life

This repository contains example scripts and documentation for integrating Lovense devices with Second Life using the Lovense API and Linden Scripting Language (LSL).

## 📋 Overview

This project demonstrates how to control Lovense devices from within Second Life, enabling interactive experiences that bridge virtual and physical sensations. The main script provides a menu-driven interface for controlling device vibration patterns, intensity, and more.

### Two Approaches Available

1. **Standalone LSL Script** (`lovense_standalone.lsl`) - **RECOMMENDED FOR MOST USERS**
   - No middleware server needed
   - Works directly with Lovense API
   - Three connection methods: LAN (local), Cloud (remote), or QR Code
   - Perfect for personal use
   - See [STANDALONE_VS_MIDDLEWARE.md](STANDALONE_VS_MIDDLEWARE.md) for comparison

2. **Middleware Server Approach** (`lovense_controller.lsl` + `middleware-server.js`)
   - Better for multi-user scenarios
   - Production-ready security
   - Advanced features (logging, rate limiting)
   - Requires server setup

## ✨ Features

- **Touch-based menu interface** for easy control
- **Multiple vibration intensities** (Low, Medium, High)
- **Built-in patterns**: Pulse, Wave, Earthquake
- **Device status checking**
- **Error handling and user feedback**
- **Customizable and extensible**

## 🚀 Quick Start

### Choose Your Approach

#### Option A: Standalone (Easiest - No Server Required!) ⭐ RECOMMENDED

Perfect for personal use, simplest setup:

1. **Get your local network info:**
   - Open Lovense Connect app
   - Go to Settings → Developer
   - Note the Local IP and HTTPS Port

2. **Configure the script:**
   - Open `lovense_standalone.lsl`
   - Set `CONNECTION_METHOD = 1`
   - Set `LAN_IP` to your Local IP
   - Set `LAN_PORT` to your HTTPS Port

3. **Deploy to Second Life:**
   - Create an object
   - Add the script
   - Touch and test!

See [QUICKSTART.md](QUICKSTART.md) for detailed instructions.

#### Option B: Middleware Server (For Production/Multi-User)

Better for public objects or advanced features:

### Prerequisites

1. **Lovense Developer Account**
   - Sign up at [Lovense Developer Portal](https://www.lovense.com/user/developer/info)
   - Obtain your developer token
   - Note your user ID

2. **Second Life Account**
   - Basic knowledge of LSL scripting
   - Permission to create/modify objects in-world

3. **Middleware Server**
   - A server with HTTPS and valid SSL certificate
   - See [Middleware Setup](#middleware-setup) below

### Installation

1. **Clone this repository**
   ```bash
   git clone https://github.com/Tr4shP4nda/Mind-Phok.git
   cd Mind-Phok
   ```

2. **Configure the script**
   - Open `lovense_controller.lsl`
   - Edit the configuration section:
     ```lsl
     string SERVER_URL = "https://your-server.example.com/lovense/command";
     string DEVELOPER_TOKEN = "YOUR_DEVELOPER_TOKEN_HERE";
     string USER_ID = "USER_ID_HERE";
     ```

3. **Deploy to Second Life**
   - Create a new object in Second Life (cube, sphere, etc.)
   - Right-click → Edit → Content tab
   - Click "New Script" and delete the default script
   - Copy the contents of `lovense_controller.lsl`
   - Paste into the script editor and save

4. **Test the controller**
   - Touch the object in-world
   - Select an action from the menu
   - Verify the device responds

## 🔧 Middleware Setup

Since Second Life requires HTTPS with valid SSL certificates, you'll typically need a middleware server to handle requests between SL and the Lovense API.

### Option 1: Simple Node.js Middleware

Create a simple Express.js server:

```javascript
const express = require('express');
const https = require('https');
const app = express();

app.use(express.json());

app.post('/lovense/command', async (req, res) => {
    try {
        const { command, action, timeSec, toy, apiVer } = req.body;

        // Add your authentication here
        const payload = {
            command,
            action,
            timeSec,
            apiVer,
            token: process.env.LOVENSE_TOKEN,
            uid: process.env.LOVENSE_UID
        };

        if (toy) payload.toy = toy;

        // Forward to Lovense API
        const response = await fetch('https://api.lovense.com/api/lan/command', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        const data = await response.json();
        res.json(data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Middleware server running on port ${PORT}`);
});
```

### Option 2: LAN API (Local Network)

If your Second Life viewer and Lovense Connect app are on the same network:

1. Open Lovense Connect
2. Go to Settings → Developer
3. Note the local IP and HTTPS port
4. Use `https://{local-ip}:{port}/command` as your SERVER_URL

**Note**: This requires a valid SSL certificate even for local connections.

### Option 3: Use Lovense Cloud API

For production use, implement proper authentication and use Lovense's cloud API:

```lsl
// In your LSL script, include token and uid in the JSON:
string buildJsonRequest(string command, string action, integer duration) {
    string json = "{";
    json += "\"command\":\"" + command + "\"";
    json += ",\"action\":\"" + action + "\"";
    json += ",\"timeSec\":" + (string)duration;
    json += ",\"apiVer\":1";
    json += ",\"token\":\"" + DEVELOPER_TOKEN + "\"";
    json += ",\"uid\":\"" + USER_ID + "\"";
    json += "}";
    return json;
}
```

## 📚 Documentation

- **[STANDALONE_VS_MIDDLEWARE.md](STANDALONE_VS_MIDDLEWARE.md)** - **START HERE** - Comparison guide to choose the right approach
- **[QUICKSTART.md](QUICKSTART.md)** - Step-by-step setup guide
- **[API_REFERENCE.md](API_REFERENCE.md)** - Detailed Lovense API documentation
- **[lovense_standalone.lsl](lovense_standalone.lsl)** - Standalone script (no server needed)
- **[lovense_controller.lsl](lovense_controller.lsl)** - Middleware version with inline documentation

## 🎮 Usage Examples

### Basic Usage

1. **Touch the controller object** in Second Life
2. **Select an action** from the dialog menu:
   - `Vibrate Low` - Low intensity vibration (5/20)
   - `Vibrate Med` - Medium intensity (10/20)
   - `Vibrate High` - Maximum intensity (20/20)
   - `Pattern: Pulse` - Pulsing pattern
   - `Pattern: Wave` - Wave pattern
   - `Pattern: Earthquake` - Earthquake pattern
   - `Stop All` - Stop all device actions
   - `Status` - Get device status and battery info

### Advanced Customization

Edit the `handleMenuSelection()` function to add custom commands:

```lsl
else if (message == "Custom Pattern") {
    // 15-second vibration at intensity 12
    sendLovenseCommand("Function", "Vibrate:12", 15);
}
```

Add rotation for compatible devices:

```lsl
else if (message == "Rotate") {
    sendLovenseCommand("Function", "Rotate:10", 10);
}
```

Combine multiple actions:

```lsl
else if (message == "Multi-Action") {
    sendLovenseCommand("Function", "Vibrate:10,Rotate:5", 10);
}
```

## 🔒 Security & Privacy Considerations

⚠️ **IMPORTANT**: This script controls intimate devices. Please observe these guidelines:

1. **Explicit Consent**: Always obtain clear, explicit consent before controlling someone's device
2. **Access Control**: The default script only allows the owner to use it. Modify carefully.
3. **Authentication**: Implement proper authentication in your middleware
4. **Secure Tokens**: Never hardcode tokens in public scripts
5. **Rate Limiting**: Implement rate limits to prevent abuse
6. **Safe Defaults**: Start with low intensities during testing
7. **Emergency Stop**: Always provide an easy way to stop all actions

## 🐛 Troubleshooting

### "HTTP Error 499" - Request Timeout
- Check your SERVER_URL is correct and accessible
- Verify your SSL certificate is valid
- Test the middleware server independently

### "SSL Certificate Validation Error"
- Second Life requires valid SSL certificates
- Self-signed certificates will not work
- Use Let's Encrypt for free valid certificates

### No Response from Device
- Verify the device is connected to Lovense Connect/Remote
- Check your developer token is correct
- Ensure the user ID matches the device owner
- Test the API endpoint with curl or Postman first

### "Only the owner can use this controller"
- This is the default security setting
- Edit the `touch_start` event to change permissions
- Be very careful about who has access

## 📖 Additional Resources

### Official Lovense Documentation
- [Lovense Developer Portal](https://www.lovense.com/user/developer/info)
- [Standard Solutions GitHub](https://github.com/lovense/Standard_solutions)
- [Cam Solutions GitHub](https://github.com/lovense/Cam-Solutions)

### LSL Resources
- [LSL Portal](http://wiki.secondlife.com/wiki/LSL_Portal)
- [LSL HTTP Request](http://wiki.secondlife.com/wiki/LlHTTPRequest)
- [LSL Dialog](http://wiki.secondlife.com/wiki/LlDialog)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for:

- Bug fixes
- New features
- Documentation improvements
- Additional examples
- Security enhancements

## 📄 License

This project is provided as-is for educational and development purposes. Please ensure you comply with:
- [Lovense Terms of Service](https://www.lovense.com/terms-of-service)
- [Second Life Terms of Service](https://www.lindenlab.com/legal/tos)
- All applicable laws and regulations regarding intimate devices

## ⚠️ Disclaimer

This software is provided for educational purposes. The authors are not responsible for misuse or any damages that may occur from using this software. Always prioritize consent, safety, and privacy when working with intimate devices.

## 💬 Support

- **Issues**: [GitHub Issues](https://github.com/Tr4shP4nda/Mind-Phok/issues)
- **Discussions**: Use GitHub Discussions for questions and community support

## 🙏 Acknowledgments

- Lovense for providing the API and documentation
- The Second Life scripting community
- All contributors to this project

---

**Made with ❤️ for the Second Life and Lovense communities**
