//
//  OnboardingProgressView.swift
//  food
//
//  Created by eliu giraldo on 28/11/25.
//

import SwiftUI

/// Muestra el progreso del onboarding con dots
public struct OnboardingProgressView: View {
    let totalSteps: Int
    let currentStep: Int
    
    public init(totalSteps: Int, currentStep: Int) {
        self.totalSteps = totalSteps
        self.currentStep = currentStep
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundColor(index == currentStep ? .white : Color.white.opacity(0.4))
                    .shadow(color: index == currentStep ? Color.black.opacity(0.2) : .clear, radius: 2, x: 0, y: 1)
                    .scaleEffect(index == currentStep ? 1.15 : 1.0)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentStep)
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
struct OnboardingProgressView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingProgressView(totalSteps: 4, currentStep: 1)
            .padding()
            .background(Color(.systemBackground))
    }
}
