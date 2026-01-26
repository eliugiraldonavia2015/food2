import SwiftUI

struct ReviewsView: View {
    var onMenuTap: () -> Void
    
    // MARK: - State
    @State private var animate = false
    
    // Colors
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let bgGray = Color(red: 249/255, green: 249/255, blue: 249/255)
    
    var body: some View {
        ZStack {
            bgGray.ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        satisfactionSummary
                        reviewsFeed
                        Spacer(minLength: 80)
                    }
                    .padding(20)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animate = true
            }
        }
    }
    
    // MARK: - Components
    
    private var header: some View {
        HStack {
            Button(action: onMenuTap) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            VStack(alignment: .center, spacing: 2) {
                Text("Opiniones")
                    .font(.title3.bold())
                    .foregroundColor(.black)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption)
                    Text("Sucursal Centro")
                        .font(.caption.bold())
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(brandPink)
                Text("4.8")
                    .font(.headline.bold())
                    .foregroundColor(brandPink)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(brandPink.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color.white)
    }
    
    private var satisfactionSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Resumen de\nSatisfacción")
                    .font(.title3.bold())
                    .foregroundColor(.black)
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "face.smiling.fill")
                    Text("Muy Positivo")
                }
                .font(.subheadline.bold())
                .foregroundColor(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(20)
            }
            
            VStack(spacing: 12) {
                ratingBar(stars: 5, percentage: 0.85, color: brandPink)
                ratingBar(stars: 4, percentage: 0.10, color: brandPink)
                ratingBar(stars: 3, percentage: 0.03, color: brandPink)
                ratingBar(stars: 2, percentage: 0.01, color: brandPink)
                ratingBar(stars: 1, percentage: 0.01, color: brandPink)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    private func ratingBar(stars: Int, percentage: CGFloat, color: Color) -> some View {
        HStack(spacing: 12) {
            Text("\(stars)")
                .font(.headline.bold())
                .foregroundColor(.black)
                .frame(width: 12)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(color)
                        .frame(width: animate ? geo.size.width * percentage : 0, height: 8)
                }
            }
            .frame(height: 8)
            
            Text("\(Int(percentage * 100))%")
                .font(.caption.bold())
                .foregroundColor(.gray)
                .frame(width: 30, alignment: .trailing)
        }
    }
    
    private var reviewsFeed: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Feed de Reseñas")
                .font(.headline.bold())
                .foregroundColor(.black)
            
            VStack(spacing: 16) {
                reviewCard(
                    name: "Carla Mendoza",
                    time: "Hace 2 horas",
                    rating: 5,
                    comment: "La atención fue increíble y los tacos al pastor son sin duda los mejores de la zona. ¡Volveremos pronto!",
                    initial: "CM",
                    color: .orange
                )
                
                reviewCard(
                    name: "Roberto G.",
                    time: "Hace 5 horas",
                    rating: 4,
                    comment: "El sabor es bueno pero el tiempo de espera fue un poco excesivo para ser un martes. Ojalá puedan mejorar la rapidez.",
                    initial: "RG",
                    color: .brown
                )
                
                reviewCard(
                    name: "María Auxilio",
                    time: "Ayer",
                    rating: 5,
                    comment: "Excelente promoción de 2x1. Muy recomendada la salsa de la casa.",
                    initial: "MA",
                    color: .blue
                )
                
                reviewCard(
                    name: "Pedro Páramo",
                    time: "Ayer",
                    rating: 5,
                    comment: "Comala nunca había tenido unos tacos tan buenos. El servicio es rápido y amable.",
                    initial: "PP",
                    color: .green
                )
            }
        }
    }
    
    private func reviewCard(name: String, time: String, rating: Int, comment: String, initial: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(initial)
                            .font(.headline.bold())
                            .foregroundColor(color)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.headline.bold())
                        .foregroundColor(.black)
                    Text(time.uppercased())
                        .font(.caption.bold())
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            HStack(spacing: 2) {
                ForEach(0..<5) { i in
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(i < rating ? brandPink : .gray.opacity(0.3))
                }
            }
            
            Text(comment)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
}
