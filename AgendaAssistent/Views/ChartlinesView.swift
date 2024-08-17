
//
//  ChartLinesView.swift
//  AgendaAssistent
//
//  Created by André Hartman on 14/09/2023.
//  Copyright © 2023 André Hartman. All rights reserved.
//
import Charts
import SwiftUI

struct ChartlinesView: View {
    @Environment(MainModel.self) private var model
    var chartNumber: Int

    let yAxisCumulatief = [0.25, 0.5, 0.75, 0.9]
    let kleuren = [
        "primary": kleur,
        "primaryLight": kleur.opacity(transparant),
        "secondary": .green,
        "secondaryLight": .green.opacity(transparant)
    ]

    var body: some View {
        let (title, xAxisLabel) = getTexts()
        SliderHeaderView(model: model)
        ChartlinesViewHeader(model: model, chartNumber: chartNumber)
        let localLines = highlightLines(lines: model.chartsData.chartData)
        Chart {
            ForEach(localLines) { line in
                BarMark(
                    x: .value("Maanden", String(line.xAxis)),
                    y: .value("Waarde", line.yValue)
                )
                .foregroundStyle(kleuren[line.barColor!]!)
                .position(by: .value("Naam", line.type))
                .annotation(position: .top, alignment: .center) {
                    Text(line.barPercent ?? "")
                        .font(.caption)
                }
            }
        }
        .chartXAxisLabel(position: .bottom, alignment: .center) {
            Text(xAxisLabel)
                .font(.system(size: tekstGrootte))
                .foregroundColor(kleur)
        }
        .chartYAxisLabel(position: .top, alignment: .leading) {
            Text("\(model.chartsData.chartToggles.cumulatief ? "Aandeel in %" : "Aantallen")")
                .font(.system(size: tekstGrootte))
                .foregroundColor(kleur)
        }
        .chartXAxis {
            AxisMarks(position: .bottom) { value in
                AxisGridLine()
                AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                AxisValueLabel(
                    centered: true,
                    collisionResolution: .greedy
                ) {
                    if let temp = value.as(String.self) {
                        Text("\(temp)")
                            .font(.system(size: tekstGrootte))
                            .foregroundColor(kleur)
                    }
                }
            }
        }
        .chartYAxis {
            let max = ((localLines.map { $0.yValue }.max() ?? 0) / 10.0).rounded(.up) * 10
            let step = max == 0 ? 1 : max / 10
            let yStride = Array(stride(from: 0, through: max, by: step))
            let asWaarden = model.chartsData.chartToggles.cumulatief ? yAxisCumulatief : yStride
            AxisMarks(preset: .aligned, position: .leading, values: asWaarden) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(centered: false) {
                    if let temp = value.as(Double.self) {
                        Text("\(model.chartsData.chartToggles.cumulatief ? temp.formatted(.percent) : temp.formatted(.number))")
                            .font(.system(size: tekstGrootte))
                            .foregroundColor(kleur)
                    }
                }
            }
        }
        .onChange(of: chartNumber, initial: true) {
            model.doChartLines(chartNr: chartNumber)
        }
#if os(iOS)
        .navigationBarTitle(title, displayMode: .inline)
#endif
    }

    func highlightLines(lines: [AveragesChart.ChartLine]) -> [AveragesChart.ChartLine] {
        let eersteLines = highlightBars(
            localTest: "secondary",
            localLines: lines.filter { $0.type.localizedStandardContains("Eerste") }
        )
        let alleLines = highlightBars(
            localTest: "primary",
            localLines: lines.filter { $0.type.localizedStandardContains("Alle") }
        )
        return eersteLines + alleLines

        func highlightBars(localTest: String, localLines: [AveragesChart.ChartLine]) -> [AveragesChart.ChartLine] {
            let localLines = highlightPercentages(
                localTest: localTest,
                localLines: localLines
                    .map {
                        AveragesChart.ChartLine(
                            xAxis: $0.xAxis,
                            type: $0.type,
                            yValue: $0.yValue,
                            barPercent: $0.barPercent,
                            barColor: localTest
                        )
                    }
            )
            return localLines
        }

        func highlightPercentages(localTest: String, localLines: [AveragesChart.ChartLine]) -> [AveragesChart.ChartLine] {
            var tempLines = localLines.filter { $0.type.localizedStandardContains("Cum") }
            if tempLines.count > 10 {
                for percent in yAxisCumulatief {
                    let closest = tempLines
                        .enumerated()
                        .min(by: { abs($0.element.yValue - percent) < abs($1.element.yValue - percent) })!
                    tempLines[closest.offset].barColor = "\(localTest)Light"
                    tempLines[closest.offset].barPercent = percent.formatted(.percent.precision(.fractionLength(0)))
                }
            } else {
                tempLines = localLines
            }
            return tempLines
        }
    }

    func getTexts() -> (String, String) {
        var title = ""
        var xAxisLabel = ""
        switch chartNumber {
        case 1:
            title = "Ouderdom patiënten"
            xAxisLabel = "Ouderdom (vanaf 1e consultatie) in maanden"
        case 2:
            title = "Consultaties per patiënt"
            xAxisLabel = "Aantal consultaties per patiënt"
        case 3:
            title = "Ouderdom consultaties"
            xAxisLabel = "Ouderdom sinds afspraak in weken"
        default:
            title = "Onbekend"
            xAxisLabel = "Onbekend"
        }
        return (title, xAxisLabel)
    }
}

struct ChartlinesViewHeader: View {
    @Bindable var model: MainModel
    let chartNumber: Int
    let width: CGFloat = 240

    var body: some View {
        HStack {
            Spacer()
            if chartNumber == 3 {
                Text("Consultaties: ")
                Text("Eerste")
                Toggle("", isOn: $model.chartsData.chartToggles.eerste).labelsHidden()
                    .tint(kleur)
                // .disabled(model.eersteDisabled)
                Spacer()
                .tint(kleur)
                Spacer()
            }
            Text("Cumulatief tonen:")
            Toggle("", isOn: $model.chartsData.chartToggles.cumulatief).labelsHidden()
                .tint(kleur)
            Spacer()
        }
        .onChange(of: model.chartsData.chartToggles) {
            model.doChartLines()
        }
    }
}
