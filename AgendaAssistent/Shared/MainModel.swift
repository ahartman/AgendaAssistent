//
//  MainModel.swift
//
//  Created by André Hartman on 31/07/2020.
//  Copyright © 2020 André Hartman. All rights reserved.
//
import EventKit

struct PeriodFloat: Codable {
    var periodStart: CGFloat = 0.0
    var periodLength: CGFloat = 0.0
    var periodEnds = [CGFloat]()
    var periodDates = PeriodStartEnd()

    struct PeriodStartEnd: Codable {
        var start = Date()
        var end = Date()
    }
}

@Observable class MainModel {
    var patientAllVisits = [PatientInfo]()
    var patientVisits = [PatientInfo]()
    var patientTimeline = [PatientTimelineInfo.PatientTimeline]()

    var chartsData = AveragesChart()
    var mapData = PatientMap()
    var inOutData = [FlowLine]()
    var diaryData = [DiaryLine]()
    var noShowData = [NoShowLine]()
    var period = Period()
    var eersteDisabled: Bool = true

    var period1 = PeriodFloat()

    let zeroDate = kalender.nextDate(
        after: Date(),
        matching: startMaandag,
        matchingPolicy: .nextTime,
        direction: .backward
    )!

    let eventStore = EKEventStore()

    init() {
        let localStart = -4.0
        let localLength = 8.0
        period.periodStart = localStart // in weken
        period.periodLength = localLength // in weken
        period.periodDates = Period.PeriodStartEnd(
            start: kalender.date(byAdding: DateComponents(day: Int(localStart) * 7 + 1), to: zeroDate)!,
            end: kalender.date(byAdding: DateComponents(day: Int(localLength) * 7), to: zeroDate)!
        )

        period1.periodStart = localStart // in weken
        period1.periodLength = localLength // in weken
        period1.periodDates = PeriodFloat.PeriodStartEnd(
            start: kalender.date(byAdding: DateComponents(day: Int(localStart) * 7 + 1), to: zeroDate)!,
            end: kalender.date(byAdding: DateComponents(day: Int(localLength) * 7), to: zeroDate)!
        )

        if defaults.object(forKey: "todayDaily") == nil {
            defaults.set(Date(), forKey: "todayDaily")
        }
        df.locale = Locale(identifier: "nl_BE")
    }

    func filterPatientData() -> [PatientInfo] {
        return patientAllVisits.filter {
            $0.visits.contains(where: { $0.visitCalendar != "Marieke speciallekes" })
        }
    }

    func startUpdate() {
        Task {
            let eventStore = EKEventStore()
            guard try await eventStore.requestFullAccessToEvents() else {
                print("calendar access probleem")
                return
            }
        }
        let counter = DBModel().makeDB()
        if counter == 0 { fullUpdate() }

        let (backLimit, forwardLimit) = DBModel().getVisitMinMax()
        let tempForward = kalender.dateComponents([.day], from: zeroDate, to: forwardLimit!).day! / 7
        period.periodEnds = [
            CGFloat(-1 * min(400 - tempForward, kalender.dateComponents([.day], from: backLimit!, to: zeroDate).day! / 7)),
            CGFloat(tempForward)
        ]
#if targetEnvironment(macCatalyst)
        dailyUpdate()
#endif
        loadAndUpdate()
    }

    func loadAndUpdate() {
        patientAllVisits = DBModel().getPatientAllInfo(dates: period.periodDates)
        patientVisits = DBModel().getPatientInfo(dates: period.periodDates)

        doChartLines()
        doInOutFlowLines()
        doDiary()
        doNoShowLines()
        doMapView()
        doPatientTimeline()
    }

    func dailyUpdate() {
        if !kalender.isDateInToday(defaults.object(forKey: "todayDaily") as! Date) {
            print("Daily update")
            let dailyDates = Period.PeriodStartEnd(
                start: kalender.date(byAdding: DateComponents(day: -1 * 7), to: zeroDate)!,
                end: kalender.date(byAdding: DateComponents(day: 6 * 7), to: zeroDate)!
            )
            let localEvents = EventModel().getCalendarEvents(dates: dailyDates, eventStore: eventStore)
            let localEventLines = doEventLines(events: localEvents)
            let localPatientLines = doPatientLines(eventLines: localEventLines)
            DBModel().updateDBWithPatients(patients: localPatientLines)
            defaults.set(Date(), forKey: "todayDaily")
            Task {
                async let a: Void = MainModel().doGeo()
                _ = await a
            }
        }
    }

    func doGeo() async {
        let contacts = ContactModel().getContacts()

        var patientsNoGeo = DBModel().getNoGeoPatients()
        print("noGeo patients to Contacts: ", patientsNoGeo.count)
        ContactModel().updatePatientsFromContacts(patientsNoGeo: patientsNoGeo, contacts: contacts)

        patientsNoGeo = DBModel().getNoGeoPatients()
        print("noGeo patients to Geocoder: ", patientsNoGeo.count)
        await ContactModel().updatePatientsContactsFromGeocoder(
            patientsNoGeo: patientsNoGeo,
            contacts: contacts
        )
        loadAndUpdate()
        print("End of doGeo")
    }

    func fullUpdate() {
        print("Full update start")
        DBModel().deleteAllPatients()

        var continueFlag = true
        var events = [EKEvent]()
        var foundEvents = [EKEvent]()

        var whileDate = kalender.date(byAdding: DateComponents(year: 1), to: Date())
        while continueFlag {
            let fourYears = Period.PeriodStartEnd(
                start: kalender.date(byAdding: DateComponents(month: -45), to: whileDate!)!,
                end: whileDate!
            )
            let tempEvents = EventModel().getCalendarEvents(dates: fourYears, eventStore: eventStore)
            foundEvents += tempEvents

            if tempEvents.count > 0 {
                whileDate = kalender.date(byAdding: DateComponents(day: 1), to: fourYears.start)
            } else {
                continueFlag = false
            }
        }

        events = Array(Set(foundEvents))

        for (index, _) in Array(events.enumerated()) {
            events[index].url = URL(string: "Not an URL", encodingInvalidCharacters: false)
        }

        let tempEventLines = doEventLines(events: events)
        let tempPatientLines = doPatientLines(eventLines: tempEventLines)
        DBModel().updateDBWithPatients(patients: tempPatientLines)

        doFirstVisit()

        print("Full update ready")
        Task {
            async let a: Void = MainModel().doGeo()
            _ = await a
        }
    }

    func doFirstVisit() {
        let (backLimit, forwardLimit) = DBModel().getVisitMinMax()
        var patientVisits = DBModel().getPatientInfo(dates: Period.PeriodStartEnd(start: backLimit!, end: forwardLimit!))

        for (index, patient) in patientVisits.enumerated() {
            let count = patient.visits.count - 1
            patientVisits[index].visits.removeLast(count)
            patientVisits[index].visits[0].visitFirst = true
        }
        DBModel().updateDBWithPatients(patients: patientVisits)
    }

    func doEventLines(events: [EKEvent]) -> [Event] {
        var localLines = [Event]()
        var localUpdates = [EKEvent]()
        for event in events {
            var eventLine = Event()

            eventLine.visitFirst = event.title.contains("#")
            eventLine.patientName = cleanPatientName(title: event.title)

            let location = event.location ?? ""
            eventLine.visitCanceled = location.localizedStandardContains("afgezegd")
            eventLine.visitNoShow = location.localizedStandardContains("niet gekomen")

            eventLine.id = event.eventIdentifier
            eventLine.visitCalendar = event.calendar.title
            eventLine.visitDate = event.startDate
            if event.hasRecurrenceRules || event.isDetached {
                if event.url == nil {
                    eventLine.id = event.hasRecurrenceRules ? UUID().uuidString : event.eventIdentifier
                    event.url = URL(string: eventLine.id)
                    localUpdates.append(event)
                }
                eventLine.visitRecurrent = true
                eventLine.visitCreated = kalender.date(
                    byAdding: DateComponents(day: -7), to: event.startDate
                )!
            } else {
                let item = eventStore.event(withIdentifier: event.eventIdentifier)
                eventLine.visitCreated = min(
                    kalender.startOfDay(for: (item?.creationDate)!),
                    eventLine.visitDate
                )
            }
            localLines.append(eventLine)
        }

        if !localUpdates.isEmpty { updateEvents(events: localUpdates) }
        if debugPrint { print("eventLines: \(localLines.count)") }
        return localLines.sorted(by: { $0.patientName < $1.patientName })
    }

    func updateEvents(events: [EKEvent]) {
        for event in events {
            try? eventStore.save(event, span: .thisEvent)
        }
        try? eventStore.commit()
    }

    func cleanPatientName(title: String) -> String {
        var temp = title
            .replacingOccurrences(of: "(mut)", with: "")
            .replacingOccurrences(of: "mut", with: "")
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "[\\s\n]+", with: " ", options: .regularExpression, range: nil)
            .trimmingCharacters(in: .whitespaces)
            .capitalized

        if let range = temp.range(of: " En") {
            temp = String(temp[..<range.lowerBound])
        }

        var titleComponents = temp.components(separatedBy: " ")
        let first = titleComponents.remove(at: 0)
        titleComponents.append(first)
        return titleComponents.joined(separator: " ")
    }

    func doPatientLines(eventLines: [Event]) -> [PatientInfo] {
        var localLines = [PatientInfo]()

        for event in eventLines {
            let start = event.visitCreated
            let created = kalender.nextDate(after: start, matching: startMaandag, matchingPolicy: .nextTime, direction: .backward)!
            let temp = kalender.nextDate(after: event.visitDate, matching: eindeZondag, matchingPolicy: .nextTime, direction: .forward)!
            let age = max(kalender.dateComponents([.weekOfYear], from: created, to: temp).weekOfYear!, 0)

            localLines.append(PatientInfo(
                patientName: event.patientName,
                visits: [PatientInfo.Visit(
                    id: event.id,
                    visitAge: age,
                    visitCalendar: event.visitCalendar,
                    visitCanceled: event.visitCanceled,
                    visitCreated: created,
                    visitDate: event.visitDate,
                    visitFirst: event.visitFirst,
                    visitNoShow: event.visitNoShow,
                    visitRecurrent: event.visitRecurrent,
                    visitPatientName: event.patientName,
                    patientId: 0
                )]
            ))
        }
        return localLines
    }

    // ============ Chartlines ==================
    func doChartLines(chartNr: Int = 0) {
        chartsData.chartNumber = chartNr > 0 ? chartNr : chartsData.chartNumber
        chartsData.agesVisits = ChartModel().getAgesVisits(dates: period.periodDates)
        chartsData.agesPatients = ChartModel().getAgesPatients(dates: period.periodDates)
        chartsData.numbersVisits = ChartModel().getNumbersVisits1(dates: period.periodDates)

        let togglesMirror = Mirror(reflecting: chartsData.chartToggles).children.dropLast()
        var selectedToggles = togglesMirror
            .filter { $0.value as! Bool == true && $0.label != "cumulatief" }
            .map { chartsData.chartToggles.cumulatief ? $0.label! + "Cum" : $0.label! }
        if selectedToggles.count == 0 {
            selectedToggles = ["alle"]
            chartsData.chartToggles.alle = true
        }

        switch chartsData.chartNumber {
        case 1:
            chartsData.chartData = chartsData.agesPatients
        case 2:
            chartsData.chartData = chartsData.numbersVisits
        case 3:
            chartsData.chartData = chartsData.agesVisits
        default: break
        }
        chartsData.chartData = chartsData.chartData
            .filter { selectedToggles.contains($0.type) }
    }

    // balanceView
    func doInOutFlowLines() {
        var localLines = [FlowLine]()
        let allEvents = patientAllVisits.flatMap { $0.visits }

        func doWeek(datum: Date) -> String {
            let components = kalender.dateComponents([.weekOfYear, .yearForWeekOfYear], from: datum)
            return String(format: "%02D", components.weekOfYear!) + String(components.yearForWeekOfYear!)
        }

        let visits = allEvents
            .filter { !$0.visitCalendar.contains("speciallekes") }
        let newVisits = allEvents
            .filter { $0.visitFirst && $0.visitCalendar == "Marieke nieuwe" }
        let proposedVisits = allEvents
            .filter { $0.visitFirst && $0.visitCalendar == "Marieke speciallekes" }
        let noShowVisits = patientAllVisits
            .flatMap { $0.visits }
            .filter { $0.visitCalendar == "Marieke speciallekes" && ($0.visitCanceled || $0.visitNoShow) }
        let endedVisits = patientAllVisits
            .map { $0.visits.last! }

        var datum = period.periodDates.start
        let currentWeek = doWeek(datum: Date())
        while datum < period.periodDates.end {
            let datumWeek = doWeek(datum: datum)
            let weekAllCount = visits.filter {
                datumWeek == doWeek(datum: $0.visitDate)
            }.count
            let weekNoShowCount = noShowVisits.filter {
                datumWeek == doWeek(datum: $0.visitDate)
            }.count
            let weekNewCount = newVisits.filter {
                datumWeek == doWeek(datum: $0.visitDate)
            }.count
            let weekProposalsCount = proposedVisits.filter {
                datumWeek == doWeek(datum: $0.visitDate)
            }.count
            let weekEndedCount = endedVisits.filter {
                datumWeek < currentWeek && datumWeek == doWeek(datum: $0.visitDate)
            }.count

            let saldo = weekNewCount - weekEndedCount + weekProposalsCount

            localLines.append(
                FlowLine(
                    startDate: datum,
                    weekNumber: kalender.component(.weekOfYear, from: datum),
                    consultaties: weekAllCount + weekNoShowCount,
                    nietGekomen: weekNoShowCount,
                    geenVervolg: weekEndedCount,
                    nieuwe: weekNewCount,
                    voorstellen: weekProposalsCount,
                    saldo: saldo
                )
            )
            datum = kalender.date(byAdding: DateComponents(day: 7), to: datum)!
        }

        inOutData = localLines
        if debugPrint { print("end doBalancesLines") }
    }

    // patientsTimeline
    func doPatientTimeline() {
        patientTimeline = DBModel().getPatientTimeline()
            .map {
                PatientTimelineInfo.PatientTimeline(
                    id: $0.patient.id!,
                    patientName: $0.patient.patientName,
                    startDate: $0.minVisitVisitCreated,
                    endDate: $0.maxVisitVisitDate
                )
            }
            .filter {
                let diff = kalender.dateComponents([.day], from: $0.startDate, to: $0.endDate).day!
                return diff < 5 ? false : true
            }
    }

    func sortPatientTimelines(type: String, direction: String) {
        switch type {
        case "alfa":
            if direction == "up" {
                patientTimeline = patientTimeline.sorted(by: { $0.patientName > $1.patientName })
            } else {
                patientTimeline = patientTimeline.sorted(by: { $0.patientName < $1.patientName })
            }
        case "datum":
            if direction == "up" {
                patientTimeline = patientTimeline.sorted(by: { $0.endDate > $1.endDate })
            } else {
                patientTimeline = patientTimeline.sorted(by: { $0.endDate < $1.endDate })
            }
        case "duur":
            patientTimeline = patientTimeline.sorted(by: {
                let delta1 = $0.startDate.distance(to: $0.endDate)
                let delta2 = $1.startDate.distance(to: $1.endDate)
                return direction == "up" ? delta1 > delta2 : delta1 < delta2
            })
        default:
            print("default sortPatientTimelines")
        }
    }

    // noShowview
    func doNoShowLines() {
        var localPatients = [NoShowLine]()

        for patient in patientAllVisits {
            let count = patient.visits.count
            let noShow = patient.visits
                .filter { $0.visitCalendar == "Marieke speciallekes" }
                .count
            let percentage = Double(noShow) / Double(count)
            if noShow > 0, noShow != count, percentage > 0.1 {
                localPatients.append(NoShowLine(
                    patientName: patient.patientName,
                    visitCount: count,
                    noShowCount: noShow,
                    percentage: percentage
                ))
            }
        }
        noShowData = localPatients.sorted(by: { $0.percentage > $1.percentage })
    }

    func sortNoShowLines(type: String, direction: String) {
        switch type {
        case "alfa":
            noShowData = noShowData.sorted(by: {
                direction == "up" ? $0.patientName < $1.patientName : $0.patientName > $1.patientName
            })
        case "consultaties":
            noShowData = noShowData.sorted(by: {
                direction == "up" ? $0.visitCount > $1.visitCount : $0.visitCount < $1.visitCount
            })
        case "percentage":
            noShowData = noShowData.sorted(by: {
                direction == "up" ? $0.percentage > $1.percentage : $0.percentage < $1.percentage
            })
        default:
            print("default sortAppointmentsChartLines")
        }
    }

    // other
    func sortPatientLines(type: String, direction: String) {
        switch type {
        case "alfa":
            if direction == "up" {
                patientVisits = patientVisits.sorted(by: { $0.patientName < $1.patientName })
            } else {
                patientVisits = patientVisits.sorted(by: { $0.patientName > $1.patientName })
            }
        case "datum":
            patientVisits = patientVisits.sorted(by: {
                let index1 = $0.visits.map { $0.visitDate }.max()!
                let index2 = $1.visits.map { $0.visitDate }.max()!
                return direction == "up" ? index1 < index2 : index1 > index2
            })
        case "aantal":
            patientVisits = patientVisits.sorted(by: {
                direction == "up" ? $0.visits.count < $1.visits.count : $0.visits.count > $1.visits.count
            })
        default:
            print("default sortAppointmentsChartLines")
        }
    }

    func doMapView() {
        let filteredLines = patientVisits.filter {
            if let _ = $0.patientLatitude {
                return true
            } else {
                return false
            }
        }
        .filter { $0.patientLatitude! > 0.0 }

        if filteredLines.count > 0 {
            mapData = MapModel().doMapView(filteredPatients: filteredLines, circles: mapData.circles)
        } else {
            print("No map data")
        }
    }

    func doDiary() {
        let weekdag: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "EEEE"
            df.locale = Locale(identifier: "nl_BE")
            return df
        }()

        let datum: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "dd-MM"
            df.locale = Locale(identifier: "nl_BE")
            return df
        }()

        let uur: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "HH:mm"
            df.locale = Locale(identifier: "nl_BE")
            return df
        }()

        var localPatients = [DiaryLine]()
        var tempVisits = [(String, Date)]()
        for p in patientVisits {
            for v in p.visits {
                tempVisits.append((p.patientName, v.visitDate))
            }
        }
        tempVisits.sort(by: { $0.1 < $1.1 })

        var previousDate = Date()
        for t in tempVisits {
            if !kalender.isDate(t.1, equalTo: previousDate, toGranularity: .day) {
                localPatients.append(
                    DiaryLine(
                        diaryDate: "\(weekdag.string(from: t.1)) (\(datum.string(from: t.1)))",
                        diaryName: ""
                    ))
                previousDate = t.1
            }
            localPatients.append(
                DiaryLine(
                    diaryDate: uur.string(from: t.1),
                    diaryName: t.0
                ))
        }
        diaryData = localPatients
    }

    func writeCSV() {
        var patients = [(naam: String, datum: Date)]()
        for line in patientVisits {
            patients.append((line.patientName, line.visits[0].visitDate))
        }
        patients = patients.sorted(by: { $0.datum < $1.datum })

        var previousWeekday = kalender.component(.weekday, from: period.periodDates.start)
        df.dateFormat = "dd/MM/yy HH:mm"

        var csvString = "\("Datum");\("Naam");\("Payconic");\("Bank/mobiel");\("Cash");\("Overschrijven")\n"
        for patient in patients {
            let weekday = kalender.component(.weekday, from: patient.datum)
            if weekday != previousWeekday {
                csvString = csvString.appending(";;;;;\n")
                previousWeekday = weekday
            }
            csvString = csvString.appending("\(String(describing: df.string(from: patient.datum)));\(patient.naam);;;\n")
        }
/*
        let fm = FileManager.default
        do {
            let path = try fm.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            let fileURL = path.appendingPathComponent("Weekformulier.csv")
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Probleem met Weekformulier")
        }
*/

        doWeekformulier(csvString: csvString)
    }

    func doWeekformulier(csvString: String) {
        var csvList = [[String]]()
        for temp in csvString.components(separatedBy: "\n") {
            csvList.append(temp.components(separatedBy: ";"))
        }
        csvList = csvList.dropLast()

        let weekFormulierScript =
            """
            tell application "Microsoft Excel"
            set theList to \(csvList)
                activate
                tell active workbook
                    tell active sheet
                        set theRange to range ("A1:F" & (count of theList))
                        set font size of font object of theRange to 14
                        set value of theRange to theList

                        set theRange to range ("C2:F" & (count of theList))
                        set myBorders to {border top, border bottom, border left, border right}
                        repeat with i from 1 to 4
                            set theBorder to get border theRange which border (item i of myBorders)
                            set weight of theBorder to border weight thin
                        end repeat

                        autofit column "A:E"
                    end tell

                    set naam to "/Users/gebruiker/Desktop/Weekformulier.xls"
                    tell application "System Events" to if (exists file naam) then delete file naam
                    save workbook as filename naam file format Excel98to2004 file format
                end tell
            end tell
            """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: weekFormulierScript) {
            if let outputString = scriptObject.executeAndReturnError(&error).stringValue {
                print("outputString: \(outputString)")
            } else if error != nil {
                print("error: ", error!)
            }
        }
    }
}
