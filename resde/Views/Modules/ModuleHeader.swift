//
//  ModuleHeader.swift
//  resde
//

import SwiftUI

enum ModuleDateFormat {
    case yearOnly
    case monthYear
}

struct ModuleHeader: View {
    @Environment(\.dismiss) var dismiss
    let title: String
    let showYear: Bool = true
    let dateFormat: ModuleDateFormat = .yearOnly
    @State private var selectedDate = Date()
    @State private var showDatePicker = false

    var dateDisplay: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")

        switch dateFormat {
        case .yearOnly:
            formatter.dateFormat = "yyyy"
        case .monthYear:
            formatter.dateFormat = "MMMM yyyy"
        }

        return formatter.string(from: selectedDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                if showYear {
                    Button(action: { showDatePicker.toggle() }) {
                        Text(dateDisplay)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(16)
            .background(Color(red: 0.05, green: 0.2, blue: 0.35))

            if showDatePicker {
                VStack(spacing: 12) {
                    DatePicker(
                        "Selecciona mes y año",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding(16)

                    Button(action: { showDatePicker = false }) {
                        Text("Listo")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .padding(16)
                }
                .background(Color.white)
            }
        }
    }
}

#Preview {
    ModuleHeader(title: "Pagos")
}
