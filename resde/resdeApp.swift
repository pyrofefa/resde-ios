//
//  resdeApp.swift
//  resde
//
//  Created by Siafeson on 25/08/26.
//

import SwiftUI
import CoreData

@main
struct resdeApp: App {
    let persistenceController = PersistenceController.shared

    @StateObject private var authService = AuthService(mockData: false)
    @Environment(\.scenePhase) private var scenePhase
    @State private var validacionPeriodicaTask: Task<Void, Never>?

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    HomeView()
                        .environmentObject(authService)
                        .transition(.opacity)
                } else {
                    LoginView()
                        .environmentObject(authService)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: authService.isAuthenticated)
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .onAppear {
                authService.loadTokenFromKeychain()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active && authService.isAuthenticated {
                    Task {
                        await authService.validarSesionActiva()
                    }
                    iniciarValidacionPeriodica()
                } else {
                    validacionPeriodicaTask?.cancel()
                    validacionPeriodicaTask = nil
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .tokenInvalido)) { notification in
                let mensaje = notification.userInfo?["mensaje"] as? String
                validacionPeriodicaTask?.cancel()
                validacionPeriodicaTask = nil
                authService.logout()
                if let mensaje = mensaje {
                    authService.errorMessage = mensaje
                }
            }
        }
    }

    /// Mientras la app esté activa, vuelve a validar la sesión cada minuto
    /// (además de al volver a primer plano), sin esperar a que el usuario
    /// minimice/reabra la app.
    private func iniciarValidacionPeriodica() {
        validacionPeriodicaTask?.cancel()
        validacionPeriodicaTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60 * 1_000_000_000)
                if Task.isCancelled { break }
                await authService.validarSesionActiva()
            }
        }
    }
}
