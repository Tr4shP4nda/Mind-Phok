## Lovense Patterns and Controls Reference

Complete guide to all available control options for your Lovense devices.

## 🎵 Vibration Intensities

### Intensity Scale: 0-20

| Level | Description | Use Case |
|-------|-------------|----------|
| **0** | Off | Stopping |
| **1-3** | Very gentle | Teasing, buildup |
| **4-7** | Light | Comfort, extended sessions |
| **8-12** | Medium | Standard intensity |
| **13-16** | Strong | Intense sessions |
| **17-20** | Maximum | Peak intensity |

### Testing Recommendations

Start testing from low to high:

1. **Level 1** - Barely noticeable, good for testing connection
2. **Level 5** - Light, comfortable for extended use
3. **Level 10** - Medium, good baseline
4. **Level 15** - Strong, clearly noticeable
5. **Level 20** - Maximum power

### Example Commands

```lsl
// Vibrate at level 10 for 15 seconds
sendCommand(avatarKey, "Function", "Vibrate:10", 15);

// Vibrate at level 20 for 5 seconds
sendCommand(avatarKey, "Function", "Vibrate:20", 5);

// Stop vibration
sendCommand(avatarKey, "Function", "Stop", 0);
```

---

## 🎵 Preset Patterns

Lovense includes 4 built-in patterns. These are pre-programmed sequences that vary intensity automatically.

### 1. Pulse 💓

**Description:** Regular on/off pulsing pattern
**Best for:** Rhythmic stimulation, teasing
**Intensity:** Varies from 0 to high
**Speed:** Medium tempo

```lsl
sendCommand(avatarKey, "Preset", "pulse", 20);
```

**What it feels like:**
- ON (high) → OFF → ON (high) → OFF
- Steady, predictable rhythm
- Great for building anticipation

---

### 2. Wave 🌊

**Description:** Gradually increases and decreases intensity
**Best for:** Edging, wave-like sensations
**Intensity:** Smoothly ramps 0→20→0
**Speed:** Slow, rolling

```lsl
sendCommand(avatarKey, "Preset", "wave", 20);
```

**What it feels like:**
- Starts low, slowly builds up
- Reaches peak intensity
- Gradually comes back down
- Continuous, flowing motion

---

### 3. Fireworks 🎆

**Description:** Random bursts of varying intensity
**Best for:** Surprise, unpredictability
**Intensity:** Random levels
**Speed:** Variable, unpredictable

```lsl
sendCommand(avatarKey, "Preset", "fireworks", 20);
```

**What it feels like:**
- Sudden bursts at random
- Different intensities each time
- Exciting and unpredictable
- Keeps you guessing

---

### 4. Earthquake 🌍

**Description:** Irregular, shaking-like vibrations
**Best for:** Intense, chaotic stimulation
**Intensity:** Rapidly varying
**Speed:** Fast, erratic

```lsl
sendCommand(avatarKey, "Preset", "earthquake", 20);
```

**What it feels like:**
- Rapid intensity changes
- Feels like trembling/shaking
- Intense and stimulating
- More chaotic than other patterns

---

## 🎮 Advanced Controls

### Rotation (Nora only)

The Nora toy has a rotating head. Rotation can be combined with vibration!

**Rotation Scale:** 0-20

```lsl
// Rotate at level 10 for 15 seconds
sendCommand(avatarKey, "Function", "Rotate:10", 15);

// Combine vibration + rotation
sendCommand(avatarKey, "Function", "Vibrate:12,Rotate:8", 15);
```

**Compatible Toys:**
- ✅ Nora (all versions)
- ❌ All other toys (will be ignored)

---

### Pump (Max series only)

The Max series has an air pump for suction/contraction.

**Pump Scale:** 0-3 (only 4 levels!)

```lsl
// Pump at level 2 for 10 seconds
sendCommand(avatarKey, "Function", "Pump:2", 10);

// Combine vibration + pump
sendCommand(avatarKey, "Function", "Vibrate:10,Pump:2", 15);
```

**Pump Levels:**
- **0** - No suction
- **1** - Light suction
- **2** - Medium suction
- **3** - Strong suction

**Compatible Toys:**
- ✅ Max 2
- ✅ Max (original)
- ❌ All other toys (will be ignored)

---

## 📊 Device Compatibility Chart

| Toy | Vibrate | Rotate | Pump |
|-----|---------|--------|------|
| **Lush** (all versions) | ✅ | ❌ | ❌ |
| **Hush** (all versions) | ✅ | ❌ | ❌ |
| **Nora** | ✅ | ✅ | ❌ |
| **Max** (all versions) | ✅ | ❌ | ✅ |
| **Domi** (all versions) | ✅ | ❌ | ❌ |
| **Ambi** | ✅ | ❌ | ❌ |
| **Edge** (all versions) | ✅ | ❌ | ❌ |
| **Osci** | ✅ | ❌ | ❌ |
| **Ferri** | ✅ | ❌ | ❌ |
| **Diamo** | ✅ | ❌ | ❌ |
| **Hyphy** | ✅ | ❌ | ❌ |

---

## ⏱️ Duration Guidelines

### Recommended Durations

| Duration | Best For |
|----------|----------|
| **5-10 sec** | Quick bursts, testing |
| **10-15 sec** | Standard commands |
| **15-30 sec** | Patterns, sustained |
| **30-60 sec** | Longer sessions |
| **0** | Continuous (until stopped) |

### Examples

```lsl
// Quick 5-second burst
sendCommand(avatarKey, "Function", "Vibrate:15", 5);

// Standard 15-second vibration
sendCommand(avatarKey, "Function", "Vibrate:10", 15);

// Long 60-second pattern
sendCommand(avatarKey, "Preset", "wave", 60);

// Continuous until manually stopped
sendCommand(avatarKey, "Function", "Vibrate:8", 0);
```

---

## 🎯 Testing Sequence

Here's a recommended testing sequence to try all features:

### 1. Connection Test
```
Vibrate:1 for 5 seconds
→ Confirms device is connected and responding
```

### 2. Intensity Scale Test
```
Vibrate:5  for 10 seconds  (Light)
Vibrate:10 for 10 seconds  (Medium)
Vibrate:15 for 10 seconds  (Strong)
Vibrate:20 for 10 seconds  (Maximum)
```

### 3. Pattern Test
```
Preset: pulse      for 20 seconds
Preset: wave       for 20 seconds
Preset: fireworks  for 20 seconds
Preset: earthquake for 20 seconds
```

### 4. Stop Test
```
Stop (verify it stops immediately)
```

### 5. Advanced Features (if supported)
```
Rotate:10 for 15 seconds  (Nora only)
Pump:2 for 10 seconds     (Max only)
Vibrate:10,Rotate:5       (Multi-action test)
```

---

## 💡 Pro Tips

### For Testing

1. **Start low, go slow:** Begin with intensity 5, not 20!
2. **Test duration:** Use 10-15 seconds for initial tests
3. **Have a stop button ready:** Always provide easy access to stop
4. **Test patterns one by one:** Don't rush through them
5. **Use Quick Controls:** Great for rapid testing

### For Real Use

1. **Build up gradually:** Start low, increase intensity over time
2. **Mix patterns:** Alternate between preset patterns
3. **Combine actions:** Use Vibrate+Rotate on Nora
4. **Use varying durations:** Mix short bursts with longer sessions
5. **Always respect limits:** Honor stop requests immediately

---

## 🎮 Menu Organization

The full control script has organized menus:

### Main Menu
```
💨 Vibrate   → Intensity levels (1-20)
🎵 Patterns  → Preset patterns (4 types)
⚡ Quick     → One-tap shortcuts
🎮 Advanced  → Special functions
🔗 Link      → QR code linking
⏹️ STOP      → Emergency stop
ℹ️ Info      → Connection status
❌ Unlink    → Remove device link
```

### Vibrate Submenu
```
Level 1, 5, 10, 12, 15, 20
⬅️ Back, ⏹️ Stop
```

### Patterns Submenu
```
Pulse, Wave, Fireworks, Earthquake
⬅️ Back, ⏹️ Stop
```

### Quick Controls
```
Quick Low   → Vibrate:5 for 10s
Quick Med   → Vibrate:10 for 10s
Quick High  → Vibrate:20 for 10s
Quick Pulse → Pulse pattern for 10s
```

---

## 🔍 Troubleshooting

### Device Doesn't Respond

**Problem:** Command sent but nothing happens

**Checks:**
1. ✅ Device is ON and charged
2. ✅ Device shows as connected in Lovense Remote app
3. ✅ You're using the correct device link (QR code scanned recently)
4. ✅ Try a higher intensity (maybe started too low)

### Weak Response

**Problem:** Vibration is too weak

**Try:**
- Increase intensity: Use 15-20 instead of 5-10
- Check battery: Low battery = weaker vibrations
- Verify toy type: Some toys are naturally quieter

### Pattern Not Working

**Problem:** Pattern doesn't start

**Try:**
- Use lowercase pattern names: "pulse" not "Pulse"
- Verify pattern name is correct (pulse, wave, fireworks, earthquake)
- Try a simple vibrate command first to verify connection

### Rotation/Pump Not Working

**Problem:** Advanced functions don't respond

**Check:**
- Using the right toy? (Rotate = Nora only, Pump = Max only)
- All other toys will ignore these commands

---

## 📝 Quick Reference

### Most Common Commands

```lsl
// Light vibration
sendCommand(avatarKey, "Function", "Vibrate:5", 15);

// Medium vibration
sendCommand(avatarKey, "Function", "Vibrate:10", 15);

// Strong vibration
sendCommand(avatarKey, "Function", "Vibrate:20", 15);

// Pulse pattern
sendCommand(avatarKey, "Preset", "pulse", 20);

// Wave pattern
sendCommand(avatarKey, "Preset", "wave", 20);

// Stop everything
sendCommand(avatarKey, "Function", "Stop", 0);
```

---

## 🎪 Fun Combinations

### The Teaser
```
1. Vibrate:3 for 10s   (gentle start)
2. Vibrate:7 for 10s   (build up)
3. Vibrate:15 for 5s   (peak)
4. Stop
5. Wait 5 seconds
6. Vibrate:20 for 3s   (surprise!)
```

### The Wave Rider
```
1. Preset: wave for 30s
2. Brief stop (2-3s)
3. Vibrate:20 for 10s
4. Preset: wave for 30s
```

### The Random Mix
```
1. Preset: fireworks for 15s
2. Vibrate:10 for 10s
3. Preset: earthquake for 15s
4. Vibrate:5 for 20s
```

---

**Have fun testing! Start with the simple vibration levels, then explore the patterns.** 🎉
