import SwiftUI

struct BrandLogoView: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                Text("Food")
                    .font(.system(size: 60, weight: .black, design: .default))
                    .foregroundColor(.white)
                Text("Took")
                    .font(.system(size: 60, weight: .black, design: .default))
                    .foregroundColor(.green)
            }
            Text("Taste the trend.")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.3))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
        }
        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
    }
}

struct BrandLogoView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack { Color.black.ignoresSafeArea(); BrandLogoView() }
            .preferredColorScheme(.dark)
    }
}
