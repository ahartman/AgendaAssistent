//
//  ContentView.swift
//  EventKit.Example
//
//  Created by André Hartman on 24/11/2020.
//  Copyright © 2020 André Hartman. All rights reserved.
//
import SwiftUI

struct ContentView: View {
    @Environment(MainModel.self) private var model

    var body: some View {
        TabView {
            TabSection("Overzichten") {
                Tab("Tijdslijn consultaties", systemImage: "") {
                    AppointmentsView(title: "Consultaties tijdslijn")
                }
                Tab("Tijdslijn patiënten", systemImage: "") {
                    PatientTimelineView(title: "Patiënten tijdslijn")
                }
                Tab("Niet gekomen", systemImage: "") {
                    NoShowView(title: "Niet gekomen")
                }
                Tab("Agenda", systemImage: "") {
                    DiaryView(title: "Agenda")
                }
            }
            TabSection("Grafieken") {
                Tab("Ouderdom consultaties", systemImage: "") {
                    ChartlinesView(chartNumber: 3)
                }
                Tab("Ouderdom patiënten", systemImage: "") {
                    ChartlinesView(chartNumber: 1)
                }
                Tab("Consultaties per patiënt", systemImage: "") {
                    ChartlinesView(chartNumber: 2)
                }
            }
            Tab("Periode instellen", systemImage: "calendar") {
                SetDatesView(model: model, title: "Periode instellen")
            }
            Tab("Kaart", systemImage: "map") {
                PatientMapView(title: "Kaart")
            }
            Tab("Opdrachten", systemImage: "text.and.command.macwindow") {
                CommandsView(title: "Opdrachten")
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewSidebarHeader {
            Text("Agenda Assistent")
        }
    }
}
