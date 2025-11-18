# 🧭 AcceloCubePro  
**Attitude-Driven Cube with Gravity / User-Acceleration Split**  
Author: *Christian Bonilla* 

---

## 📘 Overview  
**AcceloCubePro** is a SwiftUI + SceneKit application that visualizes real-time device orientation and motion using CoreMotion’s **CMDeviceMotion** sensor fusion.  
It separates **gravity** from **user acceleration**, integrates acceleration into position, and applies live-tunable **smoothing** and **damping** filters for stable visualization.  
A built-in **Demo Mode** allows full functionality even inside the iOS Simulator.  

---

## 🎯 Learning Objectives  
- Apply CoreMotion’s **CMDeviceMotion** to obtain:  
  - Attitude (Quaternion)  
  - Gravity vector  
  - User Acceleration  
- Implement **low-pass** and **damping** filters for motion data.  
- Execute a **calibration flow** that zeroes position and orientation.  
- Control a **3D SceneKit cube** using:  
  - Orientation ← attitude quaternion  
  - Translation ← integrated user acceleration  
- Provide UI controls for:  
  - Sample rate  
  - Smoothing  
  - Damping  
  - Start / Stop / Re-Center  
  - Demo Mode toggle  

---

## 🧱 Architecture  

### File Structure  
```bash
AcceloCubePro/
│
├── AcceloCubeProApp.swift # App entry point
├── ContentView.swift # Main container view
├── MotionVM.swift # ViewModel (CoreMotion, filtering, calibration)
├── SceneViewBridge.swift # SceneKit cube visualization
├── ControlPanelView.swift # Control panel (sliders, toggles, buttons)
└── Assets.xcassets
```

---

### Main Components  

#### MotionVM.swift  
- Manages the **CMMotionManager** lifecycle.  
- Publishes quaternion, position, and status updates.  
- Applies:  
  - Low-pass smoothing filter (via `simd_slerp`)  
  - Velocity/position integration  
  - Damping and clamping  
- Includes **Demo Mode** for sensor simulation when hardware is unavailable.  
- Handles calibration, re-centering, and status updates.  

#### SceneViewBridge.swift  
- A **UIViewRepresentable** bridge for SceneKit.  
- Displays a cube (`SCNBox`) with:  
  - Ambient and directional lights  
  - A fixed camera position  
- Updates orientation and position each frame according to motion data.  

#### ControlPanelView.swift  
- Provides sliders and toggles for:  
  - **Sample Rate (Hz)**  
  - **Smoothing (Low-pass α)**  
  - **Damping**  
  - **Demo Mode**  
- Includes **Start**, **Stop**, and **Re-Center** buttons that call the corresponding functions in the `MotionVM`.  

#### ContentView.swift  
- The main SwiftUI container combining:  
  - The 3D Scene (`SceneViewBridge`)  
  - The Control Panel (`ControlPanelView`)  
  - A centered Status HUD showing:  
    - Current status  
    - Sample rate  
    - Latency (ms)  

---

## ⚙️ Core Functionality  

### Motion Processing Pipeline  

1. Read CMDeviceMotion (attitude, gravity, userAcceleration).

2. Apply low-pass smoothing (quaternion).

3. Integrate user acceleration → velocity → position.

4. Apply damping each frame: v *= (1 - damping).

5. Clamp velocity/position to prevent numeric explosion.

6. Publish values to SwiftUI via @Published properties.


---

### Calibration Flow  

* Captures current quaternion as "neutral" orientation.

* Resets velocity and position to zero.

* Applies calibration offset on each update.


---

### Demo Mode  

* Enabled automatically in the simulator or manually via toggle.

* Generates smooth sinusoidal motion and quaternion rotation.

* Uses a background Task with async sleep for timing.

* Perfect for testing the app in the iOS Simulator without real sensors.

![AcceloCube Demo](./demo.gif)


---

## 🧠 Filters & Parameters  

| Parameter | Description | Typical Range |
|------------|--------------|----------------|
| `smoothing` | Low-pass α used for quaternion smoothing | 0.0 – 1.0 |
| `damping` | Multiplier applied to velocity each frame | 0.0 – 0.2 |
| `sampleHz` | DeviceMotion sampling frequency | 30 / 60 / 100 Hz |
| `maxSpeed` | Velocity clamp limit | ±5.0 m/s |
| `maxRange` | Position clamp limit | ±2.0 m |

---

## 🖥️ User Interface  

- **Top:** SceneKit cube visualization  
- **Middle:** Control panel (sliders + buttons)  
- **Bottom:** Status HUD showing status, sample rate, and latency  

```bash
[ SceneView ]
[ Start | Stop | Re-Center ]
[ Hz: Slider ]
[ Smoothing: Slider ]
[ Damping: Slider ]
[ Demo Mode: Toggle ]
[ Status HUD ]
```

---

## 🚀 Running the App  

1. Open `AcceloCubePro.xcodeproj` in **Xcode 15+**.  
2. Choose **an iPhone target**.  
3. Press **Run (⌘R)**:  
   - On a physical device → real sensor data.  
   - In simulator → automatic **Demo Mode** activation.  
4. Adjust sliders and observe cube behavior.  

---

## 🧩 Technical Notes  

- CoreMotion updates are processed on a background `OperationQueue`.  
- Published properties are updated on the main actor to keep SwiftUI reactive.  
- SceneKit rendering uses a short animation transaction (0.05s) for smooth transitions.  
- The demo loop uses `Task.sleep` for timing at the configured sample rate.  