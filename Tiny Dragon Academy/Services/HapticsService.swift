//
//  HapticsService.swift
//  Tiny Dragon Academy
//
//  Delightful, gentle haptic feedback for touch interactions on iOS devices.
//

import UIKit

final class HapticsService {
    static let shared = HapticsService()
    
    private init() {}
    
    func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
