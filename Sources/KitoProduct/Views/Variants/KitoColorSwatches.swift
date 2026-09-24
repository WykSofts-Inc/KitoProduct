//
//  KitoColorSwatches.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// Round colour swatches with a ring that springs to the chosen one, a slash through sold-out
/// colours and a "Colour: Sand" label above.
///
/// ```swift
/// KitoColorSwatches(matrix.colorOptions(), selection: $colorID)
/// KitoColorSwatches(options, selection: $colorID, showsLabel: false, size: 22)   // on a card
/// ```
public struct KitoColorSwatches: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var ring
    let options: [KitoColorOption]
    @Binding var selection: String?
    let showsLabel: Bool
    let size: CGFloat
    let tint: Color?

    public init(_ options: [KitoColorOption], selection: Binding<String?>, showsLabel: Bool = true,
                size: CGFloat = 30, tint: Color? = nil) {
        self.options = options
        _selection = selection
        self.showsLabel = showsLabel
        self.size = size
        self.tint = tint
    }

    /// Swatches for a product's colours, sold-out ones marked.
    public init(product: KitoProduct, selection: Binding<String?>, showsLabel: Bool = true, size: CGFloat = 30, tint: Color? = nil) {
        self.init(KitoVariantMatrix(product).colorOptions(), selection: selection, showsLabel: showsLabel, size: size, tint: tint)
    }

    private var palette: ProductPalette { ProductPalette(theme: theme, tint: tint) }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            if showsLabel { label }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: size * 0.4) {
                    ForEach(options) { option in swatch(option) }
                }
                .padding(.vertical, size * 0.16)
                .padding(.horizontal, size * 0.16)
            }
            .scrollClipDisabled()
        }
    }

    private var label: some View {
        HStack(spacing: theme.spacing.xs) {
            EyebrowText("Colour")
            Text(selectedName)
                .font(theme.typography.label)
                .foregroundStyle(theme.colors.onBackground)
                .contentTransition(.opacity)
                .id(selectedName)
                .transition(.opacity.combined(with: .offset(y: 4)))
        }
        .animation(ProductMotion.select(reduceMotion), value: selectedName)
    }

    private var selectedName: String {
        guard let option = options.first(where: { $0.id == selection }) else { return "" }
        return option.isSoldOut ? "\(option.color.name) — sold out" : option.color.name
    }

    private func swatch(_ option: KitoColorOption) -> some View {
        let isSelected = option.id == selection
        return Button {
            withAnimation(ProductMotion.select(reduceMotion)) { selection = option.id }
        } label: {
            ZStack {
                if isSelected {
                    Circle()
                        .strokeBorder(palette.ink, lineWidth: 1.5)
                        .frame(width: size + 10, height: size + 10)
                        .matchedGeometryEffect(id: "ring", in: ring)
                }
                SwatchFill(color: option.color, size: size)
                    .opacity(option.isSoldOut ? 0.45 : 1)
                if option.isSoldOut {
                    SlashShape()
                        .stroke(theme.colors.onBackground.opacity(0.7), lineWidth: 1.2)
                        .frame(width: size * 0.72, height: size * 0.72)
                }
            }
            .frame(width: size + 10, height: size + 10)
            .scaleEffect(isSelected ? 1 : 0.94)
            .contentShape(Circle())
        }
        .buttonStyle(ProductPressStyle(scale: 0.9))
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityLabel(option.color.name)
        .accessibilityValue(option.isSoldOut ? "Sold out" : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// A swatch circle, split on the diagonal for two-tone colours, with a hairline so white shows.
struct SwatchFill: View {
    @Environment(\.kitoTheme) private var theme
    let color: KitoProductColor
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(color.swatch)
            if let second = color.secondarySwatch {
                HalfShape().fill(second)
            }
            Circle().fill(LinearGradient(colors: [.white.opacity(0.22), .clear, .black.opacity(0.12)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().strokeBorder(theme.colors.onBackground.opacity(0.12), lineWidth: 0.5)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

private struct HalfShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
