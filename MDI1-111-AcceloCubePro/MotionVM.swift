//
//  MotionVM.swift
//  MDI1-110-OrientationVisualizer
//
//  Created by Christian Bonilla on 04/11/25.
//

import Foundation
import CoreMotion
import Combine
import simd

@MainActor
final class MotionVM: ObservableObject {
    @Published var rollDeg: Double = 0
    @Published var pitchDeg: Double = 0
    @Published var yawDeg: Double = 0
    @Published var qx: Double = 0
    @Published var qy: Double = 0
    @Published var qz: Double = 0
    @Published var qw: Double = 1
    @Published var sampleHz: Double = 0
    @Published var usingDemo: Bool = false
    @Published var errorMessage: String? = nil
    
    var alpha: Double = 0.15
    private var offRoll: Double = 0
    private var offPitch: Double = 0
    private var offYaw: Double = 0
    
    private let mgr = CMMotionManager()
    private let queue = OperationQueue()
    private var lastTimestamp: TimeInterval?
    private var demoTask: Task<Void, Never>?
    
    // MARK: - Start Motion Updates
    func start(updateHz: Double = 60, demo: Bool? = nil) {
        stop()
        if let d = demo { usingDemo = d }
        errorMessage = nil

        if usingDemo {
            startDemo(updateHz: updateHz)
            return
        }

        guard mgr.isDeviceMotionAvailable else {
            errorMessage = "Device Motion not available. Enable Demo mode."
            return
        }

        mgr.deviceMotionUpdateInterval = 1.0 / updateHz
        lastTimestamp = nil

        mgr.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] motion, error in
            guard let self else { return }

            if let error {
                Task { @MainActor in
                    self.errorMessage = error.localizedDescription
                }
            }

            guard let m = motion else { return }

            let ts = m.timestamp
            let dt = self.lastTimestamp.map { ts - $0 } ?? (1.0 / updateHz)
            self.lastTimestamp = ts
            let hz = dt > 0 ? 1.0 / dt : updateHz

            let r = m.attitude.roll.toDegrees
            let p = m.attitude.pitch.toDegrees
            let y = m.attitude.yaw.toDegrees
            let q = m.attitude.quaternion

            let newRoll = self.lowPass(current: r - self.offRoll, previous: self.rollDeg)
            let newPitch = self.lowPass(current: p - self.offPitch, previous: self.pitchDeg)
            let newYaw = self.lowPass(current: y - self.offYaw, previous: self.yawDeg)

            Task { @MainActor in
                self.rollDeg = newRoll
                self.pitchDeg = newPitch
                self.yawDeg = newYaw
                self.qx = q.x; self.qy = q.y; self.qz = q.z; self.qw = q.w
                self.sampleHz = hz
            }
        }
    }
    
    // MARK: - Stop Motion Updates
    func stop() {
        mgr.stopDeviceMotionUpdates()
        demoTask?.cancel()
        demoTask = nil
        lastTimestamp = nil
    }
    
    // MARK: - Calibrate Orientation
    func calibrate() {
        offRoll += rollDeg
        offPitch += pitchDeg
        offYaw += yawDeg
    }
    
    // MARK: - Demo Mode (for Simulators)
    private func startDemo(updateHz: Double) {
        demoTask = Task { [weak self] in
            guard let self else { return }
            var t: Double = 0
            let dt = 1.0 / updateHz

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(dt * 1_000_000_000))
                t += dt
                
                // Simulate smooth movements
                let r = sin(t * 1.2) * 8
                let p = cos(t * 0.9) * 6

                // Animate 3D orientation (rotating quaternions)
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
                    self.yawDeg = 0
                    self.qx = qx
                    self.qy = qy
                    self.qz = qz
                    self.qw = qw
                    self.sampleHz = updateHz
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func lowPass(current: Double, previous: Double) -> Double {
        previous + alpha * (current - previous)
    }
}

// MARK: - Extensions
private extension Double {
    var toDegrees: Double { self * 180.0 / .pi }
}
