//
//  KitoSizeGuideSheet.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// A size guide for a sheet: what customers say about the fit, the size chart in centimetres or
/// inches with the chosen size highlighted, and how to measure. Tapping a row picks that size.
///
/// ```swift
/// .sheet(isPresented: $showGuide) {
///     KitoSizeGuideSheet(guide: runnerGuide, selection: $sizeID)
///         .presentationDetents([.medium, .large])
/// }
/// ```
public struct KitoSizeGuideSheet: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let guide: KitoSizeGuide
    @Binding var selection: String?
    let tint: Color?
    @State private var inches = false

    public init(guide: KitoSizeGuide, selection: Binding<String?> = .constant(nil), tint: Color? = nil) {
        self.guide = guide
        _selection = selection
        self.tint = tint
    }

    private var palette: ProductPalette { ProductPalette(theme: theme, tint: tint) }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.xl) {
                header
                if let fit = guide.fit { KitoFitFeedbackBar(fit, tint: tint) }
                table
                if !guide.howToMeasure.isEmpty { measuring }
            }
            .padding(theme.spacing.xl)
        }
        .background(theme.colors.background)
    }

    private var header: some View {
        HStack {
            Text(guide.title)
                .font(theme.typography.titleLarge)
                .foregroundStyle(theme.colors.onBackground)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.colors.onBackground)
                    .frame(width: 32, height: 32)
                    .background(theme.colors.surfaceMuted, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }

    private var table: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack {
                EyebrowText("Measurements")
                Spacer()
                if guide.allowsInches { unitToggle }
            }
            VStack(spacing: 0) {
                row(label: "Size", values: guide.measurements, isHeader: true, isSelected: false)
                ForEach(guide.rows) { item in
                    Button {
                        withAnimation(ProductMotion.select(reduceMotion)) { selection = item.sizeID }
                    } label: {
                        row(label: item.label, values: item.values.map { KitoSizeGuide.format($0, inches: inches) },
                            isHeader: false, isSelected: item.sizeID == selection)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(accessibility(for: item))
                    .accessibilityAddTraits(item.sizeID == selection ? .isSelected : [])
                }
            }
            .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: theme.radii.md, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: theme.radii.md, style: .continuous).strokeBorder(palette.hairline))
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.md, style: .continuous))
            Text(inches ? "Body measurements in inches." : "Body measurements in centimetres.")
                .font(theme.typography.caption)
                .foregroundStyle(palette.muted)
        }
    }

    private var unitToggle: some View {
        HStack(spacing: 0) {
            unitButton("cm", isOn: !inches) { inches = false }
            unitButton("in", isOn: inches) { inches = true }
        }
        .padding(2)
        .background(theme.colors.surfaceMuted, in: Capsule())
    }

    private func unitButton(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(ProductMotion.select(reduceMotion)) { action() }
        } label: {
            Text(title)
                .font(theme.typography.caption.weight(.semibold))
                .foregroundStyle(isOn ? palette.onInk : theme.colors.onBackground)
                .frame(width: 38, height: 26)
                .background { if isOn { Capsule().fill(palette.ink) } }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private func row(label: String, values: [String], isHeader: Bool, isSelected: Bool) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                Text(value)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .contentTransition(.numericText())
            }
        }
        .font(isHeader ? theme.typography.caption.weight(.semibold) : theme.typography.label.weight(isSelected ? .semibold : .regular))
        .foregroundStyle(isSelected ? palette.onInk : (isHeader ? palette.muted : theme.colors.onBackground))
        .padding(.horizontal, theme.spacing.lg)
        .padding(.vertical, theme.spacing.md)
        .background(isSelected ? palette.ink : (isHeader ? theme.colors.surfaceMuted : Color.clear))
        .overlay(alignment: .bottom) {
            Rectangle().fill(palette.hairline.opacity(0.6)).frame(height: 0.5)
        }
    }

    private var measuring: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            EyebrowText("How to measure")
            ForEach(Array(guide.howToMeasure.enumerated()), id: \.element.id) { index, step in
                HStack(alignment: .top, spacing: theme.spacing.md) {
                    ZStack {
                        Circle().fill(theme.colors.surfaceMuted)
                        Image(systemName: step.systemImage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(theme.colors.onBackground)
                    }
                    .frame(width: 38, height: 38)
                    .overlay(alignment: .topTrailing) {
                        Text("\(index + 1)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(palette.onInk)
                            .frame(width: 15, height: 15)
                            .background(palette.ink, in: Circle())
                            .offset(x: 3, y: -3)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(step.title)
                            .font(theme.typography.bodyEmphasized)
                            .foregroundStyle(theme.colors.onBackground)
                        Text(step.detail)
                            .font(theme.typography.label.weight(.regular))
                            .foregroundStyle(palette.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func accessibility(for row: KitoSizeGuideRow) -> String {
        let unit = inches ? "inches" : "centimetres"
        let pairs = zip(guide.measurements, row.values).map { "\($0) \(KitoSizeGuide.format($1, inches: inches))" }
        return "\(row.label): " + pairs.joined(separator: ", ") + " \(unit)"
    }
}

/// A "Runs small — True to size — Runs large" track with a marker where customers put the fit.
///
/// ```swift
/// KitoFitFeedbackBar(KitoFitFeedback(value: 0.3, reviewCount: 214))
/// ```
public struct KitoFitFeedbackBar: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let fit: KitoFitFeedback
    let tint: Color?
    @State private var shown = false

    public init(_ fit: KitoFitFeedback, tint: Color? = nil) {
        self.fit = fit
        self.tint = tint
    }

    private var palette: ProductPalette { ProductPalette(theme: theme, tint: tint) }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text(fit.label)
                    .font(theme.typography.titleMedium)
                    .foregroundStyle(theme.colors.onBackground)
                Spacer()
                if fit.reviewCount > 0 {
                    Text("From \(fit.reviewCount.formatted()) reviews")
                        .font(theme.typography.caption)
                        .foregroundStyle(palette.muted)
                }
            }
            track
            HStack {
                Text("Runs small")
                Spacer()
                Text("True to size")
                Spacer()
                Text("Runs large")
            }
            .font(theme.typography.caption)
            .foregroundStyle(palette.muted)
            Text(fit.advice)
                .font(theme.typography.label.weight(.regular))
                .foregroundStyle(theme.colors.onBackground.opacity(0.8))
        }
        .padding(theme.spacing.lg)
        .background(theme.colors.surfaceMuted, in: RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fit: \(fit.label). \(fit.advice)")
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.7, dampingFraction: 0.7).delay(0.15)) { shown = true }
        }
    }

    private var track: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(theme.colors.onBackground.opacity(0.1)).frame(height: 4)
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(theme.colors.onBackground.opacity(0.22))
                        .frame(width: 4, height: 4)
                        .offset(x: tickOffset(index, width: proxy.size.width))
                }
                Circle()
                    .fill(palette.ink)
                    .frame(width: 18, height: 18)
                    .overlay(Circle().strokeBorder(theme.colors.surface, lineWidth: 3))
                    .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                    .offset(x: markerOffset(width: proxy.size.width))
            }
            .frame(height: 18)
        }
        .frame(height: 18)
    }

    private func tickOffset(_ index: Int, width: CGFloat) -> CGFloat {
        (width - 4) * CGFloat(index) / 4
    }

    private func markerOffset(width: CGFloat) -> CGFloat {
        let position = shown ? fit.position : 0.5
        return (width - 18) * CGFloat(position)
    }
}
