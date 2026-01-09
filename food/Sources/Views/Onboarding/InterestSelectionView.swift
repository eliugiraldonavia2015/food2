//
//  InterestSelectionView.swift
//  food
//
//  Created by Gabriel Barzola arana on 10/11/25.
//

import SwiftUI

// Sources/Views/Onboarding/InterestSelectionView.swift
struct InterestSelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    private let fuchsiaColor = Color(red: 244/255, green: 37/255, blue: 123/255)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("¿Qué te gusta?")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Elige tus categorías favoritas para personalizar tu feed.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            
            ScrollView {
                let columns = [
                    GridItem(.flexible(), spacing: 8, alignment: .center),
                    GridItem(.flexible(), spacing: 8, alignment: .center)
                ]
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach($viewModel.interests) { $option in
                        Button {
                            option.isSelected.toggle()
                        } label: {
                            HStack(spacing: 10) {
                                Text(emoji(for: option.name))
                                Text(option.name)
                                    .font(.callout)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(option.isSelected ? .white : .white.opacity(0.9))
                            .padding(.horizontal, option.isSelected ? 22 : 18)
                            .padding(.vertical, 14)
                            .background(
                                Group {
                                    if option.isSelected {
                                        Capsule().fill(fuchsiaColor)
                                    } else {
                                        Capsule().fill(Color.black.opacity(0.35))
                                    }
                                }
                            )
                            .overlay(
                                Capsule().stroke(option.isSelected ? fuchsiaColor.opacity(0.4) : Color.white.opacity(0.25), lineWidth: 1.3)
                            )
                            .shadow(color: option.isSelected ? fuchsiaColor.opacity(0.25) : .clear, radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
            }
            
            Button(action: { viewModel.nextStep() }) {
                Text("Siguiente")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .background(fuchsiaColor)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .shadow(color: fuchsiaColor.opacity(0.3), radius: 10, x: 0, y: 5)
            .padding(.horizontal)
            .disabled(viewModel.interests.filter { $0.isSelected }.count < AppConstants.Validation.minInterests)
            
            Spacer()
        }
        .padding(.top)
        .animation(.easeInOut, value: viewModel.interests)
    }
    
    private func emoji(for name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("pizza") { return "🍕" }
        if lower.contains("burger") || lower.contains("rápida") { return "🍔" }
        if lower.contains("sushi") || lower.contains("internacional") { return "🍣" }
        if lower.contains("taco") { return "🌮" }
        if lower.contains("saludable") { return "🥗" }
        if lower.contains("pasta") { return "🍝" }
        if lower.contains("postre") { return "🍰" }
        if lower.contains("café") || lower.contains("bebidas") { return "☕️" }
        if lower.contains("ramen") || lower.contains("local") { return "🍜" }
        return "🍽️"
    }
}
