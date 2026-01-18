//
//  GraphsView.swift
//  AgendaAssistent
//
//  Created by André Hartman on 11/01/2026.
//  Copyright © 2026 André Hartman. All rights reserved.
//

import SwiftUI

struct GraphsView: View {
    @State var selected = 3
    var body: some View {
        VStack {
            Divider()
            HStack {
                Spacer()
                Picker("What", selection: $selected) {
                    Text("Consultaties").tag(3)
                    Text("Patiënten").tag(1)
                    Text("Consultaties/patiënt").tag(2)
                }
                .pickerStyle(.segmented)
                .glassEffect()
                Spacer()
            }
            .padding([.leading, .trailing], 20)
            Divider()
            ChartlinesView(chartNumber: selected)
                .padding(20)
        }
    }
}

#Preview {
    GraphsView()
}
