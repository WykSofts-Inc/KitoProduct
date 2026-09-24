//
//  KitoStockIndicator.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// A coloured dot and a message for how much is left: "In stock", "Selling fast", "Only 2 left",
/// "Sold out". The dot pulses while stock is low; the bar style adds a level meter.
///
/// ```swift
/// KitoStockIndicator(stock: variant.stock)
/// KitoStockIndicator(level: .low(2), style: .bar)
/// ```
public struct KitoStockIndicator: View {
    public enum Style: Sendable, CaseIterable {
        case dot
        case bar
    }

    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let level: KitoStockLevel
    let style: Style
    let tint: Color?
    @State private var pulsing = false

    public init(level: KitoStockLevel, style: Style = .dot, tint: Color? = nil) {
        self.level = level
        self.style = style
        self.tint = tint
    }

    public init(stock: Int?, thresholds: KitoStockThresholds = .standard, style: Style = .dot, tint: Color? = nil) {
        self.init(level: KitoStockLevel.level(for: stock, thresholds: thresholds), style: style, tint: tint)
    }

    public var body: some View {
        HStack(spacing: theme.spacing.sm) {
            dot
            Text(level.message)
                .font(theme.typography.label)
                .foregroundStyle(level.isUrgent ? color : theme.colors.onBackground.opacity(0.75))
                .contentTransition(.opacity)
            if style == .bar {
                Spacer(minLength: theme.spacing.sm)
                meter
            }
        }
        .animation(.easeInOut(duration: 0.25), value: level)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(level.message)
        .onAppear { pulsing = true }
    }

    private var dot: some View {
        ZStack {
            if level.isUrgent && !reduceMotion {
                Circle()
                    .fill(color.opacity(0.35))
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulsing ? 2.4 : 1)
                    .opacity(pulsing ? 0 : 1)
                    .animation(.easeOut(duration: 1.3).repeatForever(autoreverses: false), value: pulsing)
            }
            Circle().fill(color).frame(width: 8, height: 8)
        }
        .frame(width: 18, height: 18)
    }

    private var meter: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(index < filledSegments ? color : theme.colors.onBackground.opacity(0.12))
                    .frame(width: 14, height: 4)
            }
        }
    }

    private var filledSegments: Int {
        switch level {
        case .inStock: 5
        case .sellingFast: 3
        case .low(let count): count <= 1 ? 1 : 2
        case .soldOut, .unavailable: 0
        }
    }

    private var color: Color {
        switch level {
        case .inStock: tint ?? theme.colors.success
        case .sellingFast: theme.colors.warning
        case .low: theme.colors.danger
        case .soldOut, .unavailable: theme.colors.onBackground.opacity(0.35)
        }
    }
}
