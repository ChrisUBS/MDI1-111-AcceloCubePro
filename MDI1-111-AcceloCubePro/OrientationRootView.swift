//
//  OrientationRootView.swift
//  OrientationVisualizer
//
//  Created by Christian Bonilla on 04/11/25.
//

import SwiftUI

struct OrientationRootView: View {
    @ObservedObject var vm: MotionVM
    @State private var hz: Double = 60
    @State private var showCube: Bool = false
    @State private var demoMode: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                BubbleLevelView(vm: vm, targetTolerance: 3, radius: 110)
                    .padding(.top, 8)
                
                VStack(spacing: 6) {
                    Text(String(format: "roll %.1f°   pitch %.1f°   yaw %.1f°",
                                vm.rollDeg, vm.pitchDeg, vm.yawDeg))
                    .font(.system(.body, design: .monospaced))
                    Text(String(format: "Hz ~ %.0f", vm.sampleHz))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if showCube {
                    OrientationCubeView(vm: vm)
                        .frame(height: 220)
                        .padding(.vertical, 4)
                        .transition(.opacity.combined(with: .scale))
                }
                
                VStack(spacing: 12) {
                    HStack {
                        Toggle("Demo mode", isOn: $demoMode)
                            .onChange(of: demoMode) { _, new in vm.start(updateHz: hz, demo: new) }
                        Spacer()
                        Toggle("3D cube", isOn: $showCube)
                            .toggleStyle(.switch)
                    }
                    
                    HStack(spacing: 12) {
                        Text("Hz")
                        Slider(value: $hz, in: 15...100, step: 15)
                            .onChange(of: hz) { _, new in vm.start(updateHz: new, demo: demoMode) }
                        Text("\(Int(hz))").font(.system(.body, design: .monospaced))
                            .frame(width: 36, alignment: .trailing)
                    }
                    
                    HStack(spacing: 12) {
                        Button("Start") { vm.start(updateHz: hz, demo: demoMode) }
                            .buttonStyle(.borderedProminent)
                        Button("Stop") { vm.stop() }
                            .buttonStyle(.bordered)
                        Button("Calibrate") { vm.calibrate() }
                            .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                    
                    if let msg = vm.errorMessage {
                        Text(msg).foregroundStyle(.red).font(.footnote).multilineTextAlignment(.center)
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding()
                .navigationTitle("Orientation Visualizer")
                .onAppear { vm.start(updateHz: hz, demo: demoMode) }
                .onDisappear { vm.stop() }
            }
        }
    }
}
