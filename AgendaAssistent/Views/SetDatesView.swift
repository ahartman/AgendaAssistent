//
//  CalendarDatesView.swift
//  EventKit.Example
//
//  Created by André Hartman on 05/11/2020.
//  Copyright © 2020 André Hartman. All rights reserved.
//

import SwiftUI

struct SetDatesView: View {
    @Bindable var model: MainModel
    var title: String
    let standaardPeriode = 6

    var body: some View {
        SliderHeaderView(model: model)
        Form {
            Section {
                HStack {
                    Text("Standaardinstelling")
                    Spacer()
                    Button("Deze week", action: {
                        model.period.periodStart = 0
                        model.period.periodLength = 1
                    })
                    Spacer()
                    ButtonView(model: model, label: "+1 Week", weeks: 1)
                    Spacer()
                }
            }
            Section(header: Text("Verleden perioden")) {
                HStack {
                    Spacer()
                    ButtonView(model: model, label: "-1 Jaar", weeks: -52)
                    Spacer()
                    ButtonView(model: model, label: "-1/2 jaar", weeks: -26)
                    Spacer()
                    ButtonView(model: model, label: "-3 maanden", weeks: -12)
                    Spacer()
                    ButtonView(model: model, label: "-4 weken", weeks: -4)
                    Spacer()
                }
            }
            Section(header: Text("Toekomstige perioden")) {
                HStack {
                    Spacer()
                    ButtonView(model: model, label: "+4 Weken", weeks: 4)
                    Spacer()
                    ButtonView(model: model, label: "+8 weken", weeks: 8)
                    Spacer()
                    ButtonView(model: model, label: "+12 weken", weeks: 12)
                    Spacer()
                    ButtonView(model: model, label: "+16 weken", weeks: 16)
                    Spacer()
                }
            }
        }
#if os(iOS)
        .navigationBarTitle(title, displayMode: .inline)
        .statusBar(hidden: true)
#endif
    }
}

struct ButtonView: View {
    @Bindable var model: MainModel
    let label: String
    let weeks: Int

    var body: some View {
        Button(label, action: {
            if weeks == 1 {
                model.period.periodStart += CGFloat(weeks)
                model.period.periodLength = CGFloat(weeks)
            } else if weeks > 0 {
                model.period.periodLength += CGFloat(weeks)
            } else {
                model.period.periodStart += CGFloat(weeks)
            }
        })
        .frame(minWidth: 0, maxWidth: 100)
        .buttonStyle(BorderlessButtonStyle())
    }
}
