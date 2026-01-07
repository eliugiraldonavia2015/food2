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
    
    // Define fuchsia color locally or use a shared extension if available.
    // For now, using the hex color directly.
    private let fuchsiaColor = Color(red: 217/255, green: 4/255, blue: 103/255)
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color.gray)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .focused($isFocused)
                    .foregroundColor(.black)
            } else {
                TextField(placeholder, text: $text)
                    .focused($isFocused)
                    .foregroundColor(.black)
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
                .fill(Color(.systemGray6)) // Lighter background for light theme
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? fuchsiaColor : Color.clear, lineWidth: 1)
        )
    }
}
