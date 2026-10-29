//
//  HoldDragTapView.swift
//  Tiny Dragon Academy
//
//  Tap and hold-then-drag recognizers for items inside a ScrollView.
//  SwiftUI long-press/drag gestures on scroll content swallow the swipe,
//  so the strip can't scroll. UIKit recognizers let a quick swipe go to the
//  scroll view and only take over once the finger has been held still.
//

import SwiftUI
import UIKit

struct HoldDragTapView: UIViewRepresentable {
    var minimumHold: TimeInterval = 0.22
    /// All locations are in window (SwiftUI `.global`) coordinates.
    var onTap: (CGPoint) -> Void
    var onDragChanged: (CGPoint) -> Void
    var onDragEnded: (CGPoint) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        let hold = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleHold(_:)))
        hold.minimumPressDuration = minimumHold
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(hold)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject {
        var parent: HoldDragTapView

        init(parent: HoldDragTapView) {
            self.parent = parent
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            parent.onTap(gesture.location(in: nil))
        }

        @objc func handleHold(_ gesture: UILongPressGestureRecognizer) {
            let location = gesture.location(in: nil)
            switch gesture.state {
            case .began, .changed:
                parent.onDragChanged(location)
            case .ended, .cancelled:
                parent.onDragEnded(location)
            default:
                break
            }
        }
    }
}
