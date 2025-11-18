//
//  BubbleLevelView.swift
//  OrientationVisualizer
//
//  Created by Christian Bonilla on 04/11/25.
//

import SwiftUI

struct BubbleLevelView: View {
    @ObservedObject var vm: MotionVM
    var targetTolerance: Double = 3
    var radius: CGFloat = 110

    var body: some View {
        ZStack {
            // Outer circle
            Circle()
                .stroke(lineWidth: 2)
                .foregroundStyle(.secondary)
                .frame(width: radius * 2, height: radius * 2)

            // Centered dashed crosshair
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

                Path { path in
                    // Horizontal line
                    path.move(to: CGPoint(x: center.x - radius, y: center.y))
                    path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
                    // Vertical line
                    path.move(to: CGPoint(x: center.x, y: center.y - radius))
                    path.addLine(to: CGPoint(x: center.x, y: center.y + radius))
                }
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                .foregroundStyle(.tertiary)
            }
            .frame(width: radius * 2, height: radius * 2)

            // Bubble indicator
            Circle()
                .fill(isLevel ? Color.green.opacity(0.75) : Color.orange.opacity(0.75))
                .frame(width: 24, height: 24)
                .shadow(radius: 2)
                .offset(bubbleOffset)
                .animation(.easeOut(duration: 0.08), value: vm.rollDeg)
                .animation(.easeOut(duration: 0.08), value: vm.pitchDeg)
        }
        .frame(width: radius * 2, height: radius * 2)
        .overlay(alignment: .bottom) {
            VStack(spacing: 4) {
                Text(String(format: "roll %.1f°   pitch %.1f°", vm.rollDeg, vm.pitchDeg))
                    .font(.caption)
                    .monospacedDigit()

                Text(String(format: "Hz %.0f", vm.sampleHz))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
        }
        .accessibilityLabel("Bubble level")
    }

    private var isLevel: Bool {
        abs(vm.rollDeg) <= targetTolerance && abs(vm.pitchDeg) <= targetTolerance
    }

    private var bubbleOffset: CGSize {
        let scale: CGFloat = radius / 15
        var x = CGFloat(vm.rollDeg) * scale
        var y = CGFloat(-vm.pitchDeg) * scale
        let dist = sqrt(x * x + y * y)
        if dist > radius {
            x *= radius / dist
            y *= radius / dist
        }
        return CGSize(width: x, height: y)
    }
}
