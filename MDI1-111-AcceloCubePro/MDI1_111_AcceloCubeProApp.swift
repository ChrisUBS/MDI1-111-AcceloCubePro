//
//  MDI1_111_AcceloCubeProApp.swift
//  MDI1-111-AcceloCubePro
//
//  Created by Christian Bonilla on 10/11/25.
//

import SwiftUI

@main
struct AcceloCubeProApp: App {
    @StateObject private var motionVM = MotionVM()
    
    var body: some Scene {
        WindowGroup {
            ContentView(vm: motionVM)
        }
    }
}
