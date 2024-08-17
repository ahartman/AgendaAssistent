//
//  BalanceView.swift
//  AgendaAssistent
//
//  Created by André Hartman on 02/09/2023.
//  Copyright © 2023 André Hartman. All rights reserved.
//

import SwiftUI

struct BalanceView: View {
    @Environment(MainModel.self) private var model

    let title: String
    var body: some View {
        SliderHeaderView(model: model)
        Table(model.inOutData) {
            TableColumn("Week") { line in
                Text("\(line.weekNumber)")
            }
            TableColumn("Consultaties") { line in
                Text("\(line.consultaties)")
            }
            TableColumn("No shows") { line in
                let temp = (line.consultaties > 0 ? (Double(line.nietGekomen) / Double(line.consultaties)) : 0)
                    .formatted(.percent.precision(.fractionLength(0)))
                Text("\(line.nietGekomen) (\(temp))")
            }
            TableColumn("Weg") { line in
                Text(line.geenVervolg == 0 ? "" : "\(line.geenVervolg)")
            }
            TableColumn("Nieuwe") { line in
                Text(line.nieuwe == 0 ? "" : "\(line.nieuwe)")
            }
            TableColumn("Voorstel") { line in
                Text(line.voorstellen == 0 ? "" : "\(line.voorstellen)")
            }
            TableColumn("Saldo") { line in
                Text("\(line.saldo)")
            }
        }
#if os(iOS)
        .navigationBarTitle(title, displayMode: .inline)
        .statusBar(hidden: true)
#endif
    }
}
