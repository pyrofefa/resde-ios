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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
