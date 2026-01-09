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
                ForEach(Array(stride(from: 0, to: viewModel.interests.count, by: 2)), id: \.self) { i in
                    HStack(spacing: 0) {
                        let left = viewModel.interests[i]
                        Button {
                            viewModel.interests[i].isSelected.toggle()
                            viewModel.interests = viewModel.interests
                        } label: {
                            HStack(spacing: 10) {
                                Text(emoji(for: left.name))
                                Text(left.name)
                                    .font(.callout)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(left.isSelected ? .white : .white.opacity(0.9))
                            .padding(.horizontal, left.isSelected ? 22 : 18)
                            .padding(.vertical, 14)
                            .background(left.isSelected ? Capsule().fill(fuchsiaColor) : Capsule().fill(Color.black.opacity(0.35)))
                            .overlay(Capsule().stroke(left.isSelected ? fuchsiaColor.opacity(0.4) : Color.white.opacity(0.25), lineWidth: 1.3))
                            .shadow(color: left.isSelected ? fuchsiaColor.opacity(0.25) : .clear, radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        Spacer().frame(width: 6)
                        
                        if i + 1 < viewModel.interests.count {
                            let right = viewModel.interests[i+1]
                            Button {
                                viewModel.interests[i+1].isSelected.toggle()
                                viewModel.interests = viewModel.interests
                            } label: {
                                HStack(spacing: 10) {
                                    Text(emoji(for: right.name))
                                    Text(right.name)
                                        .font(.callout)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(right.isSelected ? .white : .white.opacity(0.9))
                                .padding(.horizontal, right.isSelected ? 22 : 18)
                                .padding(.vertical, 14)
                                .background(right.isSelected ? Capsule().fill(fuchsiaColor) : Capsule().fill(Color.black.opacity(0.35)))
                                .overlay(Capsule().stroke(right.isSelected ? fuchsiaColor.opacity(0.4) : Color.white.opacity(0.25), lineWidth: 1.3))
                                .shadow(color: right.isSelected ? fuchsiaColor.opacity(0.25) : .clear, radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Spacer().frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .padding(.horizontal, 4)
                .padding(.top, 8)
            }
            
            if viewModel.interests.filter({ $0.isSelected }).count < AppConstants.Validation.minInterests {
                Text("Selecciona al menos 3 intereses")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.9))
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
        let lower = name.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        if lower.contains("comida rapida") || lower.contains("rapida") { return "🍔" }
        if lower.contains("comida saludable") || lower.contains("saludable") { return "🥗" }
        if lower.contains("hamburguesa") || lower.contains("hamburguesas") { return "🍔" }
        if lower.contains("pizza") { return "🍕" }
        if lower.contains("sushi") { return "🍣" }
        if lower.contains("pasta") || lower.contains("pastas") { return "🍝" }
        if lower.contains("ensalada") || lower.contains("ensaladas") { return "🥗" }
        if lower.contains("asado") || lower.contains("asados") { return "🍗" }
        if lower.contains("tacos") || lower.contains("mexicana") { return "🌮" }
        if lower.contains("china") { return "🥡" }
        if lower.contains("arabe") { return "🥙" }
        if lower.contains("mariscos") { return "🦐" }
        if lower.contains("tipica") { return "🍲" }
        if lower.contains("sandwich") || lower.contains("sandwiches") || lower.contains("sándwich") || lower.contains("sándwiches") { return "🥪" }
        if lower.contains("desayuno") || lower.contains("desayunos") { return "🍳" }
        if lower.contains("brunch") { return "🍳" }
        if lower.contains("postres") || lower.contains("postre") { return "🍰" }
        if lower.contains("helado") || lower.contains("helados") { return "🍦" }
        if lower.contains("panaderia") { return "🥐" }
        if lower.contains("donas") || lower.contains("dona") { return "🍩" }
        if lower.contains("tortas") || lower.contains("pasteles") { return "🎂" }
        if lower.contains("cafe") { return "☕️" }
        if lower.contains("jugos") || lower.contains("jugos naturales") { return "🧃" }
        if lower.contains("cerveza") { return "🍺" }
        if lower.contains("vinos") || lower.contains("vino") { return "🍷" }
        if lower.contains("cocteles") || lower.contains("cócteles") { return "🍹" }
        if lower.contains("malteadas") || lower.contains("malteada") { return "🥤" }
        if lower.contains("snacks") || lower.contains("snack") { return "🍿" }
        if lower.contains("tapas") || lower.contains("entradas") { return "🍤" }
        return "🍽️"
    }
}
