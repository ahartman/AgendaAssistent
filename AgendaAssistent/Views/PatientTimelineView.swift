//
//  PatientTimelineView1.swift
//  AgendaAssistent
//
//  Created by André Hartman on 28/02/2024.
//  Copyright © 2024 André Hartman. All rights reserved.
//
import Charts
import SwiftUI

struct PatientTimelineView: View {
    @Environment(MainModel.self) private var model
    var title: String

    let df: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy"
        return df
    }()

    var body: some View {
        PatientTimelineViewHeader1(model: model)
        Chart {
            ForEach(model.patientTimeline) { line in
                BarMark(
                    xStart: .value("Afspraak", line.startDate),
                    xEnd: .value("Consultatie", line.endDate),
                    y: .value("Naam", line.patientName)
                )
                .foregroundStyle(kleur)
            }
            RuleMark(x: .value("Nu", Date()))
                .foregroundStyle(.red)
        }
        .chartScrollableAxes(.vertical)
        .chartYVisibleDomain(length: 45)
        .chartXAxisLabel(alignment: .center) {
            Text("Jaren")
                .font(.system(size: tekstGrootte))
                .foregroundColor(kleur)
        }
        .chartYAxisLabel(position: .top) {
            Text("Aantal")
                .font(.system(size: tekstGrootte))
                .foregroundColor(kleur)
        }
        .chartXAxis {
            AxisMarks(position: .top, values: xWaarden()) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(
                    centered: true,
                    collisionResolution: .greedy
                ) {
                    if let temp = value.as(Date.self) {
                        Text("\(temp, formatter: df)")
                            .font(.system(size: 12))
                            .foregroundColor(kleur)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(preset: .extended, position: .leading, values: .automatic) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(centered: true) {
                    if let stringValue = value.as(String.self) {
                        Text("\(stringValue)")
                            .font(.system(size: tekstGrootte))
                            .foregroundColor(kleur)
                    }
                }
            }
        }
        .padding()
#if os(iOS)
            .navigationBarTitle(title, displayMode: .inline)
#endif
    }

    func xWaarden() -> [Date] {
        var localDates = [Date]()
        let startDatum = (model.patientTimeline.min(by: { $0.startDate < $1.startDate })?.startDate)!
        let eindDatum = (model.patientTimeline.max(by: { $0.endDate < $1.endDate })?.endDate)!

        let dateYear = kalender.component(.year, from: startDatum)
        var tempDate = DateComponents(calendar: kalender, year: dateYear).date

        while tempDate! < eindDatum {
            tempDate = kalender.date(byAdding: .month, value: 12, to: tempDate!)
            localDates.append(tempDate!)
        }
        return localDates
    }
}

struct PatientTimelineViewHeader1: View {
    @Bindable var model: MainModel
    @State var sortDirection = "down"
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
            Button(action: { doButton(type: "datum") }) {
                HStack {
                    if sortType == "datum" {
                        Text(sortDirection == "up" ? "Laatste consultatie ⇑" : "Laatste consultatie ⇓")
                    } else {
                        Text("Laatste consultatie  ")
                    }
                }
            }
            Spacer()
            Button(action: { doButton(type: "duur") }) {
                HStack {
                    if sortType == "duur" {
                        Text(sortDirection == "up" ? "Duur ⇑" : "Duur ⇓")
                    } else {
                        Text("Duur  ")
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
        model.sortPatientTimelines(type: sortType, direction: sortDirection)
    }
}
