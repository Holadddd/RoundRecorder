//
//  UrbanRecorderApp.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/10/21.
//

import SwiftUI

@main
struct UrbanRecorderApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
