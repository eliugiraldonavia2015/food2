import SwiftUI

struct SplashView: View {
    @State private var showLogo = false
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            BrandLogoView()
                .opacity(showLogo ? 1 : 0)
                .animation(.easeInOut(duration: 0.4), value: showLogo)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            showLogo = true
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
