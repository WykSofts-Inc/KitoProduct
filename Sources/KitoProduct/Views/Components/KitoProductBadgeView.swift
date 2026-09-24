//
//  KitoProductBadgeView.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// A small uppercase badge: New, Bestseller, Low stock, Eco, a sale percentage or your own text.
///
/// ```swift
/// KitoProductBadgeView(.new)
/// KitoProductBadgeView(.eco, style: .glass)          // over a photo
/// KitoProductBadges(product.badges)                   // a row of them
/// ```
public struct KitoProductBadgeView: View {
    public enum Style: Sendable, CaseIterable {
        /// Filled or tinted, for use on the page background.
        case solid
        /// Frosted, for use over a photo.
        case glass
    }

    @Environment(\.kitoTheme) private var theme
    let badge: KitoProductBadge
    let style: Style
    let tint: Color?

    public init(_ badge: KitoProductBadge, style: Style = .solid, tint: Color? = nil) {
        self.badge = badge
        self.style = style
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let symbol = badge.systemImage {
                Image(systemName: symbol).font(.system(size: 8, weight: .bold))
            }
            Text(badge.text.uppercased())
                .font(theme.typography.caption.weight(.semibold))
                .tracking(1.1)
                .lineLimit(1)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background { background }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(badge.text)
    }

    private var palette: ProductPalette { ProductPalette(theme: theme, tint: tint) }

    private var accent: Color {
        switch badge.kind {
        case .new, .exclusive, .custom: tint ?? theme.colors.onBackground
        case .bestseller: tint ?? theme.colors.warning
        case .lowStock, .sale: theme.colors.danger
        case .eco: theme.colors.success
        }
    }

    private var isFilled: Bool {
        badge.kind == .new || badge.kind == .sale
    }

    private var foreground: Color {
        if style == .glass { return isFilled ? .white : theme.colors.onSurface }
        if isFilled { return badge.kind == .new ? palette.onInk : .white }
        return badge.kind == .bestseller ? theme.colors.onBackground : accent
    }

    @ViewBuilder private var background: some View {
        let shape = RoundedRectangle(cornerRadius: theme.radii.sm * 0.6, style: .continuous)
        switch style {
        case .glass:
            if isFilled {
                shape.fill(accent.opacity(0.9))
            } else {
                shape.fill(.ultraThinMaterial)
            }
        case .solid:
            if isFilled {
                shape.fill(accent)
            } else if badge.kind == .exclusive || badge.kind == .custom {
                shape.strokeBorder(accent.opacity(0.6), lineWidth: 1)
            } else {
                shape.fill(accent.opacity(0.14))
            }
        }
    }
}

/// A row of badges.
public struct KitoProductBadges: View {
    @Environment(\.kitoTheme) private var theme
    let badges: [KitoProductBadge]
    let style: KitoProductBadgeView.Style
    let tint: Color?

    public init(_ badges: [KitoProductBadge], style: KitoProductBadgeView.Style = .solid, tint: Color? = nil) {
        self.badges = badges
        self.style = style
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: theme.spacing.xs) {
            ForEach(badges) { KitoProductBadgeView($0, style: style, tint: tint) }
        }
    }
}
