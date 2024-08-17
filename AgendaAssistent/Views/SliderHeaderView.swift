//
//  HeaderView.swift
//  AgendaAssistent
//
//  Created by André Hartman on 21/12/2023.
//  Copyright © 2023 André Hartman. All rights reserved.
//

import MultiSlider
import SwiftUI

@MainActor
struct SliderHeaderView: View {
    @Bindable var model: MainModel
    let screenWidth: CGFloat = UIScreen.main.bounds.width - 32.0
    let labelFormat = Date.FormatStyle()
        .year(.twoDigits)
        .month(.abbreviated)

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("Van:")
                Text(model.period.periodDates.start, style: .date)
                Spacer()
                Text("tot:")
                Text(model.period.periodDates.end, style: .date)
                Spacer()
            }
            HStack {
                Spacer()
                MultiValueSlider(
                    value: $model.period.periodStart,
                    minimumValue: model.period.periodEnds[0],
                    maximumValue: model.period.periodEnds[1],
                    isContinuous: false,
                    snapStepSize: 12,
                    valueLabelPosition: .top,
                    orientation: .horizontal,
                    valueLabelColor: UIColor(kleur)
                )
                .snapImage(.init(systemName: "line.diagonal"))
                .valueLabelTextForThumb { _, value in
                    "\(kalender.date(byAdding: DateComponents(month: Int(value / 4)), to: Date())!.formatted(labelFormat))"
                }
                .padding(.horizontal, 20)
                .containerRelativeFrame(.horizontal, count: 12, span: 8, spacing: 1)
                .onChange(of: model.period.periodStart, initial: false) { setPeriod() }
                Spacer()
                MultiValueSlider(
                    value: $model.period.periodLength,
                    minimumValue: CGFloat(0),
                    maximumValue: CGFloat(96),
                    isContinuous: false,
                    snapStepSize: 4,
                    valueLabelPosition: .top,
                    orientation: .horizontal,
                    valueLabelColor: UIColor(kleur)
                )
                .snapImage(.init(systemName: "line.diagonal"))
                .valueLabelTextForThumb { _, value in
                    "\(Int(value / 4)) maanden"
                }
                .padding(.horizontal, 20)
                .containerRelativeFrame(.horizontal, count: 12, span: 4, spacing: 1)
                .onChange(of: model.period.periodLength, initial: false) { setPeriod() }
                Spacer()
            }
            .frame(maxHeight: 80)
        }
    }

    func setPeriod() {
        let tempStart = kalender.date(byAdding: DateComponents(day: Int(model.period.periodStart[0]) * 7), to: model.zeroDate)!
        model.period.periodDates = Period.PeriodStartEnd(
            start: tempStart,
            end: kalender.date(byAdding: DateComponents(day: Int(model.period.periodLength[0]) * 7), to: tempStart)!
        )
        model.loadAndUpdate()
    }
}
