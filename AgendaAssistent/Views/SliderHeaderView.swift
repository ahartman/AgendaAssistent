//
//  HeaderView.swift
//  AgendaAssistent
//
//  Created by André Hartman on 21/12/2023.
//  Copyright © 2023 André Hartman. All rights reserved.
//

import BetterSlider
import MultiSlider
import SwiftUI

@MainActor
struct SliderHeaderView: View {
    @Bindable var model: MainModel
    let screenWidth: CGFloat = UIScreen.main.bounds.width - 32.0

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
                let range = model.period.periodEnds[0]...model.period.periodEnds[1]
                BetterSlider(value: $model.period.periodStart, in: range, step: 12.0)
                    { Text("") } maximumValueLabel: { Text("") }
                    .containerRelativeFrame(.horizontal, count: 12, span: 8, spacing: 1)
                    .safeAreaInset(edge: .top) {
                        Text(formatThumb(value: model.period.periodStart))
                            .monthStyle(value: model.period.periodStart)
                     }
                    .onChange(of: model.period.periodStart, initial: false) { setPeriod() }
                BetterSlider(value: $model.period.periodLength, in: 0.0...96.0, step: 12.0)
                    { Text("") } maximumValueLabel: { Text("") }
                   .containerRelativeFrame(.horizontal, count: 12, span: 4, spacing: 1)
                    .safeAreaInset(edge: .top) {
                        Text("\(Int(model.period.periodLength / 4)) maanden")
                            .monthStyle(value: model.period.periodLength)
                    }
                    .onChange(of: model.period.periodLength, initial: false) { setPeriod() }
            }
            .showSliderStep()
            .sliderHandleSize(20)
            .sliderTrackHeight(5)
            .sliderStepHeight(25)
            .sliderTrackColor(kleur)
            .sliderHandleColor(.green)
            .tint(kleur)
            .padding(.horizontal, 20)
        }
    }

    func formatThumb(value: Double) -> String {
        let labelFormat = Date.FormatStyle()
            .year(.twoDigits)
            .month(.abbreviated)
        return kalender.date(byAdding: DateComponents(month: Int(value / 4)), to: Date())!.formatted(labelFormat)
    }

    func setPeriod() {
        let tempStart = kalender.date(byAdding: DateComponents(day: Int(model.period.periodStart) * 7), to: model.zeroDate)!
        model.period.periodDates = Period.PeriodStartEnd(
            start: tempStart,
            end: kalender.date(byAdding: DateComponents(day: Int(model.period.periodLength) * 7), to: tempStart)!
        )
        model.loadAndUpdate()
    }
}

struct MonthStyle: ViewModifier {
    let value: Double
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: .semibold, design: .rounded).monospacedDigit())
            .padding(0)
            .contentTransition(.numericText(value: value))
            .animation(.default, value: value)
    }
}
extension View {
    func monthStyle(value: Double) -> some View {
        modifier(MonthStyle(value: value))
    }
}
