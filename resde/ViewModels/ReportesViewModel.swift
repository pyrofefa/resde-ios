import SwiftUI
import Combine

enum ConceptoReporte {
    case ingresos
    case egresos
}

@MainActor
class ReportesViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var resumenFinanciero: BalanceMensualData?
    @Published var isLoading = true
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var conceptoSeleccionado: ConceptoReporte = .ingresos

    private let authService = AuthService(mockData: false)

    init() {
        authService.loadTokenFromKeychain()
    }

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM/yyyy"
        return formatter.string(from: selectedDate).uppercased()
    }

    func loadReportes() async {
        isLoading = true
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fechaParam = dateFormatter.string(from: selectedDate)

        if let data = await fetchBalanceMensual(fecha: fechaParam) {
            do {
                let response = try JSONDecoder().decode(BalanceMensualResponse.self, from: data)
                await MainActor.run {
                    self.resumenFinanciero = response.data
                    self.isLoading = false
                }
            } catch {
                print("❌ Error decodificando balance: \(error)")
                await MainActor.run {
                    self.errorMessage = "Error al cargar el reporte"
                    self.showError = true
                    self.isLoading = false
                }
            }
        } else {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    private func fetchBalanceMensual(fecha: String) async -> Data? {
        guard let url = URL(string: "https://resde.aseenti.com.mx/api/v1/reportes/balance-mensual?fecha=\(fecha)") else {
            return nil
        }

        var request = URLRequest(url: url)
        if let token = authService.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 403 {
                    return nil
                }
            }
            return data
        } catch {
            print("❌ Error fetching balance: \(error)")
            return nil
        }
    }
}

struct BalanceMensualData: Codable {
    let total_ingresos_mes: String
    let total_egresos_mes: String
    let balance_neto: String
    let saldo_inicial_mes: String?
    let saldo_final: String?
}

struct BalanceMensualResponse: Codable {
    let success: Bool?
    let data: BalanceMensualData?
    let message: String?
}
