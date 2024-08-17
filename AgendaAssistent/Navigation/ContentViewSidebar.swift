//
//  ContentViewSidebar.swift
//  EventKit.Example
//
//  Created by André Hartman on 24/11/2020.
//  Copyright © 2020 André Hartman. All rights reserved.
//

import SwiftUI

struct ContentViewSidebar: View {
    @Environment(MainModel.self) private var model

    var body: some View {
        let titlePeriode = "Periode instellen"
        NavigationSplitView {
            List {
                NavigationLink(destination: SetDatesView(model: model, title: titlePeriode)) {
                    Text(titlePeriode)
                }
                Divider()
                NavigationLink(destination: DiaryView(title: "Agenda")) {
                    Text("Agenda")
                }
                NavigationLink(destination: AppointmentsView(title: "Consultaties tijdslijn")) {
                    Text("Tijdslijn consultaties")
                }
                NavigationLink(destination: PatientTimelineView(title: "Patiënten tijdslijn")) {
                    Text("Tijdslijn patiënten")
                }
                NavigationLink(destination: NoShowview(title: "Niet gekomen")) {
                    Text("Niet gekomen")
                }
                NavigationLink(destination: BalanceView(title: "In- en uitstroom")) {
                    Text("In- en uitstroom per week")
                }
                Divider()
                NavigationLink(destination: ChartlinesView(chartNumber: 3)) {
                    Text("Ouderdom consultaties")
                }
               NavigationLink(destination: ChartlinesView(chartNumber: 1)) {
                    Text("Ouderdom patiënten")
                }
               NavigationLink(destination: ChartlinesView(chartNumber: 2)) {
                    Text("Consultaties per patiënt")
                }
                Divider()
                NavigationLink(destination: PatientMapView(title: "Patiëntenkaart")) {
                    Text("Patiëntenkaart")
                }
                Divider()
                NavigationLink(destination: CommandsView(title: "Weekformulier")) {
                    Text("Opdrachten")
                }
            }
            .navigationBarTitle("Menu")
        } detail: {}
    }
}
