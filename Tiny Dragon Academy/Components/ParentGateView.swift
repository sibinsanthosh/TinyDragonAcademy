//
//  ParentGateView.swift
//  Tiny Dragon Academy
//
//  App Store compliant Parental Gate challenge for grown-ups.
//  Protects settings, sound toggles, and data resets behind an adult math question.
//

import SwiftUI

struct ParentGateView: View {
    let onSuccess: () -> Void
    let onCancel: () -> Void
    
    @State private var num1: Int = 0
    @State private var num2: Int = 0
    @State private var answerOptions: [Int] = []
    @State private var showWiggle: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(DragonPalette.softPurple)
                    Text("Grown-Ups Only")
                        .font(.clay(24, .bold))
                        .foregroundColor(DragonPalette.textDark)
                }
                
                Text("Please solve this math question to continue:")
                    .font(.clay(16, .medium))
                    .foregroundColor(DragonPalette.textMuted)
                    .multilineTextAlignment(.center)
                
                // Question Box
                Text("What is \(num1) + \(num2) ?")
                    .font(.clay(32, .heavy))
                    .foregroundColor(DragonPalette.softPurple)
                    .padding(.vertical, 8)
                
                // Choice Buttons
                HStack(spacing: 16) {
                    ForEach(answerOptions, id: \.self) { choice in
                        Button(action: {
                            checkAnswer(choice)
                        }) {
                            Text("\(choice)")
                                .font(.clay(24, .bold))
                                .foregroundColor(DragonPalette.textDark)
                                .frame(width: 70, height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18)
                                                .stroke(DragonPalette.softPurple.opacity(0.4), lineWidth: 2)
                                        )
                                        .shadow(color: DragonPalette.softShadow, radius: 4, x: 0, y: 2)
                                )
                        }
                    }
                }
                .offset(x: showWiggle ? -10 : 0)
                
                // Cancel Button
                Button(action: onCancel) {
                    Text("Go Back")
                        .font(.clay(16, .semibold))
                        .foregroundColor(ClayColor.coralShade)
                        .padding(.top, 8)
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(red: 0.98, green: 0.97, blue: 1.0))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 20)
            )
            .padding(.horizontal, 28)
            .onAppear {
                generateQuestion()
            }
        }
    }
    
    private func generateQuestion() {
        num1 = Int.random(in: 4...9)
        num2 = Int.random(in: 3...8)
        let correct = num1 + num2
        
        var options = Set<Int>()
        options.insert(correct)
        while options.count < 3 {
            let offset = Int.random(in: -3...3)
            let wrong = correct + offset
            if wrong > 0 && wrong != correct {
                options.insert(wrong)
            }
        }
        answerOptions = Array(options).shuffled()
    }
    
    private func checkAnswer(_ choice: Int) {
        if choice == (num1 + num2) {
            HapticsService.shared.success()
            AudioService.shared.playChime()
            onSuccess()
        } else {
            HapticsService.shared.light()
            AudioService.shared.playEncouragement()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.2)) {
                showWiggle = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showWiggle = false
                generateQuestion()
            }
        }
    }
}
