import SwiftUI

struct AllCategoriesView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedCategory: String?
    @State private var animateContent = false
    
    // Grid Configuration
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    // Design Constants
    private let primaryColor = Color.green
    private let backgroundColor = Color.white
    private let primaryTextColor = Color.black.opacity(0.9)
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            animateContent = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(primaryTextColor)
                            .padding(12)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Todas las Categorías")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(primaryTextColor)
                    
                    Spacer()
                    
                    // Placeholder for balance
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                // Content
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(Array(allCategoryItems.enumerated()), id: \.element.id) { index, item in
                            CategoryCard(item: item, index: index, animate: animateContent, isSelected: selectedCategory == item.name)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        selectedCategory = item.name
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateContent = true
            }
        }
    }
}

struct CategoryCard: View {
    let item: CategoryItem
    let index: Int
    let animate: Bool
    let isSelected: Bool
    
    private let primaryColor = Color.green
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? primaryColor : Color.clear, lineWidth: 3)
                    )
                
                if let path = Bundle.main.path(forResource: item.image, ofType: "png", inDirectory: "CategoryImages"),
                   let uiImage = UIImage(contentsOfFile: path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else if let uiImage = UIImage(named: item.image) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "fork.knife")
                                .foregroundColor(.gray)
                        )
                }
            }
            .frame(height: 100)
            
            Text(item.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .scaleEffect(animate ? 1 : 0.5)
        .opacity(animate ? 1 : 0)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.7)
            .delay(Double(index) * 0.05),
            value: animate
        )
    }
}
