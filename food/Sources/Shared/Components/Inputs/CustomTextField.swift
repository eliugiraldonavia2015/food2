//
//  CustomTextField.swift
//  food
//
//  Created by eliu giraldo on 28/11/25.
//

// Sources/Shared/Components/Inputs/CustomTextField.swift
import SwiftUI

struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    let isSecure: Bool
    let isAvailable: Bool?
    let isChecking: Bool
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isFocused ? .green : .gray) // Cambié a green para mantener consistencia
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .focused($isFocused)
            } else {
                TextField(placeholder, text: $text)
                    .focused($isFocused)
            }
            
            if let isAvailable = isAvailable, !isSecure {
                if isChecking {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                        .frame(width: 20, height: 20)
                } else if isAvailable {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? .green : Color(.systemGray3), lineWidth: 1) // Cambié a green
                )
        )
        .foregroundColor(.white)
        .accentColor(.green) // Cambié a green
    }
}
