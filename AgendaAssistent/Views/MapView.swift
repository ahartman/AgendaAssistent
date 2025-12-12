//
//  MapView.swift
//  AgendaAssistent
//
//  Created by André Hartman on 29/12/2022.
//  Copyright © 2022 André Hartman. All rights reserved.
//

import MapKit
import SwiftUI

struct MapView: View {
    @EnvironmentObject var mainModel: MainModel

    var body: some View {
        ZStack {
            provideMapView()
            VStack(alignment: .trailing) {
                Text("Test")
                ForEach(mainModel.patientPinsCounts.enumerated(), id: \.self)  { index, pinscount in
                    HStack {
                        if index == mainModel.patientPinsCounts.endIndex-1
                            Text("\(pinscount.roundedDistance)")
                    } else {
                        Text("< \(pinscount.roundedDistance)")
                    }
                        Text("\(pinscount.count)")
                    }
                }
            }
            .border(.black)
            .foregroundColor(.red)
            .background(.white)
        }
        .background(.red)
        .navigationBarTitleDisplayMode(.inline)
        .statusBar(hidden: true)
    }
}

struct provideMapView: UIViewRepresentable {
    @EnvironmentObject var mainModel: MainModel

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: UIScreen.main.bounds)
        mapView.delegate = context.coordinator
        mapView.setRegion(mainModel.region, animated: true)
        return mapView
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        for counter in mainModel.ringsCounter {
            let circle = MKCircle(center: mainModel.home, radius: counter.roundedDistance)
            view.addOverlay(circle)
        }

        for patientPin in mainModel.patientPins {
            let pin = CustomAnnotation(coordinate: patientPin.coordinates, tag: patientPin.roundedDistance)
            view.addAnnotation(pin)
        }

        let pin = CustomAnnotation(coordinate: mainModel.home, tag: 0)
        view.addAnnotation(pin)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: provideMapView
        init(_ parent: provideMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
            view.canShowCallout = false

            let tag = (annotation as! CustomAnnotation).tag
            view.pinTintColor = ringColor(ring: tag)
            return view
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circleOverlay = overlay as? MKCircle {
                let renderer = MKCircleRenderer(overlay: circleOverlay)
                renderer.strokeColor = ringColor(ring: circleOverlay.radius)
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

public func ringColor(ring: Double) -> UIColor {
    switch ring {
    case circles.ring1.rawValue:
        return UIColor(ringColor1)
    case circles.ring2.rawValue:
        return UIColor(ringColor2)
    case circles.ring3.rawValue:
        return UIColor(ringColor3)
    case circles.ring4.rawValue:
        return UIColor(ringColor4)
    default:
        return UIColor(.black)
    }
}

class CustomAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    // let title: String?
    let tag: Double

    init(coordinate: CLLocationCoordinate2D, tag: Double) {
        self.coordinate = coordinate
        // self.title = title
        self.tag = tag
        super.init()
    }
}
