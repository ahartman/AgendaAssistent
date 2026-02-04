//
//  PatientTimelineView.swift
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
        VStack {
            SliderHeaderView(model: model)
            NavigationStack {
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
                    AxisMarks(
                        preset: .extended,
                        position: .leading,
                        values: .automatic
                    ) { value in
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
                .toolbar(.hidden, for: .navigationBar)
                .toolbar {
                    PatientsViewToolbar(whichView: "patients")
                }
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    func xWaarden() -> [Date] {
        var localDates = [Date]()
        let startDatum =
            (model.patientTimeline.min(by: { $0.startDate < $1.startDate })?
            .startDate)!
        let eindDatum =
            (model.patientTimeline.max(by: { $0.endDate < $1.endDate })?.endDate)!

        let dateYear = kalender.component(.year, from: startDatum)
        var tempDate = DateComponents(calendar: kalender, year: dateYear).date

        while tempDate! < eindDatum {
            tempDate = kalender.date(byAdding: .month, value: 12, to: tempDate!)
            localDates.append(tempDate!)
        }
        return localDates
    }
}
