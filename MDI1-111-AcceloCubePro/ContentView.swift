//
//  ContentView.swift
//  AcceloCubePro
//
//  Created by Christian Bonilla on 17/11/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var vm: MotionVM
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                // 3D Scene View
                SceneViewBridge(quat: $vm.quat, position: $vm.position)
                    .frame(height: 300)
                    .padding(.top)
                
                Divider()
                
                // Control Panel
                ControlPanelView(vm: vm)
                    .padding()
                
                Divider()
                
                // Status HUD
                HStack {
                    Spacer()
                    VStack(alignment: .center, spacing: 2) {
                        Text("Status: \(vm.status)")
                        Text(String(format: "Sample Rate: %.0f Hz", vm.cfg.sampleHz))
                        Text(String(format: "Latency: %.1f ms", vm.latencyMs))
                    }
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("AcceloCubePro")
        }
    }
}
