//
//  KitoAddToBagBar.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// Where the add-to-bag button is in its little story.
public enum KitoAddToBagState: Hashable, Sendable {
    case idle
    case adding
    case added
    case soldOut
}

/// A sticky bottom bar with a wishlist heart and a capsule button that morphs from "Add to bag ·
/// KES 9,900" to a spinner to "Added ✓". Put it in `.safeAreaInset(edge: .bottom)`.
///
/// ```swift
/// .safeAreaInset(edge: .bottom) {
///     KitoAddToBagBar(price: "KES 9,900", state: state, isWishlisted: $saved) { add() }
/// }
/// ```
public struct KitoAddToBagBar: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let title: String
    let price: String?
    let state: KitoAddToBagState
    let isWishlisted: Binding<Bool>?
    let tint: Color?
    let action: () -> Void

    public init(
        title: String = "Add to bag",
        price: String? = nil,
        state: KitoAddToBagState = .idle,
        isWishlisted: Binding<Bool>? = nil,
        tint: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.price = price
        self.state = state
        self.isWishlisted = isWishlisted
        self.tint = tint
        self.action = action
    }

    private var palette: ProductPalette { ProductPalette(theme: theme, tint: tint) }

    public var body: some View {
        HStack(spacing: theme.spacing.md) {
            if let isWishlisted {
                KitoWishlistButton(isOn: isWishlisted, style: .outlined, size: 20, tint: tint)
                    .frame(width: 52, height: 52)
            }
            KitoAddToBagButton(title: title, price: price, state: state, tint: tint, action: action)
        }
        .padding(.horizontal, theme.spacing.lg)
        .padding(.top, theme.spacing.md)
        .padding(.bottom, theme.spacing.sm)
        .background {
            Rectangle()
                .fill(.regularMaterial)
                .overlay(alignment: .top) { Rectangle().fill(palette.hairline).frame(height: 0.5) }
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

/// The morphing capsule on its own, for use outside the bar.
public struct KitoAddToBagButton: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let title: String
    let price: String?
    let state: KitoAddToBagState
    let tint: Color?
    let action: () -> Void

    public init(title: String = "Add to bag", price: String? = nil, state: KitoAddToBagState = .idle,
                tint: Color? = nil, action: @escaping () -> Void) {
        self.title = title
        self.price = price
        self.state = state
        self.tint = tint
        self.action = action
    }

    private var palette: ProductPalette { ProductPalette(theme: theme, tint: tint) }

    public var body: some View {
        Button(action: action) {
            ZStack { label }
                .font(theme.typography.button)
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(background, in: Capsule())
                .overlay {
                    if state == .soldOut { Capsule().strokeBorder(palette.hairline, lineWidth: 1) }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(ProductPressStyle())
        .disabled(state == .adding || state == .soldOut)
        .animation(ProductMotion.select(reduceMotion), value: state)
        .sensoryFeedback(.success, trigger: state == .added)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder private var label: some View {
        switch state {
        case .idle:
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: "bag")
                Text(title)
                if let price {
                    Text("·").opacity(0.5)
                    Text(price).contentTransition(.numericText())
                }
            }
            .transition(morph)
        case .adding:
            ProgressView()
                .tint(palette.onInk)
                .transition(morph)
        case .added:
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: "checkmark")
                    .symbolEffect(.bounce, value: state)
                Text("Added")
            }
            .transition(morph)
        case .soldOut:
            Text("Sold out").transition(morph)
        }
    }

    private var morph: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.7)).combined(with: .offset(y: 6))
    }

    private var foreground: Color {
        switch state {
        case .soldOut: palette.muted
        case .added: .white
        default: palette.onInk
        }
    }

    private var background: Color {
        switch state {
        case .soldOut: theme.colors.surfaceMuted
        case .added: theme.colors.success
        default: palette.ink
        }
    }

    private var accessibilityText: String {
        switch state {
        case .idle: [title, price].compactMap { $0 }.joined(separator: ", ")
        case .adding: "Adding to bag"
        case .added: "Added to bag"
        case .soldOut: "Sold out"
        }
    }
}
