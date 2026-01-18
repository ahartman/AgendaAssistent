//
//  TablesView.swift
//  AgendaAssistent
//
//  Created by André Hartman on 11/01/2026.
//  Copyright © 2026 André Hartman. All rights reserved.
//

import SwiftUI

struct TablesView: View {
    @State var selected = 1
    var body: some View {
        VStack {
            Divider()
            HStack {
                Picker("What", selection: $selected) {
                    Text("Consultaties").tag(1)
                    Text("Patiënten").tag(2)
                    Text("Niet gekomen").tag(3)
                    Text("Agenda").tag(4)
                }
                .pickerStyle(.segmented)
                .glassEffect()
            }
            .padding([.top], 50)
            .padding([.leading, .trailing], 20)
            Divider()
            if selected == 1 {
                AppointmentsView(title: "Consultaties tijdslijn")
                    .padding(20)
            } else if selected == 2 {
                PatientTimelineView(title: "Patiënten tijdslijn")
                    .padding(20)
            } else if selected == 3 {
                NoShowView(title: "Niet gekomen")
                    .padding(20)
            } else if selected == 4 {
                DiaryView(title: "Agenda")
                    .padding(20)
            }
        }
    }
}
#Preview {
    TablesView()
}
