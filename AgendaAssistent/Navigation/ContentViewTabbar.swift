//
//  ContentView.swift
//  EventKit.Example
//
//  Created by André Hartman on 31/07/2020.
//  Copyright © 2020 André Hartman. All rights reserved.
//
import SwiftUI

struct ContentViewTabbar: View {
    @Environment(MainModel.self) private var model

    var body: some View {
        TabView {
            let titlePeriode = "Periode instellen"
            SetDatesView(model: model, title: titlePeriode)
                .tabItem {
                    Image(systemName: "gearshape")
                    Text(titlePeriode)
                }
            let titleConsultaties = "Consultaties"
            AppointmentsView(title: titleConsultaties)
                .tabItem {
                    Image(systemName: "calendar.circle.fill")
                    Text(titleConsultaties)
                }
            let titleKaart = "Patiëntenkaart"
            PatientMapView(title: titleKaart)
                .tabItem {
                    Image(systemName: "mappin.and.ellipse")
                    Text("Kaart")
                }
        }
    }
}

struct ContentViewTabbar_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
