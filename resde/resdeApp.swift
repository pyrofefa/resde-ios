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

    @StateObject private var authService = AuthService(mockData: true)

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    HomeView()
                        .environmentObject(authService)
                } else {
                    LoginView()
                        .environmentObject(authService)
                }
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .onAppear {
                authService.loadTokenFromKeychain()
            }
            .onReceive(NotificationCenter.default.publisher(for: .tokenInvalido)) { _ in
                authService.logout()
            }
        }
    }
}
