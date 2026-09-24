//
//  KitoSizePicker.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// Sizes as a grid or a row of chips. Sizes not made in the colour are struck through, sold-out
/// sizes can still be picked to offer "Notify me", and a low-stock size says "Only 2 left in UK 8".
/// Shakes and shows "Choose a size" when `error` is set, and again whenever `shakeTrigger` changes.
///
/// ```swift
/// KitoSizePicker(matrix.sizeOptions(for: colorID), selection: $sizeID,
///                error: issue == .chooseSize ? issue?.message : nil,
///                onSizeGuide: { showGuide = true },
///                onNotifyMe: { size in subscribe(size) })
/// ```
public struct KitoSizePicker: View {
    public enum Style: Sendable, CaseIterable {
        /// Four to a row.
        case grid
        /// One scrolling row of capsules.
        case chips
    }

    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var highlight
    let options: [KitoSizeOption]
    @Binding var selection: String?
    let style: Style
    let error: String?
    let shakeTrigger: Int
    let tint: Color?
    let onSizeGuide: (() -> Void)?
    let onNotifyMe: ((KitoProductSize) -> Void)?
    @State private var shakes: CGFloat = 0
    @State private var notified: Set<String> = []

    public init(
        _ options: [KitoSizeOption],
        selection: Binding<String?>,
        style: Style = .grid,
        error: String? = nil,
        shakeTrigger: Int = 0,
        tint: Color? = nil,
        onSizeGuide: (() -> Void)? = nil,
        onNotifyMe: ((KitoProductSize) -> Void)? = nil
    ) {
        self.options = options
        _selection = selection
        self.style = style
        self.error = error
        self.shakeTrigger = shakeTrigger
        self.tint = tint
        self.onSizeGuide = onSizeGuide
        self.onNotifyMe = onNotifyMe
    }

    private var palette: ProductPalette { ProductPalette(theme: theme, tint: tint) }
    private var selected: KitoSizeOption? { options.first { $0.id == selection } }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            header
            sizes.modifier(ShakeEffect(attempts: shakes))
            footer
        }
        .animation(ProductMotion.layout(reduceMotion), value: selection)
        .animation(ProductMotion.layout(reduceMotion), value: error)
        .onChange(of: error) { _, newValue in
            if newValue != nil { shake() }
        }
        .onChange(of: shakeTrigger) { _, _ in
            if error != nil { shake() }
        }
    }

    private func shake() {
        guard !reduceMotion else { return }
        withAnimation(.linear(duration: 0.4)) { shakes += 1 }
    }

    private var header: some View {
        HStack {
            EyebrowText("Size", color: error == nil ? nil : theme.colors.danger)
            if let selected {
                Text(selected.size.label)
                    .font(theme.typography.label)
                    .foregroundStyle(theme.colors.onBackground)
            }
            Spacer()
            if let onSizeGuide {
                Button(action: onSizeGuide) {
                    Label("Size guide", systemImage: "ruler")
                        .font(theme.typography.caption.weight(.medium))
                        .foregroundStyle(theme.colors.onBackground)
                        .underline()
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder private var sizes: some View {
        switch style {
        case .grid:
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: theme.spacing.sm), count: 4),
                      spacing: theme.spacing.sm) {
                ForEach(options) { cell($0) }
            }
        case .chips:
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.sm) {
                    ForEach(options) { cell($0).frame(minWidth: 56) }
                }
                .padding(.vertical, 2)
            }
            .scrollClipDisabled()
        }
    }

    private func cell(_ option: KitoSizeOption) -> some View {
        let isSelected = option.id == selection
        let isMissing = option.level == .unavailable
        return Button {
            guard !isMissing else { return }
            withAnimation(ProductMotion.select(reduceMotion)) { selection = option.id }
        } label: {
            SizeCellLabel(option: option, isSelected: isSelected, palette: palette, style: style)
                .background { cellBackground(isSelected: isSelected) }
                .overlay { cellBorder(option: option, isSelected: isSelected) }
        }
        .buttonStyle(ProductPressStyle(scale: 0.95))
        .disabled(isMissing)
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityLabel(option.size.label)
        .accessibilityValue(option.level == .inStock ? "" : option.level.message)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder private func cellBackground(isSelected: Bool) -> some View {
        if isSelected {
            cellShape.fill(palette.ink).matchedGeometryEffect(id: "size", in: highlight)
        } else {
            cellShape.fill(theme.colors.surface)
        }
    }

    private func cellBorder(option: KitoSizeOption, isSelected: Bool) -> some View {
        let color = error != nil ? theme.colors.danger.opacity(0.6) : palette.hairline
        return cellShape.strokeBorder(isSelected ? Color.clear : color, lineWidth: 1)
    }

    private var cellShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: style == .chips ? theme.radii.pill : theme.radii.sm, style: .continuous)
    }

    @ViewBuilder private var footer: some View {
        if let error {
            Label(error, systemImage: "exclamationmark.circle")
                .font(theme.typography.caption.weight(.medium))
                .foregroundStyle(theme.colors.danger)
                .transition(.opacity.combined(with: .move(edge: .top)))
        } else if let selected, selected.level == .soldOut {
            notifyRow(selected.size)
                .transition(.opacity.combined(with: .move(edge: .top)))
        } else if let selected, let hint = selected.level.hint(for: selected.size.label) {
            Label(hint, systemImage: "flame")
                .font(theme.typography.caption.weight(.medium))
                .foregroundStyle(selected.level.isUrgent ? theme.colors.danger : palette.muted)
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private func notifyRow(_ size: KitoProductSize) -> some View {
        let done = notified.contains(size.id)
        return HStack(spacing: theme.spacing.md) {
            Image(systemName: done ? "checkmark.circle.fill" : "bell")
                .foregroundStyle(done ? theme.colors.success : theme.colors.onBackground)
                .contentTransition(.symbolEffect(.replace))
            VStack(alignment: .leading, spacing: 2) {
                Text(done ? "We'll let you know" : "\(size.label) is sold out")
                    .font(theme.typography.label)
                    .foregroundStyle(theme.colors.onBackground)
                Text(done ? "You'll hear from us when \(size.label) is back." : "Get an alert when it's back.")
                    .font(theme.typography.caption)
                    .foregroundStyle(palette.muted)
            }
            Spacer()
            if !done {
                Button("Notify me") {
                    withAnimation(ProductMotion.select(reduceMotion)) { _ = notified.insert(size.id) }
                    onNotifyMe?(size)
                }
                .font(theme.typography.caption.weight(.semibold))
                .foregroundStyle(palette.onInk)
                .padding(.horizontal, 14)
                .frame(minHeight: 34)
                .background(palette.ink, in: Capsule())
                .buttonStyle(ProductPressStyle())
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surfaceMuted, in: RoundedRectangle(cornerRadius: theme.radii.md, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct SizeCellLabel: View {
    @Environment(\.kitoTheme) private var theme
    let option: KitoSizeOption
    let isSelected: Bool
    let palette: ProductPalette
    let style: KitoSizePicker.Style

    var body: some View {
        VStack(spacing: 1) {
            Text(option.size.label)
                .font(theme.typography.label)
                .strikethrough(option.level == .unavailable, color: palette.faint)
            if let detail = option.size.detail, style == .grid {
                Text(detail).font(.system(size: 9)).opacity(0.7)
            }
        }
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity, minHeight: 44)
        .padding(.horizontal, style == .chips ? theme.spacing.md : 0)
        .overlay(alignment: .topTrailing) { lowDot }
        .overlay { soldOutSlash }
    }

    private var foreground: Color {
        if isSelected { return palette.onInk }
        switch option.level {
        case .unavailable: return palette.faint
        case .soldOut: return palette.muted
        default: return theme.colors.onBackground
        }
    }

    @ViewBuilder private var lowDot: some View {
        if case .low = option.level {
            Circle().fill(theme.colors.danger).frame(width: 5, height: 5).padding(6)
        }
    }

    @ViewBuilder private var soldOutSlash: some View {
        if option.level == .soldOut {
            SlashShape()
                .stroke(isSelected ? palette.onInk.opacity(0.5) : palette.faint, lineWidth: 0.8)
                .padding(8)
        }
    }
}
