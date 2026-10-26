//
//  Tiny_Dragon_AcademyApp.swift
//  Tiny Dragon Academy
//
//  Created by Sibin on 20/10/26.
//

import SwiftUI

@main
struct Tiny_Dragon_AcademyApp: App {
    @StateObject private var gameManager = GameManager()
    
    init() {
        #if DEBUG
        GameLogicTests.runAllTests()
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameManager)
        }
    }
}
