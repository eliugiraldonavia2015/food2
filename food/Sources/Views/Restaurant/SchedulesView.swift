import SwiftUI

struct SchedulesView: View {
    var onMenuTap: () -> Void
    
    // MARK: - State
    @State private var animate = false
    @State private var selectedMode = 0 // 0: Global, 1: Por Sucursal
    @State private var showSaveToast = false
    
    // Colors
    private let brandPink = Color(red: 244/255, green: 37/255, blue: 123/255)
    private let bgGray = Color(red: 249/255, green: 249/255, blue: 249/255)
    
    // Mock Data
    @State private var weekSchedule: [DaySchedule] = [
        DaySchedule(day: "Lunes", isOpen: true, open: "09:00", close: "22:00"),
        DaySchedule(day: "Martes", isOpen: true, open: "09:00", close: "22:00"),
        DaySchedule(day: "Miércoles", isOpen: true, open: "09:00", close: "22:00"),
        DaySchedule(day: "Jueves", isOpen: true, open: "09:00", close: "23:00"),
        DaySchedule(day: "Viernes", isOpen: true, open: "09:00", close: "00:00"),
        DaySchedule(day: "Sábado", isOpen: true, open: "10:00", close: "01:00"),
        DaySchedule(day: "Domingo", isOpen: true, open: "10:00", close: "21:00")
    ]
    
    private let branches = ["Sucursal Centro", "Sucursal Polanco", "Sucursal Roma", "Sucursal Condesa"]
    
    struct DaySchedule: Identifiable {
        let id = UUID()
        var day: String
        var isOpen: Bool
        var open: String
        var close: String
    }
    
    var body: some View {
        ZStack {
            bgGray.ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        modeSelector
                        
                        if selectedMode == 0 {
                            globalScheduleSection
                        } else {
                            branchListSection
                        }
                        
                        holidaysSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(20)
                }
            }
            
            // Floating Save Button (only for Global mode or when editing)
            if selectedMode == 0 {
                VStack {
                    Spacer()
                    Button(action: {
                        withAnimation { showSaveToast = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { showSaveToast = false }
                        }
                    }) {
                        Text("Guardar Cambios")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(brandPink)
                            .cornerRadius(16)
                            .shadow(color: brandPink.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .padding(20)
                }
            }
            
            // Toast
            if showSaveToast {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Horarios actualizados correctamente")
                            .font(.subheadline.bold())
                            .foregroundColor(.black)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .padding(.top, 60)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
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
            
            Text("Horarios")
                .font(.title3.bold())
                .foregroundColor(.black)
            
            Spacer()
            
            Image(systemName: "clock.fill")
                .font(.system(size: 20))
                .foregroundColor(brandPink)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color.white)
    }
    
    private var modeSelector: some View {
        HStack(spacing: 0) {
            modeButton(title: "Horario Global", icon: "globe", index: 0)
            modeButton(title: "Por Sucursal", icon: "building.2.fill", index: 1)
        }
        .padding(4)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5)
        .offset(y: animate ? 0 : 20)
        .opacity(animate ? 1 : 0)
    }
    
    private func modeButton(title: String, icon: String, index: Int) -> some View {
        Button(action: { withAnimation(.spring()) { selectedMode = index } }) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(selectedMode == index ? .white : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selectedMode == index ? brandPink : Color.clear)
            .cornerRadius(12)
        }
    }
    
    private var globalScheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Horario Estándar")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                    Text("Aplica para todas las sucursales")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                Button(action: {}) {
                    Text("Copiar Lunes a todos")
                        .font(.caption.bold())
                        .foregroundColor(brandPink)
                }
            }
            
            VStack(spacing: 0) {
                ForEach($weekSchedule) { $day in
                    scheduleRow(item: $day)
                    if day.id != weekSchedule.last?.id {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
        }
        .offset(y: animate ? 0 : 20)
        .opacity(animate ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.2), value: animate)
    }
    
    private func scheduleRow(item: Binding<DaySchedule>) -> some View {
        HStack {
            Text(item.wrappedValue.day)
                .font(.subheadline.bold())
                .foregroundColor(.black)
                .frame(width: 80, alignment: .leading)
            
            Toggle("", isOn: item.isOpen)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: brandPink))
                .scaleEffect(0.8)
            
            Spacer()
            
            if item.wrappedValue.isOpen {
                HStack(spacing: 8) {
                    timePill(time: item.open)
                    Text("-")
                        .foregroundColor(.gray)
                    timePill(time: item.close)
                }
            } else {
                Text("Cerrado")
                    .font(.subheadline.bold())
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 12)
            }
        }
        .padding(16)
        .background(item.wrappedValue.isOpen ? Color.white : Color.gray.opacity(0.05))
    }
    
    private func timePill(time: Binding<String>) -> some View {
        Text(time.wrappedValue)
            .font(.subheadline.bold())
            .foregroundColor(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .onTapGesture {
                // Here would go a time picker logic
            }
    }
    
    private var branchListSection: some View {
        VStack(spacing: 16) {
            ForEach(branches, id: \.self) { branch in
                branchCard(name: branch)
            }
        }
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }
    
    private func branchCard(name: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline.bold())
                    .foregroundColor(.black)
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Abierto ahora")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("09:00 - 22:00")
                    .font(.subheadline.bold())
                    .foregroundColor(.gray)
                Text("Configuración propia")
                    .font(.caption)
                    .foregroundColor(brandPink)
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
                .padding(.leading, 8)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    private var holidaysSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fechas Especiales / Feriados")
                .font(.headline.bold())
                .foregroundColor(.black)
            
            VStack(spacing: 12) {
                holidayRow(date: "25 Dic", name: "Navidad", status: "Cerrado")
                holidayRow(date: "01 Ene", name: "Año Nuevo", status: "12:00 - 20:00")
                
                Button(action: {}) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Agregar fecha especial")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(brandPink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(brandPink.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
        }
        .offset(y: animate ? 0 : 20)
        .opacity(animate ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.3), value: animate)
    }
    
    private func holidayRow(date: String, name: String, status: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(date)
                    .font(.caption.bold())
                    .foregroundColor(brandPink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(brandPink.opacity(0.1))
                    .cornerRadius(6)
                Text(name)
                    .font(.subheadline.bold())
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            Text(status)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.bottom, 8)
    }
}
