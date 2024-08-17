//
//  LocationsModel.swift
//  AgendaAssistent
//
//  Created by André Hartman on 13/01/2021.
//  Copyright © 2021 André Hartman. All rights reserved.
//
import MapKit

class MapModel {
    let model = MainModel()
    var mapCircles = [PatientMap.Circle]()

    func doMapView(filteredPatients: [PatientInfo], circles: [PatientMap.Circle]) -> PatientMap {
        mapCircles = circles
        let localPins = getPins(patients: filteredPatients)
        let localMap = PatientMap(
            marker: localPins,
            legend: getLegend(pins: localPins),
            region: getRegion(pins: localPins)
        )
        return localMap
    }

    func getPins(patients: [PatientInfo]) -> [PatientMap.Marker] {
        let rodeweg = PatientMap.Marker(coordinate: thuis, radius: 0.0, color: .yellow, monogram: "")
        let rodewegDistance = CLLocation(latitude: thuis.latitude, longitude: thuis.longitude)

        var localPins = [PatientMap.Marker]()
        for patient in patients {
            let patientLocation = CLLocation(latitude: patient.patientLatitude!, longitude: patient.patientLongitude!)
            let patientLocationDistance = patientLocation.distance(from: rodewegDistance)
            let mapCircle = mapCircles.first(where: { patientLocationDistance < $0.radius })
            let monogram = String(patient.patientName
                .components(separatedBy: " ")
                .map { String($0.prefix(1)) }
                .joined()
                .prefix(2)
                .reversed()
                )

            localPins.append(PatientMap.Marker(coordinate: patientLocation.coordinate, radius: mapCircle!.radius, color: mapCircle!.strokeColor, monogram: monogram))
        }
        localPins.append(rodeweg)
        return localPins
    }

    func getLegend(pins: [PatientMap.Marker]) -> [PatientMap.Legend] {
        var localLegend = [PatientMap.Legend]()

        var previousDistance = 0.0
        var counterTotal = 0
        for (index, mapCircle) in mapCircles.enumerated() {
            let distance = mapCircle.radius
            let counter = pins.filter { $0.radius == distance }.count
            counterTotal += counter
            let stringDistance = (index == mapCircles.count - 1) ? "> \(Int(previousDistance/1000)) km" : "< \(Int(distance/1000)) km"
            localLegend.append(PatientMap.Legend(roundedDistance: distance, distance: stringDistance, count: String(counter), percentage: "0%", color: mapCircle.strokeColor))
            previousDistance = distance
        }

        var percent = 0.0
        for (index, _) in localLegend.enumerated() {
            percent += Double(localLegend[index].count)!/Double(counterTotal)
            if percent.isNaN { percent = 0 }
            let roundedPercentage = Int(round(percent * 20)/20 * 100)
            localLegend[index].percentage = String("\(roundedPercentage)%")
        }
        return localLegend
    }

    func getRegion(pins: [PatientMap.Marker]) -> (MKCoordinateRegion) {
        let coordinates = pins.map(\.coordinate)
        let minLatitude = coordinates.map(\.latitude).min()!
        let maxLatitude = coordinates.map(\.latitude).max()!
        let minLongitude = coordinates.map(\.longitude).min()!
        let maxLongitude = coordinates.map(\.longitude).max()!
        let spanFactor = 1.1

        let latitudeDelta = (maxLatitude - minLatitude) * spanFactor
        let longitudeDelta = (maxLongitude - minLongitude) * spanFactor
        let localRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: minLatitude + (maxLatitude - minLatitude)/2.0,
                longitude: minLongitude + (maxLongitude - minLongitude)/2.0
            ),
            span: MKCoordinateSpan(
                latitudeDelta: latitudeDelta,
                longitudeDelta: longitudeDelta
            )
        )
        return localRegion
    }
}
