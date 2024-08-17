//
//  NoShowView.swift
//  AgendaAssistent
//
//  Created by André Hartman on 11/02/2024.
//  Copyright © 2024 André Hartman. All rights reserved.
//

import SwiftUI

struct NoShowview: View {
    @Environment(MainModel.self) private var model
    var title: String

    var body: some View {
        SliderHeaderView(model: model)
        NoShowViewHeader(model: model)
        VStack {
            Table(of: NoShowLine.self) {
                TableColumn("Patiënt", value: \.patientName)
                TableColumn("Consultaties") { line in
                    Text(String(line.visitCount))
                }
                TableColumn("No Shows") { line in
                    Text(String(line.noShowCount))
                }
                TableColumn("Percentage") { line in
                    let temp = line.percentage
                        .formatted(.percent.precision(.fractionLength(0)))
                    Text(String(temp))
                }
            } rows: {
                ForEach(model.noShowData) { line in
                    TableRow(line)
                }
            }
        }
#if os(iOS)
        .navigationBarTitle(title, displayMode: .inline)
        .statusBar(hidden: true)
#endif
    }
}

struct NoShowViewHeader: View {
    @Bindable var model: MainModel
    @State var sortDirection = "up"
    @State var sortType = "alfa"

    var body: some View {
        HStack {
            Spacer()
            Button(action: { doButton(type: "alfa") }) {
                HStack {
                    if sortType == "alfa" {
                        Text(sortDirection == "up" ? "Alfabetisch ⇑" : "Alfabetisch ⇓")
                    } else {
                        Text("Alfabetisch  ")
                    }
                }
            }
            Spacer()
            Button(action: { doButton(type: "consultaties") }) {
                HStack {
                    if sortType == "consultaties" {
                        Text(sortDirection == "up" ? "Consultaties ⇑" : "Consultaties ⇓")
                    } else {
                        Text("Consultaties  ")
                    }
                }
            }
            Spacer()
            Button(action: { doButton(type: "percentage") }) {
                HStack {
                    if sortType == "percentage" {
                        Text(sortDirection == "up" ? "Percentage ⇑" : "Percentage ⇓")
                    } else {
                        Text("Percentage  ")
                    }
                }
            }
            Spacer()
        }
        .foregroundStyle(kleur)
    }

    func doButton(type: String) {
        if sortType != type {
            sortDirection = "up"
            sortType = type
        } else {
            sortDirection = (sortDirection == "up") ? "down" : "up"
        }
        model.sortNoShowLines(type: sortType, direction: sortDirection)
    }
}
