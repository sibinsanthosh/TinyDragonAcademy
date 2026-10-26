//
//  GameLoop.swift
//  Tiny Dragon Academy
//
//  Fixed 60 Hz update loop for training games, driven by TimelineView.
//

import SwiftUI

struct GameLoop<Content: View>: View {
    static var fixedStep: Double { 1.0 / 60.0 }
    private static var maxStepsPerFrame: Int { 5 }

    let isRunning: Bool
    let step: (Double) -> Void
    let content: Content

    @State private var driver = LoopDriver()

    init(isRunning: Bool, step: @escaping (Double) -> Void, @ViewBuilder content: () -> Content) {
        self.isRunning = isRunning
        self.step = step
        self.content = content()
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: !isRunning)) { context in
            content
                .onChange(of: context.date) { _, date in
                    guard isRunning else { return }
                    advance(to: date)
                }
        }
        .onChange(of: isRunning) { _, _ in
            driver.lastDate = nil
            driver.accumulator = 0
        }
    }

    private func advance(to date: Date) {
        defer { driver.lastDate = date }
        guard let last = driver.lastDate else { return }
        driver.accumulator += min(0.25, max(0, date.timeIntervalSince(last)))
        var steps = 0
        while driver.accumulator >= Self.fixedStep && steps < Self.maxStepsPerFrame {
            step(Self.fixedStep)
            driver.accumulator -= Self.fixedStep
            steps += 1
        }
        // Drop the backlog after a hitch instead of spiralling
        if steps == Self.maxStepsPerFrame { driver.accumulator = 0 }
    }
}

private final class LoopDriver {
    var lastDate: Date?
    var accumulator: Double = 0
}
