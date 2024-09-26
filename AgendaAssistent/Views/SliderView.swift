//
//  CustomSlider.swift
//
//  Created by André Hartman on 24/09/2024.
//

import SwiftUI

struct SliderView: View {
    @Binding var value: CGFloat
    let range: ClosedRange<Double>
    let stepCount: Int
    let colors: [Color]
    @State private var isDragging = false
    @State private var lastValue: Double

    init(value: Binding<CGFloat>, range: ClosedRange<Double>, stepCount: Int, colors: [Color]) {
        self._value = value
        self.colors = colors
        self.range = range
        self.stepCount = stepCount
        self._lastValue = State(initialValue: value.wrappedValue)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background track
                Rectangle()
                    .fill(.clear)
                    .frame(height: 15)

                // Bar indicators
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(0 ..< self.stepCount, id: \.self) { index in
                        BarIndicator(
                            height: self.getBarHeight(for: index),
                            isHighlighted: Double(index) <= self.getNormalizedValue() * Double(self.stepCount - 1),
                            isCurrentValue: self.isCurrentValue(index),
                            isDragging: self.isDragging,
                            shouldShow: Double(index) <= self.getNormalizedValue() * Double(self.stepCount - 1), colors: self.colors
                        )
                    }
                }
            }
            .frame(minHeight: 50, alignment: .bottom)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let newValue = self.getValue(geometry: geometry, dragLocation: gesture.location)
                        self.value = min(max(self.range.lowerBound, newValue), self.range.upperBound)
                        self.isDragging = true

                        // Trigger haptic feedback when moving between steps
                        if Int(self.value) != Int(self.lastValue) {
                            // HapticManager.shared.trigger(.light)
                            self.lastValue = self.value
                        }
                    }
                    .onEnded { _ in
                        self.isDragging = false
                        // HapticManager.shared.trigger(.light)
                    }
            )
        }
    }

    private func getProgress(geometry: GeometryProxy) -> CGFloat {
        let percent = (self.value - self.range.lowerBound) / (self.range.upperBound - self.range.lowerBound)
        return geometry.size.width * CGFloat(percent)
    }

    private func getValue(geometry: GeometryProxy, dragLocation: CGPoint) -> Double {
        let percent = Double(dragLocation.x / geometry.size.width)
        let value = percent * (self.range.upperBound - self.range.lowerBound) + self.range.lowerBound
        return value
    }

    private func getNormalizedValue() -> Double {
        return (self.value - self.range.lowerBound) / (self.range.upperBound - self.range.lowerBound)
    }

    private func getBarHeight(for index: Int) -> CGFloat {
        let normalizedValue = self.getNormalizedValue()
        let stepValue = Double(index) / Double(self.stepCount - 1)
        let difference = abs(normalizedValue - stepValue)
        let maxHeight: CGFloat = 35
        let minHeight: CGFloat = 15

        if difference < 0.15 {
            return maxHeight - CGFloat(difference / 0.15) * (maxHeight - minHeight)
        } else {
            return minHeight
        }
    }

    private func isCurrentValue(_ index: Int) -> Bool {
        let normalizedValue = self.getNormalizedValue()
        let stepValue = Double(index) / Double(self.stepCount - 1)
        return abs(normalizedValue - stepValue) < (1.0 / Double(self.stepCount - 1)) / 2
    }
}

struct BarIndicator: View {
    let height: CGFloat
    let isHighlighted: Bool
    let isCurrentValue: Bool
    let isDragging: Bool
    let shouldShow: Bool
    let colors: [Color]

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(self.isCurrentValue ? LinearGradient(colors: self.colors, startPoint: .bottom, endPoint: .top) : (self.isHighlighted ? LinearGradient(colors: self.colors.map { $0.opacity(0.75) }, startPoint: .bottom, endPoint: .top) : LinearGradient(colors: [.primary.opacity(0.4), .primary.opacity(0.3)], startPoint: .bottom, endPoint: .top)))
            .frame(width: 4, height: (self.isDragging && self.shouldShow) ? self.height : 15)
            .animation(.bouncy, value: self.height)
            .animation(.bouncy, value: self.isDragging)
            .animation(.bouncy, value: self.shouldShow)
    }
}

struct MeshingSlider: View {
    @Binding var value: CGFloat
    let colors: [Color] = [.yellow, .red]
    var range: ClosedRange<Double> = 0 ... 35

    var body: some View {
        HStack(alignment: .center) {
            SliderView(value: self.$value.animation(.bouncy), range: self.range, stepCount: 35, colors: self.colors)
        }
    }
}
