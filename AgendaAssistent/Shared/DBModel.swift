//
//  DBModel2.swift
//  AgendaAssistent
//
//  Created by André Hartman on 11/11/2023.
//  Copyright © 2023 André Hartman. All rights reserved.
//
import EventKit
import GRDB

let db = DBModel().getDB()

class DBModel {
    public func getDB() -> DatabaseQueue {
        do {
            let fm = FileManager.default
            let path = try fm.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            let databaseURL = path.appendingPathComponent("db.sqlite")
            var dbQueue = try DatabaseQueue(path: databaseURL.path)
            print("db stored at \(databaseURL.path)")
            var config = Configuration()
/*
             config.prepareDatabase { db in
                 db.trace { print($0) }
             }
*/
            dbQueue = try DatabaseQueue(path: databaseURL.path, configuration: config)
            return dbQueue
        } catch {
            fatalError("Unresolved error \(error)")
        }
    }

    public func makeDB() -> Int {
        var counter = 0
        do {
            // try db.erase()
            try db.write { db in
                try db.create(table: "patient", ifNotExists: true) { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("patientName", .text)
                        .indexed()
                        .unique()
                        .notNull()
                    t.column("patientLatitude", .real)
                        .indexed()
                    t.column("patientLongitude", .real)
                }
            }
            try db.write { db in
                try db.create(table: "visit", ifNotExists: true) { t in
                    t.column("id", .text)
                        .primaryKey()
                        .indexed()
                    t.column("visitAge", .integer)
                        .indexed()
                    t.column("visitCalendar", .text)
                        .indexed()
                    t.column("visitCreated", .text)
                        .indexed()
                    t.column("visitCanceled", .boolean)
                        .indexed()
                    t.column("visitDate", .text)
                        .indexed()
                    t.column("visitFirst", .boolean)
                        .indexed()
                    t.column("visitNoShow", .boolean)
                        .indexed()
                    t.column("visitRecurrent", .boolean)
                        .indexed()
                    t.column("visitPatientName", .text)
                    t.uniqueKey(["patientID", "visitDate"])
                    t.belongsTo("patient", onDelete: .cascade)
                }
            }
            try db.read { db in
                counter = try PatientInfo.Patient.fetchCount(db)
            }
        } catch {
            fatalError("Unresolved error \(error)")
        }
        return counter
    }

    func updateDBWithPatients(patients: [PatientInfo]) {
        do {
            try db.inTransaction { db in
                for patient in patients {
                    var tempPatient = PatientInfo.Patient(
                        patientName: patient.patientName
                    )
                    tempPatient = try tempPatient.upsertAndFetch(
                        db, onConflict: ["patientName"],
                        doUpdate: { _ in
                            [
                                Column("patientLatitude").noOverwrite,
                                Column("patientLongitude").noOverwrite
                            ]
                        }
                    )
                    for visit in patient.visits {
                        var tempVisit = visit
                        tempVisit.patientId = tempPatient.id!
                        try tempVisit.upsert(db)
                    }
                }
                return .commit
            }
        } catch {
            fatalError("Unresolved error \(error)")
        }
    }

    func updateDBWithGeo(patients: [PatientInfo.Patient]) {
        do {
            try db.inTransaction { db in
                for p in patients {
                    if p.patientLatitude == 0.0 {
                        print("Faulty geo (0)")
                    } else {
                        var patient = p
                        try patient.upsert(db)
                    }
                }
                return .commit
            }
        } catch {
            fatalError("Unresolved error \(error)")
        }
    }

    func deleteAllPatients() {
        do {
            try db.write { db in
                try PatientInfo.Patient.deleteAll(db)
            }
        } catch {
            fatalError("Unresolved error \(error)")
        }
    }

    func getPatientAllInfo(dates: Period.PeriodStartEnd) -> [PatientInfo] {
        var patientInfo = [PatientInfo]()
        do {
            patientInfo = try db.read { db in
                let filteredVisits = PatientInfo.Patient.visits
                    .filter(Column("visitDate") >= dates.start)
                    .filter(Column("visitDate") <= dates.end)
                    .order(Column("visitDate"))
                return try PatientInfo.Patient
                    .including(all: filteredVisits)
                    .having(filteredVisits.isEmpty == false)
                    .asRequest(of: PatientInfo.self)
                    .fetchAll(db)
            }
        } catch {
            fatalError("Unresolved error \(error)")
        }
        return patientInfo
    }

    func getPatientInfo(dates: Period.PeriodStartEnd) -> [PatientInfo] {
        var patientInfo = [PatientInfo]()
        do {
            patientInfo = try db.read { db in
                let filteredVisits = PatientInfo.Patient.visits
                    .filter(Column("visitDate") >= dates.start)
                    .filter(Column("visitDate") <= dates.end)
                    .filter(["Marieke", "Marieke nieuwe"].contains(Column("visitCalendar")))
                    .order(Column("visitDate"))
                return try PatientInfo.Patient
                    .including(all: filteredVisits)
                    .having(filteredVisits.isEmpty == false)
                    .asRequest(of: PatientInfo.self)
                    .fetchAll(db)
            }
        } catch {
            fatalError("Unresolved error \(error)")
        }
        return patientInfo
    }

    func getVisitMinMax() -> (Date?, Date?) {
        var result: Row?
        do {
            try db.read { db in
                let request = PatientInfo.Visit
                    .select(
                        min(Column("visitDate")).forKey("visitDateMin"),
                        max(Column("visitDate")).forKey("visitDateMax")
                    )
                    .filter(Column("visitRecurrent") == false)
                result = try Row.fetchOne(db, request)!
            }
        } catch {
            fatalError("Unresolved error \(error)")
        }
        return (result?["visitDateMin"], result?["visitDateMax"])
    }

    func getPatientTimeline() -> [PatientTimelineInfo] {
        var patientTimeline = [PatientTimelineInfo]()
        do {
            patientTimeline = try db.read { db in
                let filteredVisits = PatientInfo.Patient.visits
                    .filter(["Marieke", "Marieke nieuwe"].contains(Column("visitCalendar")))
                let request = PatientInfo.Patient
                    .select(
                        Column("id"),
                        Column("patientName")
                    )
                    .order(Column("patientName"))
                    .having(filteredVisits.isEmpty == false)
                    .annotated(with:
                        filteredVisits.min(Column("visitCreated")),
                        filteredVisits.max(Column("visitDate")))
                return try PatientTimelineInfo.fetchAll(db, request)
            }
        } catch {
            fatalError("Unresolved error \(error)")
        }
        return patientTimeline
    }

    func getNoGeoPatients() -> [PatientInfo.Patient] {
        var patients = [PatientInfo.Patient]()
        do {
            try db.read { db in
                patients = try PatientInfo.Patient
                    .filter(Column("patientLatitude") == nil)
                    .fetchAll(db)
            }
        } catch {
            fatalError("getNoGeoPatients: \(error)")
        }
        return patients
    }
}
