//
//  Appointments2ChartView.swift
//  AgendaAssistent
//
//  Created by André Hartman on 12/03/2023.
//  Copyright © 2023 André Hartman. All rights reserved.
//

import Charts
import SwiftUI

struct PatientVisitsView: View {
    @Environment(MainModel.self) private var mainModel
    var title: String

    var body: some View {
            VStack {
                let (xWeekNummers, xAantallen) = xWaarden()
                SliderHeaderView(model: mainModel)
                NavigationStack {
                let localVisits = extraVisits(patients: mainModel.patientVisits)
                Chart {
                    ForEach(localVisits, id: \.id) { patient in
                        ForEach(patient.visits, id: \.id) { visit in
                            BarMark(
                                xStart: .value("Afspraak", visit.visitCreated),
                                xEnd: .value("Consultatie", visit.visitDate),
                                y: .value("Naam", doNaam(localPatient: patient))
                            )
                            .foregroundStyle(
                                visit.visitAge == 1
                                ? kleur : kleur.opacity(transparant)
                            )
                        }
                    }
                    RuleMark(x: .value("Nu", Date()))
                        .foregroundStyle(.red)
                }
                .chartScrollableAxes(.vertical)
                .chartYVisibleDomain(length: 25)
                .chartXAxisLabel(alignment: .center) {
                    Text("Weken")
                        .font(.system(size: tekstGrootte))
                        .foregroundColor(kleur)
                }
                .chartYAxisLabel(position: .top) {
                    Text("Aantal")
                        .font(.system(size: tekstGrootte))
                        .foregroundColor(kleur)
                }
                .chartXAxis {
                    AxisMarks(position: .top, values: xWeekNummers) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(
                            centered: true,
                            collisionResolution: .greedy
                        ) {
                            if let temp = value.as(Date.self) {
                                let counter =
                                xAantallen[value.index] == 0
                                ? "" : String(xAantallen[value.index])
                                Text(
                                    "\(temp.formatted(.dateTime.week()))\n\(counter)"
                                )
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
                .padding([.leading, .trailing], 40)
                .toolbar(.hidden, for: .navigationBar)
                .toolbar {
                    PatientsViewToolbar(whichView: "visits")
                }
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    func extraVisits(patients: [PatientInfo]) -> [PatientInfo] {
        var localPatients = [PatientInfo]()
        for patient in patients {
            var localVisits = patient.visits
            for visit in patient.visits {
                localVisits.append(
                    PatientInfo.Visit(
                        id: visit.id,
                        visitAge: 1,
                        visitCalendar: visit.visitCalendar,
                        visitCanceled: visit.visitCanceled,
                        visitCreated: kalender.date(
                            byAdding: DateComponents(day: -7),
                            to: visit.visitDate
                        )!,
                        visitDate: visit.visitDate,
                        visitFirst: visit.visitFirst,
                        visitNoShow: visit.visitNoShow,
                        visitRecurrent: visit.visitRecurrent,
                        visitPatientName: patient.patientName,
                        patientId: patient.id!
                    )
                )
            }
            let localPatient = PatientInfo(
                id: patient.id,
                patientName: patient.patientName,
                visits: localVisits
            )
            localPatients.append(localPatient)
        }
        return localPatients
    }

    func doNaam(localPatient: PatientInfo) -> String {
        let aantal = (localPatient.visits.count) / 2
        let aantalNaam = aantal > 1 ? String("(\(aantal))") : ""
        return "\(localPatient.patientName) \(aantalNaam)"
    }

    func xWaarden() -> ([Date], [Int]) {
        var localDates = [Date]()
        var localCounters = [Int]()
        let consultaties = mainModel.patientAllVisits.flatMap { $0.visits }
        let startDatum =
            (consultaties.min(by: { $0.visitCreated < $1.visitCreated })?
            .visitCreated)!
        let eindDatum =
            (consultaties.max(by: { $0.visitDate < $1.visitDate })?.visitDate)!
        let eindDatumPlus = kalender.nextDate(
            after: eindDatum,
            matching: startMaandag,
            matchingPolicy: .nextTime,
            direction: .forward
        )!
        kalender.enumerateDates(
            startingAfter: startDatum,
            matching: startMaandag,
            matchingPolicy: .nextTime
        ) { datum, _, stop in
            guard let datum = datum, datum < eindDatumPlus else {
                stop = true
                return
            }
            localDates.append(datum)
        }

        for localDate in localDates {
            let localDateWeek = kalender.component(.weekOfYear, from: localDate)
            let localCounter = consultaties.filter {
                kalender.component(.weekOfYear, from: $0.visitCreated)
                    == localDateWeek && $0.visitAge == 1
            }.count
            localCounters.append(localCounter)
        }
        return (localDates, localCounters)
    }
}

#Preview {
    PatientVisitsView(title: "")
}
