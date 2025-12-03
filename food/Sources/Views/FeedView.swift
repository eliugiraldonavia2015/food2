import SwiftUI

struct FeedView: View {
    private let sampleImages: [String] = [
        "https://images.pexels.com/photos/1640772/pexels-photo-1640772.jpeg",
        "https://images.pexels.com/photos/704569/pexels-photo-704569.jpeg",
        "https://images.pexels.com/photos/461198/pexels-photo-461198.jpeg",
        "https://images.pexels.com/photos/1435893/pexels-photo-1435893.jpeg"
    ]

    var body: some View {
        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    ForEach(sampleImages, id: \.self) { url in
                        ZStack {
                            AsyncImage(url: URL(string: url)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geo.size.width - 24, height: geo.size.height * 0.72)
                                    .clipped()
                            } placeholder: {
                                Color.black.opacity(0.4)
                            }
                            .cornerRadius(20)

                            LinearGradient(
                                colors: [.black.opacity(0.55), .clear, .black.opacity(0.8)],
                                startPoint: .bottom, endPoint: .top
                            )
                            .cornerRadius(20)

                            // Overlay UI estilo TikTok
                            VStack {
                                HStack {
                                    Text("FoodTook")
                                        .font(.headline.bold())
                                        .foregroundColor(.white)
                                    Spacer()
                                    HStack(spacing: 18) {
                                        Image(systemName: "heart.fill").foregroundColor(.white)
                                        Image(systemName: "bubble.left.and.bubble.right.fill").foregroundColor(.white)
                                        Image(systemName: "arrowshape.turn.up.right.fill").foregroundColor(.white)
                                    }
                                    .font(.system(size: 18, weight: .semibold))
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 14)

                                Spacer()

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Restaurante La Plaza")
                                        .foregroundColor(.white)
                                        .font(.headline.bold())
                                    Text("Descubre el nuevo combo especial con sabores auténticos.")
                                        .foregroundColor(.white.opacity(0.9))
                                        .font(.footnote)
                                        .lineLimit(2)
                                    HStack(spacing: 12) {
                                        Capsule()
                                            .fill(Color.green.opacity(0.25))
                                            .frame(width: 80, height: 26)
                                            .overlay(Text("Combo").foregroundColor(.green).font(.caption.bold()))
                                        Capsule()
                                            .fill(Color.orange.opacity(0.25))
                                            .frame(width: 90, height: 26)
                                            .overlay(Text("Oferta").foregroundColor(.orange).font(.caption.bold()))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                            }
                        }
                        .frame(height: geo.size.height * 0.72)
                        .shadow(color: .black.opacity(0.35), radius: 20, x: 0, y: 12)
                        .padding(.horizontal, 12)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}