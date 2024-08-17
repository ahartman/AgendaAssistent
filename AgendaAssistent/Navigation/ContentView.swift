//
//  ContentView.swift
//  EventKit.Example
//
//  Created by André Hartman on 24/11/2020.
//  Copyright © 2020 André Hartman. All rights reserved.
//
import SwiftUI

struct ContentView: View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    var body: some View {
        VStack {
            #if os(iOS)
            if horizontalSizeClass == .compact {
                ContentViewTabbar() // For iPhone
            }
            else {
                ContentViewSidebar() // For iPad
            }
            #else
            ContentViewSidebar() // For Mac
                .frame(minWidth: 2000, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)
            #endif
        }
    }
}
