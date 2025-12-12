//
//  WriteCSV.swift
//  AgendaAssistent
//
//  Created by André Hartman on 13/02/2022.
//  Copyright © 2022 André Hartman. All rights reserved.
//
import SwiftUI

struct CommandsView: View {
    @Environment(MainModel.self) private var model
    var title: String
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("Van: ")
                Text(model.period.periodDates.start, style: .date)
                Spacer()
                Text("tot: ")
                Text(model.period.periodDates.end, style: .date)
                Spacer()
            }
            .environment(\.locale, Locale(identifier: "nl"))
            Divider()
            HStack {
                Spacer()
                Button(action: { model.fullUpdate() }) {
                    Text("Full update")
                        .padding()
                        .background(kleur)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                Spacer()
#if targetEnvironment(macCatalyst)
                Button(action: { model.writeCSV() }) {
                    Text("Weekformulier")
                        .padding()
                        .background(kleur)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                Spacer()
#endif
            }
            .padding()
            .buttonStyle(.borderless)
        }
        .statusBar(hidden: true)
        .frame(maxWidth: 600)
        .border(.gray)
#if os(iOS)
            .navigationBarTitle(title, displayMode: .inline)
#endif
    }
}
