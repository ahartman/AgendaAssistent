//
//  Model.swift
//
//  Created by André Hartman on 05/11/2020.
//  Copyright © 2020 André Hartman. All rights reserved.
//

import EventKit
import GRDB
import MapKit
import SwiftUI

let debugPrint: Bool = false
let thuis = CLLocationCoordinate2D(latitude: 51.35988, longitude: 4.48369)
let startMaandag = DateComponents(hour: 0, minute: 0, second: 0, weekday: 2)
let eindeZondag = DateComponents(hour: 0, minute: 0, second: 0, weekday: 1)
let kalender = Calendar(identifier: .iso8601)
let df = DateFormatter()
var defaults: UserDefaults {
    return UserDefaults.standard
}
let transparant = 0.4
let kleur = Color(.blue)
let tekstGrootte: CGFloat = 16

// Period
struct Period: Codable {
    var periodStart: Double = 0.0
    var periodLength: Double = 0.0
    var periodEnds = [Double]()
    var periodDates = PeriodStartEnd()

    struct PeriodStartEnd: Codable {
        var start = Date()
        var end = Date()
    }
}

// PatientsTimeline
struct PatientTimelineInfo: Decodable, FetchableRecord {
    var patient: PatientInfo.Patient
    var minVisitVisitCreated: Date
    var maxVisitVisitDate: Date

    struct PatientTimeline: Identifiable {
        var id: Int
        var patientName: String
        var startDate: Date
        var endDate: Date
    }
}

struct PatientInfo: Codable, Hashable, FetchableRecord {
    var id: Int?
    var patientName: String
    var patientLatitude: CLLocationDegrees?
    var patientLongitude: CLLocationDegrees?
    var visits: [PatientInfo.Visit]

    struct Patient: Codable, Hashable, FetchableRecord, MutablePersistableRecord {
        var id: Int?
        var patientName: String
        var patientLatitude: CLLocationDegrees?
        var patientLongitude: CLLocationDegrees?
        static let visits = hasMany(Visit.self)
    }
    struct Visit: Codable, Hashable, FetchableRecord, MutablePersistableRecord {
        var id: String
        var visitAge: Int
        var visitCalendar: String
        var visitCanceled: Bool
        var visitCreated: Date
        var visitDate: Date
        var visitFirst: Bool
        var visitNoShow: Bool
        var visitRecurrent: Bool
        var visitPatientName: String
        var patientId: Int
        static let patient = belongsTo(Patient.self)
    }
}

// Charts display
struct AveragesChart {
    var chartData = [AveragesChart.ChartLine]()
    var agesVisits = [AveragesChart.ChartLine]()
    var agesPatients = [AveragesChart.ChartLine]()
    var numbersVisits = [AveragesChart.ChartLine]()
    var chartToggles = ChartToggles()
    var chartNumber: Int = 0

    struct ChartLine: Identifiable, FetchableRecord, Decodable {
        var xAxis: Int
        var type: String
        var yValue: Double
        var barPercent: String?
        var barColor: String?
        let id = UUID()
    }

    struct ChartToggles: Equatable {
        var eerste: Bool = false
        var alle: Bool = true
        var cumulatief: Bool = false
    }
}

// PatientMap
struct PatientMap {
    var marker = [Marker]()
    var legend = [Legend]()
    var region = MKCoordinateRegion()
    let circles = [
        Circle(coordinate: thuis, radius: 5000.0, strokeColor: .blue),
        Circle(coordinate: thuis, radius: 10000.0, strokeColor: .green),
        Circle(coordinate: thuis, radius: 15000.0, strokeColor: .red),
        Circle(coordinate: thuis, radius: 300000.0, strokeColor: .black)
    ]

    struct Circle: Identifiable {
        var coordinate: CLLocationCoordinate2D
        var radius: CLLocationDistance
        var strokeColor: Color
        let id = UUID()
    }
    struct Marker: Identifiable {
        let id = UUID()
        var coordinate: CLLocationCoordinate2D
        var radius: Double
        var color: Color
        var monogram: String
    }
    struct Legend: Hashable {
        var roundedDistance: Double
        var distance: String
        var count: String
        var percentage: String
        var color: Color
    }
}

// end Map

struct NoShowLine: Identifiable {
    var patientName: String
    var visitCount: Int
    var noShowCount: Int
    var percentage: Double
    let id = UUID()
}

struct DiaryLine: Identifiable {
    var diaryDate: String
    var diaryName: String
    var id = UUID()
}

struct FlowLine: Identifiable {
    var startDate = Date()
    var weekNumber = 0
    var consultaties = 0
    var nietGekomen = 0
    var geenVervolg = 0
    var nieuwe = 0
    var voorstellen = 0
    var saldo = 0
    var id = UUID()
}

struct Event {
    var id = String()
    var patientName = String()
    var visitAge: Int = 0
    var visitCalendar = String()
    var visitCanceled: Bool = false
    var visitCreated = Date()
    var visitDate = Date()
    var visitFirst: Bool = false
    var visitLocation = String()
    var visitLatitude: Double?
    var visitLongitude: Double?
    var visitNoShow: Bool = false
    var visitRecurrent: Bool = false
}

// extensions
extension Formatter {
    static var percentage: NumberFormatter {
        let nf = NumberFormatter()
        nf.maximumFractionDigits = 0
        // nf.positivePrefix = nf.plusSign
        nf.numberStyle = .percent
        return nf
    }
}

extension FloatingPoint {
    func rounded(to value: Self, roundingRule: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> Self {
        (self / value).rounded(roundingRule) * value
    }
}
