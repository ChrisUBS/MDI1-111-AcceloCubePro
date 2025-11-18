//
//  ControlPanelView.swift
//  AcceloCubePro
//
//  Created by Christian Bonilla on 17/11/25.
//

import SwiftUI

struct ControlPanelView: View {
    @ObservedObject var vm: MotionVM
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button("Start") { vm.start(demo: vm.usingDemo) }
                    .buttonStyle(.borderedProminent)
                Button("Stop") { vm.stop() }
                    .buttonStyle(.bordered)
                Button("Re-Center") { vm.calibrate() }
                    .buttonStyle(.bordered)
            }
            
            VStack(alignment: .leading) {
                Text("Sample Rate: \(Int(vm.cfg.sampleHz)) Hz")
                Slider(value: $vm.cfg.sampleHz, in: 30...100, step: 30)
            }
            
            VStack(alignment: .leading) {
                Text(String(format: "Smoothing: %.2f", vm.cfg.smoothing))
                Slider(value: $vm.cfg.smoothing, in: 0...1, step: 0.05)
            }
            
            VStack(alignment: .leading) {
                Text(String(format: "Damping: %.2f", vm.cfg.damping))
                Slider(value: $vm.cfg.damping, in: 0...0.2, step: 0.01)
            }
            
            Toggle("Demo Mode", isOn: $vm.usingDemo)
                .onChange(of: vm.usingDemo) { _, newValue in
                    if vm.status != "Stopped" {
                        vm.start(demo: newValue)
                    }
                }
        }
    }
}
