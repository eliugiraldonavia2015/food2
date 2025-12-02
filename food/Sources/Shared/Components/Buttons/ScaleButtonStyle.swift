//
//  ScaleButtonStyle.swift
//  food
//
//  Created by eliu giraldo on 28/11/25.
//

// Sources/Shared/Components/Buttons/ScaleButtonStyle.swift
import SwiftUI

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
