import SwiftUI

struct BrandLogoView: View {
    private let fuchsiaColor = Color(red: 217/255, green: 4/255, blue: 103/255)
    
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
                    .frame(width: 65, height: 65)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            // Text
            Text("FoodTook")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.black)
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
