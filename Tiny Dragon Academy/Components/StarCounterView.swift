//
//  StarCounterView.swift
//  Tiny Dragon Academy
//
//  The star balance as a clay pill; bumps whenever it changes.
//

import SwiftUI

struct StarCounterView: View {
    let count: Int
    var isInteractive: Bool = false
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            guard isInteractive else { return }
            HapticsService.shared.light()
            AudioService.shared.playChime()
            onTap?()
        } label: {
            ClayPill(systemName: "star.fill", iconColor: ClayColor.sun, value: "\(count)", accessibilityLabel: "Stars")
        }
        .buttonStyle(.plain)
        .disabled(!isInteractive)
    }
}
