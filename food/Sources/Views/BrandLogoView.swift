import SwiftUI

struct BrandLogoView: View {
    private let fuchsiaColor = Color(red: 244/255, green: 37/255, blue: 123/255)
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon Container
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                Image("foodtookoficialicon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80) // Full width of container for max zoom
                    .clipShape(RoundedRectangle(cornerRadius: 20)) // Match container corner radius
            }
        }
    }
}

struct BrandLogoView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack { 
            Color.gray.opacity(0.2).ignoresSafeArea()
            BrandLogoView() 
        }
    }
}
