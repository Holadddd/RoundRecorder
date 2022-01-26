//
//  RoundRecorderApp.swift
//  RoundRecorder
//
//  Created by ting hui wu on 2021/10/21.
//

import SwiftUI

@main
struct RoundRecorderApp: App {
    let persistenceController = PersistenceController.shared

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            HomeMapView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
