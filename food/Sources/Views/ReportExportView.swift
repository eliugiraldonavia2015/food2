import SwiftUI

struct ReportExportView: View {
    @Environment(\.presentationMode) var presentationMode
    
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let bgGray = Color(red: 249/255, green: 249/255, blue: 249/255)
    
    @State private var selectedFormat = "PDF"
    @State private var includeCharts = true
    @State private var includeComments = false
    @State private var isExporting = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.title2.bold())
                                .foregroundColor(.black)
                                .padding(10)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        Spacer()
                        
                        Text("Exportar Informe")
                            .font(.title3.bold())
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Color.clear.frame(width: 44, height: 44)
                    }
                    .padding()
                    .background(bgGray)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            
                            // Format Selection
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Formato de Archivo")
                                    .font(.headline.bold())
                                    .foregroundColor(.black)
                                
                                HStack(spacing: 16) {
                                    formatOption(icon: "doc.fill", title: "PDF", isSelected: selectedFormat == "PDF")
                                    formatOption(icon: "tablecells.fill", title: "Excel", isSelected: selectedFormat == "Excel")
                                    formatOption(icon: "doc.text.fill", title: "CSV", isSelected: selectedFormat == "CSV")
                                }
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(24)
                            .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Options
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Opciones de Exportación")
                                    .font(.headline.bold())
                                    .foregroundColor(.black)
                                
                                Toggle(isOn: $includeCharts) {
                                    HStack {
                                        Image(systemName: "chart.pie.fill")
                                            .foregroundColor(brandPink)
                                        Text("Incluir Gráficos")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.black)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: brandPink))
                                
                                Divider()
                                
                                Toggle(isOn: $includeComments) {
                                    HStack {
                                        Image(systemName: "text.bubble.fill")
                                            .foregroundColor(brandPink)
                                        Text("Incluir Comentarios")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.black)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: brandPink))
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(24)
                            .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
                            .padding(.horizontal, 20)
                            
                            Spacer(minLength: 30)
                            
                            // Export Button
                            Button(action: startExport) {
                                HStack {
                                    if isExporting {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .padding(.trailing, 8)
                                    } else {
                                        Image(systemName: "square.and.arrow.up")
                                    }
                                    
                                    Text(isExporting ? "Generando..." : "Exportar Reporte")
                                }
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(brandPink)
                                .cornerRadius(16)
                                .shadow(color: brandPink.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .padding(.horizontal, 20)
                            .disabled(isExporting)
                        }
                        .padding(.vertical)
                    }
                }
                .background(bgGray.ignoresSafeArea())
                
                // Success Overlay
                if showSuccess {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation { showSuccess = false }
                        }
                    
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("¡Exportación Exitosa!")
                            .font(.title3.bold())
                            .foregroundColor(.black)
                        
                        Text("El archivo se ha guardado correctamente en tu dispositivo.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            withAnimation { showSuccess = false }
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Entendido")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(brandPink)
                                .cornerRadius(20)
                        }
                    }
                    .padding(30)
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(radius: 20)
                    .padding(40)
                    .transition(.scale)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func formatOption(icon: String, title: String, isSelected: Bool) -> some View {
        Button(action: { selectedFormat = title }) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? brandPink : .gray)
                
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(isSelected ? brandPink : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? brandPink.opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? brandPink : Color.clear, lineWidth: 2)
            )
        }
    }
    
    private func startExport() {
        withAnimation { isExporting = true }
        
        // Simulate network/processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                isExporting = false
                showSuccess = true
            }
        }
    }
}
