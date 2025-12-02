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
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(index == currentStep ? .green : .gray)
                    .scaleEffect(index == currentStep ? 1.2 : 1.0)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentStep)
        .padding(.vertical, 12)
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
