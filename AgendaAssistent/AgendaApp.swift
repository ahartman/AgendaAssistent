//
//  AgendaApp.swift
//  AgendaAssistent
//
//  Created by André Hartman on 19/01/2021.
//  Copyright © 2021 André Hartman. All rights reserved.
//
import SwiftUI

@main
struct AgendaApp: App {
    @State private var model = MainModel()
    init() {
        model.startUpdate()
    }

    var body: some Scene {
        WindowGroup("Agenda Assistent") {
            ContentView()
                .environment(model)
                .navigationTitle("Agenda Assistent")
        }
        #if os(macOS)
            MenuBarExtra("Inspect", systemImage: "eyedropper") {
                VStack {
                    Button("Action One") {
                        // ...
                    }
                    Button("Action Two") {
                        // ...
                    }
                }
            }
        #endif
    }
}
