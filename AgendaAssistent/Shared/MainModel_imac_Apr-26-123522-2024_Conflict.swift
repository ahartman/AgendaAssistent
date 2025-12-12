//
//  MainModel.swift
//
//  Created by André Hartman on 31/07/2020.
//  Copyright © 2020 André Hartman. All rights reserved.
//
import EventKit
import Observation

@Observable class MainModel {
    var patientAllVisits = [PatientInfo]() {
        didSet {
            patientVisits = filterPatientData()
        }
    }

    var patientVisits = [PatientInfo]()
    var patientTimeline = [PatientTimeline]()

    var mapData = PatientMap()
    var inOutData = [FlowLine]()
    var inOutData1 = [FlowLine]()
    var diaryData = [DiaryLine]()
    var noShowData = [NoShowLine]()

    var numbersData = AveragesChart()
    var chartToggles = AveragesChart.ChartToggles() {
        didSet { filterChartLines() }
    }

    let startDateTemp = kalender.nextDate(
        after: Date(),
        matching: startMaandag,
        matchingPolicy: .nextTime,
        direction: .backward
    )!

    var sliderThumbs = [CGFloat]()
    var sliderEnds = [Int]()

    var periodDates: PeriodStartEnd {
        didSet { loadAndUpdate() }
    }

    var eersteDisabled: Bool = true

    init() {
        periodDates = PeriodStartEnd(
            start: kalender.date(byAdding: DateComponents(day: -4 * 7 + 1), to: startDateTemp)!,
            end: kalender.date(byAdding: DateComponents(day: 4 * 7), to: startDateTemp)!
        )
        sliderThumbs = [-4, 4] // in weken

        if defaults.object(forKey: "todayDaily") == nil {
            defaults.set(Date(), forKey: "todayDaily")
        }

        kalender.locale = NSLocale(localeIdentifier: "nl_BE") as Locale
        df.locale = Locale(identifier: "nl_BE")
    }

    func filterPatientData() -> [PatientInfo] {
        return patientAllVisits.filter {
            $0.visits.contains(where: { !$0.visitCalendar.contains("speciallekes") })
        }
    }

    func loadAndUpdate() {
        Task {
            guard try await eventStore.requestFullAccessToEvents() else {
                print("calendar access probleem")
                return
            }
        }
        let counter = DBModel().makeDB()
        if counter == 0 { fullUpdate() }

        let (backLimit, forwardLimit) = DBModel().getVisitMinMax()
        let tempForward = kalender.dateComponents([.day], from: startDateTemp, to: forwardLimit!).day! / 7
        sliderEnds = [
            -1 * min(400 - tempForward, kalender.dateComponents([.day], from: backLimit!, to: startDateTemp).day! / 7),
            tempForward
        ]

        dailyUpdate()
        loadAndUpdate1(dates: periodDates)
    }

    // @MainActor
    func loadAndUpdate1(dates: PeriodStartEnd) {
        patientAllVisits = DBModel().getPatientInfo(dates: periodDates)
        doKeyedAgesPatientsChartLines()
        doKeyedAgesVisitsChartLines()
        doKeyedNumbersVisitsChartLines()
        filterChartLines()

        doInOutFlowLines()
        doDiary()
        doNoShowLines()
        doMapView()
        doPatientTimeline()
    }

    func dailyUpdate() {
        if !kalender.isDateInToday(defaults.object(forKey: "todayDaily") as! Date) {
            print("Daily update")
            let dailyDates = PeriodStartEnd(
                start: kalender.date(byAdding: DateComponents(day: -1 * 7), to: startDateTemp)!,
                end: kalender.date(byAdding: DateComponents(day: 6 * 7), to: startDateTemp)!
            )
            let localEvents = EventModel().getCalendarEvents(dates: dailyDates)
            let localEventLines = doEventLines(events: localEvents)
            let localPatientLines = doPatientLines(eventLines: localEventLines)
            DBModel().updateDBFromPatients(patients: localPatientLines, dates: periodDates)
            defaults.set(Date(), forKey: "todayDaily")
            Task {
                async let a: Void = doGeo()
                _ = await a
            }
        }
        @Sendable func doGeo() async {
            let patients = DBModel().getNoGeoPatients()
            let contacts = ContactModel().getContacts()
            let foundPatients = await ContactModel()
                .updatePatientsFromGeocoder(
                    patientsNotFound: patients,
                    contacts: contacts
                )
            DBModel().updateDBFromGeo(patients: foundPatients)
        }
    }

    func fullUpdate() {
        print("Full update start")
        DBModel().deleteAllPatients()

        df.dateFormat = "dd/MM/yyy"
        let tempStart = df.date(from: "01/01/2017")!

        var fourYears = PeriodStartEnd(
            start: tempStart,
            end: kalender.date(byAdding: DateComponents(year: 4), to: tempStart)!
        )
        var events: [EKEvent] = EventModel().getCalendarEvents(dates: fourYears)

        fourYears = PeriodStartEnd(
            start: kalender.date(byAdding: DateComponents(year: 4), to: tempStart)!,
            end: kalender.date(byAdding: DateComponents(year: 8), to: tempStart)!
        )
        events += EventModel().getCalendarEvents(dates: fourYears)
        for (index, _) in Array(events.enumerated()) {
            events[index].url = URL(string: "Not an URL", encodingInvalidCharacters: false)
        }

        let tempEventLines = doEventLines(events: events)
            .filter { $0.visitCreated <= $0.visitDate }
        let tempPatientLines = doPatientLines(eventLines: tempEventLines)

        DBModel().updateDBFromPatients(patients: tempPatientLines, dates: periodDates)
        ContactModel().findGeoForPatients(patients: tempPatientLines)
        print("Full update ready")
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
                eventLine.visitCreated = kalender.startOfDay(for: (item?.creationDate)!)
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
    func filterChartLines() {
        let togglesMirror = Mirror(reflecting: chartToggles).children.dropLast()
        var selectedToggles = togglesMirror
            .filter { $0.value as! Bool == true && $0.label != "cumulatief" }
            .map { chartToggles.cumulatief ? $0.label! + "Cum" : $0.label! }
        if selectedToggles.count == 0 {
            selectedToggles = ["alle"]
            chartToggles.alle = true
        }
        numbersData.agesVisits = numbersData.keyedAgesVisits
            .filter { selectedToggles.contains($0.key) }
            .flatMap { $0.value }

        numbersData.numbersVisits = numbersData.keyedNumbersVisits
            .filter { selectedToggles.contains($0.key) }
            .flatMap { $0.value }

        numbersData.agesPatients = numbersData.keyedAgesPatients
            .filter { selectedToggles.contains($0.key) }
            .flatMap { $0.value }
    }

    func doKeyedAgesPatientsChartLines() {
        var localChartLines = [String: [AveragesChart.ChartLine]]()

        localChartLines = doAgesPatientsChartLines(eerste: false)
        for (key, element) in localChartLines {
            numbersData.keyedAgesVisits[key] = element
        }

        localChartLines = doAgesPatientsChartLines(eerste: true)
        for (key, element) in localChartLines {
            numbersData.keyedAgesVisits[key] = element
        }
        eersteDisabled = numbersData.keyedAgesVisits["eerste"]!.count == 0

        func doAgesPatientsChartLines(eerste: Bool) -> [String: [AveragesChart.ChartLine]] {
            var localCounts = [Double]()

            var filteredChartLines = patientVisits
                .flatMap { $0.visits }
            if eerste {
                filteredChartLines = filteredChartLines.filter { $0.visitFirst == true }
            }
            let maxOuderdom = filteredChartLines
                .map { $0.visitAge }
                .max() ?? 0

            for ouderdom in stride(from: 0, through: maxOuderdom, by: 1) {
                localCounts.append(Double(filteredChartLines
                        .filter { $0.visitAge == ouderdom }
                        .count
                ))
            }

            let countsTotal = localCounts.reduce(0,+)
            localCounts = localCounts.map { $0 / countsTotal < 0.01 ? 0.0 : $0 }
            let localLastIndex = localCounts.lastIndex(where: { $0 > 0.0 }) ?? 0 + 1
            localCounts.removeSubrange(localLastIndex...)

            let key = eerste ? "eerste" : "alle"
            let label = "\(key.capitalized) consultaties"
            localChartLines[key] = localCounts.enumerated().map { index, waarde in
                AveragesChart.ChartLine(xAs: index, naam: label, waarde: waarde, procent: "", kleur: kleur)
            }

            let localWaarden = localCounts.reduce(into: [Double]()) { $0.append(($0.last ?? 0) + $1) }
            let localCumulatief = localWaarden.map { $0 / (localWaarden.last!) }

            let keyCum = key + "Cum"
            localChartLines[keyCum] = localCumulatief.enumerated().map { index, waarde in
                AveragesChart.ChartLine(xAs: index, naam: label, waarde: waarde, procent: "", kleur: kleur)
            }
            return localChartLines
        }
    }

    // agesView
    func doKeyedAgesVisitsChartLines() {
        let parameter = patientVisits
            .map {
                let min = $0.visits.min(by: { $0.visitCreated < $1.visitCreated })!.visitCreated
                let max = $0.visits.max(by: { $0.visitDate < $1.visitDate })!.visitDate
                return kalender.dateComponents([.month], from: min, to: max).month!
            }
        numbersData.keyedAgesPatients = doKeyedChartLines(parameter: parameter)
    }

    // numbersView
    func doKeyedNumbersVisitsChartLines() {
        let parameter = patientVisits
            .map { $0.visits.count }
        numbersData.keyedNumbersVisits = doKeyedChartLines(parameter: parameter, minParameter: 1)
    }

    func doKeyedChartLines(parameter: [Int], minParameter: Int = 0) -> [String: [AveragesChart.ChartLine]] {
        var localChartlines = [String: [AveragesChart.ChartLine]]()
        var localCounts = [(key: Int, value: Double)]()

        let maxParameter = parameter
            .max() ?? 0
        let countedSet = NSCountedSet(array: parameter)
        for element in stride(from: minParameter, through: maxParameter, by: 1) {
            localCounts.append((key: element, value: Double(countedSet.count(for: element))))
        }
        let som = localCounts.compactMap { $0.1 }.reduce(0, +)
        var total = 0.0
        let localCumulatief = localCounts.map {
            total += $0.1
            return (key: $0.0, value: total / som)
        }

        localChartlines["alle"] = localCounts.map {
            AveragesChart.ChartLine(xAs: $0.key, naam: "Maanden", waarde: $0.value, procent: "", kleur: kleur)
        }
        localChartlines["alleCum"] = localCumulatief.map {
            AveragesChart.ChartLine(xAs: $0.key, naam: "Maanden", waarde: $0.value, procent: "", kleur: kleur)
        }
        if let lines = localChartlines["alleCum"] {
            if lines.count > 10 {
                for percent in yAxisCumulatief {
                    let closest = lines
                        .enumerated()
                        .min(
                            by: { abs($0.element.waarde - percent) < abs($1.element.waarde - percent) }
                        )!
                    localChartlines["alleCum"]![closest.offset].kleur = lichteKleur
                    localChartlines["alleCum"]![closest.offset].procent = percent.formatted(.percent.precision(.fractionLength(0)))
                }
            }
        }
        return localChartlines
    }

    // balanceView
    func doInOutFlowLines() {
        var localLines = [FlowLine]()
        let allEvents = patientAllVisits.flatMap { $0.visits }

        func doWeek(datum: Date) -> String {
            let components = kalender.dateComponents([.weekOfYear, .yearForWeekOfYear], from: datum)
            return "\(components.weekOfYear!)\(components.yearForWeekOfYear!)"
        }

        let visits = allEvents
            .filter { !$0.visitCalendar.contains("speciallekes") }
        let firstVisits = allEvents
            .filter { $0.visitFirst }

        let newVisits = firstVisits
            .filter { $0.visitCalendar == "Marieke nieuwe" }
        let proposedVisits = firstVisits
            .filter { $0.visitCalendar == "Marieke speciallekes" }
        let noShowVisits = patientAllVisits
            .flatMap { $0.visits }
            .filter { $0.visitCalendar == "Marieke speciallekes" && ($0.visitCanceled || $0.visitNoShow) }
        let endedVisits = patientAllVisits
            .map { $0.visits.last! }

        var cumulatief = 0
        var datum = periodDates.start
        let currentWeek = doWeek(datum: Date())
        while datum < periodDates.end {
            let datumWeek = doWeek(datum: datum)
            // print(datumWeek)
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
                let labelWeek = doWeek(datum: $0.visitDate)
                return datumWeek <= currentWeek ? false : datumWeek == labelWeek
            }.count
            let weekEndedCount = endedVisits.filter {
                let labelWeek = doWeek(datum: $0.visitDate)
                if labelWeek == "92024" { print("#",$0.visitDate, $0.visitPatientName) }
                return datumWeek >= currentWeek ? false : datumWeek == labelWeek
            }.count

            let saldo = weekNewCount - weekEndedCount + weekProposalsCount
            cumulatief += saldo

            localLines.append(
                FlowLine(
                    startDate: datum,
                    weekNumber: kalender.component(.weekOfYear, from: datum),
                    consultaties: weekAllCount + weekNoShowCount,
                    nietGekomen: weekNoShowCount,
                    geenVervolg: weekEndedCount,
                    nieuwe: weekNewCount,
                    voorstellen: weekProposalsCount,
                    saldo: saldo,
                    cumulatief: cumulatief
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
            .map({
                PatientTimeline(
                    id: $0.patient.id!,
                    patientName: $0.patient.patientName,
                    startDate: $0.minVisitVisitCreated,
                    endDate: $0.maxVisitVisitDate
                ) }
            )
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

        var previousWeekday = kalender.component(.weekday, from: periodDates.start)
        df.dateFormat = "dd/MM/yy HH:mm"

        var csvString = "\("Datum");\("Naam");\("Elektronisch");\("Cash");\("Overschrijven")\n"
        for patient in patients {
            let weekday = kalender.component(.weekday, from: patient.datum)
            if weekday != previousWeekday {
                csvString = csvString.appending("\(" ")\n")
                previousWeekday = weekday
            }
            csvString = csvString.appending("\(String(describing: df.string(from: patient.datum)));\(String(describing: patient.naam))\n")
        }

        let fm = FileManager.default
        do {
            let path = try fm.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            let fileURL = path.appendingPathComponent("Weekformulier.csv")
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Probleem met Weekformulier")
        }
    }
}
