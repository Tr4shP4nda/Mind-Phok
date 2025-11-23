# Lovense API Reference

Complete reference documentation for the Lovense API as used in the Mind-Phok Second Life integration.

## Table of Contents

- [Overview](#overview)
- [Authentication](#authentication)
- [API Endpoints](#api-endpoints)
- [Request Format](#request-format)
- [Response Format](#response-format)
- [Commands](#commands)
- [Error Codes](#error-codes)
- [Device Capabilities](#device-capabilities)
- [Examples](#examples)

## Overview

The Lovense API allows you to control Lovense devices through HTTPS requests. There are two main modes of operation:

1. **Cloud API**: Commands are sent to Lovense servers, which relay them to the user's device
2. **LAN API**: Direct communication with devices on the same local network

## Authentication

### Developer Token

All API requests require authentication using a developer token.

**How to get your token:**
1. Go to [Lovense Developer Dashboard](https://www.lovense.com/user/developer/info)
2. Log in with your Lovense account
3. Copy your developer token
4. Set your callback URL (if needed)

**Using the token:**
- Include in request body: `"token": "your_developer_token"`
- Also include user ID: `"uid": "target_user_id"`

## API Endpoints

### Cloud API Endpoint

```
POST https://api.lovense.com/api/lan/command
```

**Use when:**
- Controlling remote devices
- Internet connection available
- Maximum compatibility needed

### LAN API Endpoint

```
POST https://{local-ip}:{port}/command
```

**Use when:**
- Same local network as device
- Lower latency required
- Privacy/offline operation needed

**Finding LAN endpoint:**
1. Open Lovense Connect app
2. Settings → Developer tab
3. Note the IP address and HTTPS port shown

## Request Format

All requests must be sent as JSON with `Content-Type: application/json`.

### Basic Structure

```json
{
  "command": "Function|Pattern|Preset|GetToys",
  "action": "action_string",
  "timeSec": 0,
  "toy": "toy_id",
  "apiVer": 1,
  "token": "your_token",
  "uid": "user_id"
}
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `command` | string | Yes | Command type (see [Commands](#commands)) |
| `action` | string | Varies | Action to perform (depends on command) |
| `timeSec` | integer | No | Duration in seconds (0 = indefinite) |
| `toy` | string | No | Specific toy ID (omit to control all toys) |
| `apiVer` | integer | Yes | API version (use 1) |
| `token` | string | Yes* | Developer token (*for cloud API) |
| `uid` | string | Yes* | Target user ID (*for cloud API) |

## Response Format

### Success Response

```json
{
  "code": 200,
  "type": "ok",
  "data": {}
}
```

### Error Response

```json
{
  "code": 400,
  "type": "error",
  "message": "Error description"
}
```

## Commands

### 1. Function Command

Direct control of device functions.

**Usage:**
```json
{
  "command": "Function",
  "action": "Vibrate:10",
  "timeSec": 5
}
```

**Action Format:**

Single action:
```
"Vibrate:20"    // Vibrate at intensity 20
"Rotate:10"     // Rotate at intensity 10
"Pump:2"        // Pump at level 2
"Stop"          // Stop all actions
```

Multiple actions:
```
"Vibrate:15,Rotate:10"    // Combined vibration and rotation
```

**Intensity Ranges:**
- **Vibrate**: 0-20 (0 = off, 20 = maximum)
- **Rotate**: 0-20 (0 = off, 20 = maximum)
- **Pump**: 0-3 (0 = off, 3 = maximum)

**Examples:**

Low vibration for 10 seconds:
```json
{"command": "Function", "action": "Vibrate:5", "timeSec": 10}
```

High vibration indefinitely:
```json
{"command": "Function", "action": "Vibrate:20", "timeSec": 0}
```

Stop all actions:
```json
{"command": "Function", "action": "Stop", "timeSec": 0}
```

### 2. Pattern Command

Create custom vibration patterns.

**Usage:**
```json
{
  "command": "Pattern",
  "rule": "V:1;F:v;S:1000#",
  "strength": "20;10;15;10",
  "timeSec": 10
}
```

**Pattern Rule Syntax:**

```
V:1;F:v;S:1000#
```

- `V:1` - Version (always 1)
- `F:v` - Function (v=vibrate, r=rotate, p=pump)
- `S:1000` - Interval in milliseconds between strength changes
- `#` - Terminator

**Strength Parameter:**
- Semicolon-separated list of intensity values
- Values range: 0-20 for vibrate/rotate, 0-3 for pump
- Pattern loops through values at the specified interval

**Example - Pulsing Pattern:**
```json
{
  "command": "Pattern",
  "rule": "V:1;F:v;S:500#",
  "strength": "20;0;20;0;20;0",
  "timeSec": 10
}
```
This creates: 500ms high → 500ms off → 500ms high → 500ms off (repeating)

### 3. Preset Command

Use built-in preset patterns.

**Usage:**
```json
{
  "command": "Preset",
  "name": "pulse",
  "timeSec": 10
}
```

**Available Presets:**

| Preset | Description |
|--------|-------------|
| `pulse` | Regular pulsing pattern |
| `wave` | Gradually increasing and decreasing intensity |
| `fireworks` | Random intensity bursts |
| `earthquake` | Irregular shaking pattern |

**Examples:**

Wave pattern for 15 seconds:
```json
{"command": "Preset", "name": "wave", "timeSec": 15}
```

Earthquake pattern indefinitely:
```json
{"command": "Preset", "name": "earthquake", "timeSec": 0}
```

### 4. GetToys Command

Retrieve information about connected devices.

**Usage:**
```json
{
  "command": "GetToys"
}
```

**Response:**
```json
{
  "code": 200,
  "type": "ok",
  "data": {
    "toys": [
      {
        "id": "toy_id_123",
        "name": "Lush 3",
        "nickname": "My Lush",
        "status": 1,
        "battery": 85,
        "connected": true
      }
    ]
  }
}
```

**Toy Object Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique toy identifier |
| `name` | string | Device model name |
| `nickname` | string | User-assigned nickname |
| `status` | integer | 1=active, 0=inactive |
| `battery` | integer | Battery level (0-100) |
| `connected` | boolean | Connection status |

## Error Codes

| Code | Type | Description |
|------|------|-------------|
| 200 | Success | Request completed successfully |
| 400 | Invalid Command | Command format is invalid |
| 401 | Invalid Token | Developer token is invalid or expired |
| 402 | Invalid User ID | Target user ID doesn't exist |
| 404 | Toy Not Found | Specified toy ID not found |
| 405 | Toy Not Connected | Toy exists but is not connected |
| 406 | Toy Doesn't Support Command | Device doesn't support this action |
| 507 | Service Unavailable | Lovense servers are temporarily unavailable |

## Device Capabilities

Different Lovense devices support different functions:

### Vibration-Only Devices
- Lush series
- Hush series
- Ambi
- Domi series
- Ferri
- Hyphy

**Supported:** Vibrate
**Not Supported:** Rotate, Pump

### Rotation-Capable Devices
- Nora

**Supported:** Vibrate, Rotate
**Not Supported:** Pump

### Air Pump Devices
- Max series

**Supported:** Vibrate, Pump
**Not Supported:** Rotate

**Always check device capabilities before sending commands!**

## LSL Integration Notes

### Building JSON in LSL

LSL doesn't have native JSON encoding. Build JSON strings manually:

```lsl
string buildJsonRequest(string command, string action, integer duration) {
    string json = "{";
    json += "\"command\":\"" + command + "\"";
    json += ",\"action\":\"" + action + "\"";
    json += ",\"timeSec\":" + (string)duration;
    json += ",\"apiVer\":1";
    json += "}";
    return json;
}
```

### Making HTTP Requests

```lsl
list headers = [
    HTTP_METHOD, "POST",
    HTTP_MIMETYPE, "application/json",
    HTTP_VERIFY_CERT, TRUE
];

key requestId = llHTTPRequest(SERVER_URL, headers, jsonBody);
```

### Handling Responses

```lsl
http_response(key request_id, integer status, list metadata, string body) {
    if (request_id == httpRequestId) {
        if (status == 200) {
            llOwnerSay("Success!");
        } else {
            llOwnerSay("Error: " + (string)status);
        }
    }
}
```

## Examples

### Example 1: Simple Vibration

**Request:**
```json
{
  "command": "Function",
  "action": "Vibrate:15",
  "timeSec": 5,
  "apiVer": 1,
  "token": "abc123...",
  "uid": "user123"
}
```

**Response:**
```json
{
  "code": 200,
  "type": "ok"
}
```

### Example 2: Custom Wave Pattern

**Request:**
```json
{
  "command": "Pattern",
  "rule": "V:1;F:v;S:1000#",
  "strength": "5;10;15;20;15;10",
  "timeSec": 30,
  "apiVer": 1,
  "token": "abc123...",
  "uid": "user123"
}
```

Creates a wave that ramps up from 5 to 20 and back down, changing every second.

### Example 3: Combined Actions

**Request:**
```json
{
  "command": "Function",
  "action": "Vibrate:12,Rotate:8",
  "timeSec": 10,
  "apiVer": 1,
  "token": "abc123...",
  "uid": "user123"
}
```

Vibrates at intensity 12 while rotating at intensity 8 (for compatible devices like Nora).

### Example 4: Get Device Status

**Request:**
```json
{
  "command": "GetToys",
  "apiVer": 1,
  "token": "abc123...",
  "uid": "user123"
}
```

**Response:**
```json
{
  "code": 200,
  "type": "ok",
  "data": {
    "toys": [
      {
        "id": "abc123",
        "name": "Lush 3",
        "nickname": "Pink Lush",
        "status": 1,
        "battery": 75,
        "connected": true
      },
      {
        "id": "def456",
        "name": "Nora",
        "nickname": "My Nora",
        "status": 1,
        "battery": 90,
        "connected": true
      }
    ]
  }
}
```

### Example 5: Control Specific Toy

**Request:**
```json
{
  "command": "Function",
  "action": "Vibrate:20",
  "timeSec": 5,
  "toy": "abc123",
  "apiVer": 1,
  "token": "abc123...",
  "uid": "user123"
}
```

Only controls the toy with ID "abc123", leaving other toys unaffected.

## Rate Limiting

- **Recommended**: Maximum 1 request per second per user
- **Burst**: Up to 5 requests in rapid succession
- Exceeding limits may result in temporary blocking

## Best Practices

1. **Always implement Stop functionality** for safety
2. **Start with low intensities** during testing
3. **Check device capabilities** before sending commands
4. **Handle errors gracefully** with user feedback
5. **Respect rate limits** to prevent blocking
6. **Validate SSL certificates** (required for SL)
7. **Never hardcode tokens** in public scripts
8. **Implement consent mechanisms** for user safety
9. **Provide battery status checks** for better UX
10. **Test thoroughly** with your own devices first

## Additional Resources

- **Official Documentation**: [Lovense Standard Solutions](https://github.com/lovense/Standard_solutions)
- **Developer Dashboard**: [Lovense Developer Portal](https://www.lovense.com/user/developer/info)
- **Community Support**: Lovense Developer Forums

---

**Last Updated**: November 2025
**API Version**: 1
**Document Version**: 1.0
