//
//  MyDemoApp.swift
//  MyDemo
//
//  Created by Funny Valentine. on 2025/08/04.
//

import SwiftUI

@main
struct MyDemoApp: App {
    let persistenceController = PersistenceController.shared
    var body: some Scene {
        LaunchScreen {
            Image(.appleLogo)
        } rootContent: {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }

    }
}
