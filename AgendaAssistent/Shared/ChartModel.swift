//
//  ChartModel.swift
//  AgendaAssistent
//
//  Created by André Hartman on 06/06/2024.
//  Copyright © 2024 André Hartman. All rights reserved.
//

import GRDB

class ChartModel {
    func getAgesVisits(dates: Period.PeriodStartEnd) -> [AveragesChart.ChartLine] {
        var chartData = [AveragesChart.ChartLine]()

        df.dateFormat = "yyyy-MM-dd"
        let dateStart = df.string(from: dates.start)
        let dateEnd = df.string(from: dates.end)

        do {
            chartData = try db.read { db in
                let chartsCTE = CommonTableExpression(
                    recursive: true,
                    named: "charts",
                    columns: ["type", "xAxis", "yValue"],
                    literal:
                    """
                    WITH RECURSIVE
                        vars AS (
                            SELECT \(dateStart) as dateStart, \(dateEnd) as dateEnd
                        ),
                        agesVisitsRange(visitAge) AS (
                            VALUES(0)
                            UNION ALL
                            SELECT visitAge+1 FROM agesVisitsRange WHERE visitAge <
                                ( SELECT max(visitAge) FROM selectedRows )
                        ),
                        selectedRows AS (
                            SELECT patientId, visitDate, visitAge, visitFirst
                            FROM visit v, vars
                            WHERE
                                v.visitDate BETWEEN dateStart AND dateEnd
                                AND visitCalendar IN ('Marieke', 'Marieke nieuwe')
                            ),
                        alle AS (
                            SELECT agesVisitsRange.visitAge, count(selectedRows.visitAge) AS ageCount
                            FROM agesVisitsRange
                            LEFT JOIN selectedRows ON agesVisitsRange.visitAge = selectedRows.visitAge
                            GROUP BY agesVisitsRange.visitAge
                            ),
                        eerste AS (
                            SELECT agesVisitsRange.visitAge, count(selectedRows.visitAge) AS ageCount
                            FROM agesVisitsRange
                            LEFT JOIN selectedRows
                                ON agesVisitsRange.visitAge = selectedRows.visitAge
                                AND visitFirst = true
                            GROUP BY agesVisitsRange.visitAge
                            )

                    SELECT 'alle' AS type, visitAge AS xAxis, ageCount as yValue
                    FROM alle
                    UNION
                    SELECT 'alleCum' AS type, visitAge AS xAxis,
                        SUM(coalesce(ageCount / total.total, 0)) OVER (ORDER BY visitAge) AS yValue
                    FROM alle,
                            (SELECT count(*) * 1.0 AS total FROM selectedRows) AS total
                    UNION
                    SELECT 'eerste' AS type, visitAge AS xAxis, ageCount AS yValue
                    FROM eerste
                    UNION
                    SELECT 'eersteCum' AS type, visitAge AS xAxis,
                        SUM(coalesce(ageCount / total.total, 0)) OVER (ORDER BY visitAge) AS yValue
                    FROM eerste,
                        (SELECT count(*) * 1.0 AS total FROM selectedRows WHERE visitFirst = true) AS total

                    ORDER BY type, xAxis
                    """
                )
                let request = chartsCTE.all().with(chartsCTE)
                return try AveragesChart.ChartLine.fetchAll(db, request)
            }
        } catch {
            fatalError("\(error)")
        }
        return chartData
    }

    func getAgesPatients(dates: Period.PeriodStartEnd) -> [AveragesChart.ChartLine] {
        var chartData = [AveragesChart.ChartLine]()

        df.dateFormat = "yyyy-MM-dd"
        let dateStart = df.string(from: dates.start)
        let dateEnd = df.string(from: dates.end)

        do {
            chartData = try db.read { db in
                let chartsCTE = CommonTableExpression(
                    named: "charts",
                    columns: ["type", "xAxis", "yValue"],
                    literal:
                    """
                      WITH
                         vars AS (
                         SELECT \(dateStart) as dateStart, \(dateEnd) as dateEnd
                         ),
                         patientAllVisits AS (
                             SELECT p.id, p.patientName,
                                 cast(((julianDay(max(v1.visitDate)) - julianday(min(v1.visitCreated))) / 30) as int) AS patientAge /*,
                                 date(MIN(v1.visitCreated)) AS minDate, date(MAX(v1.visitDate)) AS maxDate */
                             FROM patient p, visit v, visit v1, vars
                             WHERE v.visitDate BETWEEN dateStart AND dateEnd
                             AND v.visitCalendar IN ('Marieke', 'Marieke nieuwe')
                             AND p.id = v.patientId
                             AND p.id = v1.patientId
                             AND v1.visitDate < dateEnd
                             GROUP BY p.id
                          ),
                         patientAllCounts AS (
                         SELECT patientAge, count(patientAge) * 1.0 as ageCount
                         FROM patientAllVisits
                         GROUP BY patientAge
                         ORDER BY patientAge
                         )
                     SELECT 'alle' AS type, patientAge as xAxis, ageCount AS yValue
                     FROM patientAllCounts
                     UNION
                     SELECT 'alleCum' AS type, patientAge as xAxis,
                         SUM(coalesce(ageCount / total, 0)) OVER (ORDER BY patientAge) AS yValue
                     FROM patientAllCounts ,
                         (SELECT count(*) * 1.0 AS total from patientAllVisits) AS total

                     ORDER BY type, xAxis
                   """
                )
                let request = chartsCTE.all().with(chartsCTE)
                return try AveragesChart.ChartLine.fetchAll(db, request)
            }
        } catch {
            fatalError("\(error)")
        }
        return chartData
    }

    func getNumbersVisits1(dates: Period.PeriodStartEnd) -> [AveragesChart.ChartLine] {
        var chartData = [AveragesChart.ChartLine]()

        df.dateFormat = "yyyy-MM-dd"
        let dateStart = df.string(from: dates.start)
        let dateEnd = df.string(from: dates.end)

        do {
            chartData = try db.read { db in
                let chartsCTE = CommonTableExpression(
                    named: "charts",
                    columns: ["type", "xAxis", "yValue"],
                    literal:
                    """
                     WITH
                            vars AS (
                            SELECT \(dateStart) as dateStart, \(dateEnd) as dateEnd
                            ),
                            patientAllVisits AS (
                                SELECT p.id, p.patientName,
                                    (SELECT count(*)
                                    FROM visit v, vars
                                    WHERE v.visitCalendar IN ('Marieke', 'Marieke nieuwe')
                                    AND p.id = v.patientId
                                    ) AS visitCount
                                FROM patient p, visit v, vars
                                WHERE v.visitCalendar IN ('Marieke', 'Marieke nieuwe')
                                AND p.id = v.patientId
                                AND v.visitDate BETWEEN dateStart AND dateEnd
                                GROUP BY p.id
                             ),
                             patientAllCount AS (
                                SELECT visitCount, count(*) * 1.0 AS visitTotal
                                FROM patientAllVisits
                                GROUP BY visitCount
                            )

                        SELECT 'alle' AS type, visitCount AS xAxis, visitTotal AS yValue
                        FROM patientAllCount
                        UNION
                        SELECT 'alleCum' AS type, visitCount AS xAxis,
                            SUM(coalesce(visitTotal / total.total, 0)) OVER (ORDER BY visitCount) AS yValue
                        FROM patientAllCount,
                            (SELECT SUM(visitTotal) * 1.0 AS total FROM patientAllCount) AS total

                        ORDER BY type, xAxis

                    """
                )
                let request = chartsCTE.all().with(chartsCTE)
                return try AveragesChart.ChartLine.fetchAll(db, request)
            }
        } catch {
            fatalError("\(error)")
        }
        return chartData
    }
}
