//
//  TimelineToolbarView.swift
//  AgendaAssistent
//
//  Created by André Hartman on 23/01/2026.
//  Copyright © 2026 André Hartman. All rights reserved.
//

import SwiftUI

struct PatientsViewToolbar: ToolbarContent {
    @Environment(MainModel.self) private var mainModel
    var whichView: String

    @State var buttonIcon: String = "arrow.up"
    @State var buttonType = [
        "direction": "up",
        "type": "alfa",
        "icon": "arrow.up",
    ]
    @State var buttonVisible = [
        "alfa": 1.0,
        "datum": 0.0,
        "aantal": 0.0,
    ]

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            makeButton(type: "alfa")
            makeButton(type: "datum")
            makeButton(type: "aantal")
        }
    }
    func makeButton(type: String) -> some View {
         return Button(
            action: { doButton(type: type) },
            label: {
                HStack {
                    Image(systemName: buttonType["icon"]!)
                        .opacity(buttonVisible[type]!)
                    Text("\(type)".capitalized)
                }
                .fixedSize()
            }
        )
    }

    func doButton(type: String) {
        buttonVisible["alfa"] = 0.0
        buttonVisible["datum"] = 0.0
        buttonVisible["aantal"] = 0.0
        buttonVisible[type] = 1.0

        if buttonType["type"] != type {
            buttonType["direction"] = "up"
            buttonType["type"] = type

        } else {
            buttonType["direction"] =
                buttonType["direction"] == "up" ? "down" : "up"
            buttonType["icon"] =
                buttonType["direction"] == "up" ? "arrow.up" : "arrow.down"
        }

        let _ = print(whichView)
        if whichView == "visits" {
            mainModel.sortPatientVisitsLines(
                type: buttonType["type"]!,
                direction: buttonType["direction"]!
            )
        } else {
            mainModel.sortPatientTimelines(
                type: buttonType["type"]!,
                direction: buttonType["direction"]!
            )
        }
    }
}
