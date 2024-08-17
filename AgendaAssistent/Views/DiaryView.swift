//
//  DiaryView.swift
//  AgendaAssistent
//
//  Created by André Hartman on 08/12/2023.
//  Copyright © 2023 André Hartman. All rights reserved.
//

import SwiftUI

struct DiaryView: View {
    @Environment(MainModel.self) private var model
    var title: String
    var body: some View {
        SliderHeaderView(model: model)
        Table(of: DiaryLine.self) {
            TableColumn("Dag") { line in
                let dateColor = line.diaryName == "" ? Color(kleur) : Color(.black)
                Text(line.diaryDate)
                    .foregroundStyle(dateColor)
            }
            TableColumn("Patiënt", value: \.diaryName)
        } rows: {
            ForEach(model.diaryData) { line in
                TableRow(line)
            }
        }
#if os(iOS)
        .navigationBarTitle(title, displayMode: .inline)
        .statusBar(hidden: true)
#endif
    }
}
