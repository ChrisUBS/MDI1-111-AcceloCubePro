import Foundation
import CoreMotion
import Combine
import simd

// MARK: - Configuration
struct MotionConfig {
    var sampleHz: Double = 60
    var smoothing: Double = 0.2   // Low-pass alpha (0..1)
    var damping: Double = 0.02    // Velocity damping (0..0.2)
    var maxSpeed: Double = 5.0    // m/s
    var maxRange: Double = 2.0    // m
}

// MARK: - ViewModel
@MainActor
final class MotionVM: ObservableObject {
    // Published state
    @Published var cfg = MotionConfig()
    @Published var quat = simd_quatf()
    @Published var position = SIMD3<Float>(repeating: 0)
    @Published var status: String = "Idle"
    @Published var latencyMs: Double = 0.0
    // MARK: - Simulation Support
    private var demoTask: Task<Void, Never>? = nil
    @Published var usingDemo: Bool = false
    
    // Internal motion vars
    private var mgr = CMMotionManager()
    private var queue = OperationQueue()
    private var velocity = SIMD3<Float>(repeating: 0)
    private var lastTimestamp: TimeInterval?
    private var calibratedQuat = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
    
    // MARK: - Lifecycle
    func start(demo: Bool? = nil) {
        stop()
        status = "Starting..."
        
        if let d = demo { usingDemo = d }
        
        // Automatically enable demo mode if hardware is unavailable
        if usingDemo || !mgr.isDeviceMotionAvailable {
            usingDemo = true
            startDemo()
            status = "Demo mode active"
            return
        }

        mgr.deviceMotionUpdateInterval = 1.0 / cfg.sampleHz
        lastTimestamp = nil

        mgr.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] motion, error in
            guard let self, let m = motion else { return }
            self.processMotion(m)
        }

        status = "Running (Real Sensor)"
    }
    
    // MARK: - Demo Simulation (for simulator)
    private func startDemo() {
        demoTask = Task { [weak self] in
            guard let self else { return }
            var t: Double = 0
            let dt = 1.0 / cfg.sampleHz
            
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(dt * 1_000_000_000))
                t += dt
                
                // Generate smooth oscillating motion
                let roll = sin(t * 0.9) * 0.3
                let pitch = cos(t * 0.7) * 0.25
                let yaw = sin(t * 0.5) * 0.15
                
                // Fake quaternion rotation (incremental)
                let angle = Float(t * 0.8)
                let axis = SIMD3<Float>(x: sin(Float(t) * 0.4), y: cos(Float(t) * 0.5), z: sin(Float(t) * 0.3))
                let norm = simd_normalize(axis)
                let halfAngle = angle / 2
                let sinHalf = sin(halfAngle)
                let q = simd_quatf(ix: norm.x * sinHalf,
                                   iy: norm.y * sinHalf,
                                   iz: norm.z * sinHalf,
                                   r: cos(halfAngle))
                
                // Simulated acceleration
                let acc = SIMD3<Float>(x: sin(Float(t)) * 0.5,
                                       y: cos(Float(t * 0.7)) * 0.4,
                                       z: 0.0)
                
                self.integrate(accel: acc, dt: Float(dt))
                
                await MainActor.run {
                    self.quat = q
                    self.status = "Running (Demo)"
                }
            }
        }
    }
    
    func stop() {
        mgr.stopDeviceMotionUpdates()
        demoTask?.cancel()
        demoTask = nil
        lastTimestamp = nil
        
        // Reset status and allow demo toggle to deactivate
        status = "Stopped"
        if usingDemo {
            usingDemo = false
        }
    }
    
    func calibrate() {
        // Store current orientation as neutral
        calibratedQuat = quat
        velocity = .zero
        position = .zero
        status = "Calibrated"
    }
    
    // MARK: - Motion Processing
    private func processMotion(_ m: CMDeviceMotion) {
        let ts = m.timestamp
        let dt = Float((lastTimestamp.map { ts - $0 } ?? (1.0 / cfg.sampleHz)))
        lastTimestamp = ts
        let hz = 1.0 / Double(dt)
        
        let now = Date().timeIntervalSince1970
        latencyMs = (now - ts) * 1000
        
        // Orientation
        let q = simd_quatf(ix: Float(m.attitude.quaternion.x),
                           iy: Float(m.attitude.quaternion.y),
                           iz: Float(m.attitude.quaternion.z),
                           r:  Float(m.attitude.quaternion.w))
        
        // Apply simple low-pass smoothing on quaternion
        let alpha = Float(cfg.smoothing)
        let smoothedQuat = simd_slerp(quat, self.quat, alpha)
        let calibrated = simd_mul(calibratedQuat.inverse, smoothedQuat)
        
        // Acceleration
        let ua = SIMD3<Float>(Float(m.userAcceleration.x),
                              Float(m.userAcceleration.y),
                              Float(m.userAcceleration.z))
        
        // Integration
        integrate(accel: ua, dt: dt)
        
        // Update main thread state
        Task { @MainActor in
            self.quat = calibrated
            self.position = self.position
            self.status = String(format: "Running (%.0f Hz)", hz)
        }
    }
    
    // MARK: - Integration and Filtering
    private func integrate(accel: SIMD3<Float>, dt: Float) {
        // Simple damping model
        velocity += accel * dt
        velocity *= (1 - Float(cfg.damping))
        position += velocity * dt

        // Convert Double → Float for clamping
        let maxSpeed = Float(cfg.maxSpeed)
        let maxRange = Float(cfg.maxRange)

        // Clamping (use vector limits)
        let minVel = SIMD3<Float>(repeating: -maxSpeed)
        let maxVel = SIMD3<Float>(repeating:  maxSpeed)
        let minPos = SIMD3<Float>(repeating: -maxRange)
        let maxPos = SIMD3<Float>(repeating:  maxRange)

        velocity = simd_clamp(velocity, minVel, maxVel)
        position = simd_clamp(position, minPos, maxPos)
    }
}
