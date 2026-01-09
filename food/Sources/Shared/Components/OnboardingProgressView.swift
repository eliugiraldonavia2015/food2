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
    private let fuchsiaColor = Color(red: 244/255, green: 37/255, blue: 123/255)
    
    public init(totalSteps: Int, currentStep: Int) {
        self.totalSteps = totalSteps
        self.currentStep = currentStep
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { index in
                if index == currentStep {
                    Capsule()
                        .frame(width: 16, height: 6)
                        .foregroundColor(fuchsiaColor)
                        .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 2)
                } else {
                    Circle()
                        .frame(width: 6, height: 6)
                        .foregroundColor(Color.white.opacity(0.4))
                }
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
