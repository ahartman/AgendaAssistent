//
//  PatientMapView.swift
//  AgendaAssistent
//
//  Created by André Hartman on 23/12/2023.
//  Copyright © 2023 André Hartman. All rights reserved.
//

import MapKit
import SwiftUI

struct PatientMapView: View {
    @Environment(MainModel.self) private var model
    var title: String

    var body: some View {
        SliderHeaderView(model: model)
        ZStack {
            doMap(mapData: model.mapData)
            doLegend(mapData: model.mapData)
        }
        .overlay {
            if model.mapData.marker.isEmpty {
                ContentUnavailableView(
                    "Geen adressen voor deze periode",
                    systemImage: "circle.slash"
                )
            }
        }
        #if os(iOS)
        .navigationBarTitle(title, displayMode: .inline)
        .statusBar(hidden: true)
        #endif
    }
}

struct doMap: View {
    var mapData: PatientMap
    var body: some View {
        Map {
            ForEach(mapData.marker) { line in
                Marker("", monogram: Text(line.monogram), coordinate: line.coordinate)
                    .tint(line.color)
            }
            ForEach(mapData.circles[...2]) { circle in
                MapCircle(center: circle.coordinate, radius: circle.radius)
                    .foregroundStyle(.clear)
                    .stroke(circle.strokeColor, lineWidth: 2)
            }
        }
    }
}

struct doLegend: View {
    var mapData: PatientMap
    let columns = [GridItem(.fixed(80)), GridItem(.fixed(80)), GridItem(.fixed(80))]
    var body: some View {
        VStack {
            HStack {
                Spacer()
                LazyVGrid(columns: columns) {
                    Text("Afstand")
                        .underline()
                    Text("Aantal")
                        .underline()
                    Text("Procent")
                        .underline()
                    ForEach(mapData.legend, id: \.self) { legend in
                        Text(legend.distance)
                        Text(legend.count)
                        Text(legend.percentage)
                    }
                }
                .border(.black)
                .background(Color.white.opacity(0.8))
                .padding([.trailing], 60)
                .padding([.top], 20)
                .frame(maxWidth: 240)
            }
            Spacer()
        }
    }
}
