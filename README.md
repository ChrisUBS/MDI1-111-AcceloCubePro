# Orientation Visualizer

An interactive device orientation visualizer built with **SwiftUI + CoreMotion + SceneKit**.  
It displays real-time **roll**, **pitch**, **yaw**, and a 3D cube that rotates using quaternion data.  
Fully supports both **real devices** and the **iOS simulator** through a built-in **demo mode**.

---

## 📱 Device / Simulator Used

- **Environment:** Xcode Simulator  
- **Simulated device:** iPhone 15 Pro (iOS 18.1)  
- **Physical sensors:** Not available (Demo mode enabled)

---

## ⚙️ Main Parameters

| Parameter | Description | Value |
|------------|-------------|--------|
| **α (alpha)** | Low-pass filter coefficient for smooth motion data | `0.15` |
| **Hz (sampling rate)** | Sensor update frequency | `60 Hz` |
| **Demo Mode** | Simulates roll/pitch/yaw and quaternion updates | Enabled |
| **3D Cube Mode** | Displays SceneKit cube rotation using quaternions | Enabled |

---

## 🚀 Implemented Features

✅ **Bubble Level Visualization**  
- Circular frame with a moving bubble that responds to roll and pitch.  
- Highlights “level” state when both angles are within ±3°.  

✅ **Real-Time 3D Rotation**  
- Cube rendered using **SceneKit**.  
- Orientation updates with quaternion data (`qx`, `qy`, `qz`, `qw`).  

✅ **Demo Mode (Simulator Support)**  
- Generates smooth sinusoidal roll/pitch waves.  
- Dynamically rotates the cube using quaternion math.  
- Allows full app testing without a physical device.  

✅ **Interactive Controls**  
- `Demo mode` toggle → Enables or disables simulation.  
- `3D cube` toggle → Shows or hides the 3D cube.  
- `Hz` slider → Adjusts the update frequency (15–100 Hz).  
- Buttons: **Start**, **Stop**, **Calibrate**.

---

## 🧠 Project Structure

| File | Description |
|------|--------------|
| `MotionVM.swift` | Main ViewModel handling CoreMotion and simulated data. |
| `BubbleLevelView.swift` | Circular bubble view displaying roll/pitch orientation. |
| `OrientationCubeView.swift` | SceneKit 3D cube using quaternions for rotation. |
| `OrientationRootView.swift` | Root SwiftUI view with UI controls and bindings. |
| `MDI1_110_OrientationVisualizerApp.swift` | Main app entry point with `@main`. |

---

## 🧩 Demo Logic Example

```swift
// Simplified demo mode from MotionVM.swift
private func startDemo(updateHz: Double) {
    demoTask = Task { [weak self] in
        guard let self else { return }
        var t: Double = 0
        let dt = 1.0 / updateHz

        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(dt * 1_000_000_000))
            t += dt

            let r = sin(t * 1.2) * 8
            let p = cos(t * 0.9) * 6

            // Quaternion rotation
            let angle = t * 0.8
            let axis = SIMD3<Double>(x: sin(t * 0.4), y: cos(t * 0.5), z: sin(t * 0.3))
            let norm = simd_normalize(axis)
            let halfAngle = angle / 2
            let sinHalf = sin(halfAngle)
            let qx = norm.x * sinHalf
            let qy = norm.y * sinHalf
            let qz = norm.z * sinHalf
            let qw = cos(halfAngle)

            await MainActor.run {
                self.rollDeg = self.lowPass(current: r, previous: self.rollDeg)
                self.pitchDeg = self.lowPass(current: p, previous: self.pitchDeg)
                self.qx = qx; self.qy = qy; self.qz = qz; self.qw = qw
                self.sampleHz = updateHz
            }
        }
    }
}
```
---

## 🧭 How to Run

1. Open the project in **Xcode 16+**.  
2. Choose a **simulator** (e.g., *iPhone 16 Pro*).  
3. Run with **⌘ + R**.  
4. Toggle **Demo mode** ON and press **Start**.  
5. Watch the bubble and cube respond to simulated motion.

---

## 📸 Screenshots

| Bubble Centered | Rotating Cube |
|----------------|----------------|
| ![screenshot1](/screenshots/img1.png) | ![screenshot2](/screenshots/img2.png) |

---

## 🧩 Dependencies

- **SwiftUI**
- **CoreMotion**
- **SceneKit**
- **simd** (for vector normalization and quaternion generation)

---

## 👨‍💻 Author

Developed by **Christian Bonilla**