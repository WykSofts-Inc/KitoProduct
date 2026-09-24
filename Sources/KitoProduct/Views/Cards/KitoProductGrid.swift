//
//  KitoProductGrid.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// A two-column grid of product cards that rise into place one after another. The staggered
/// layout drops the right column so the photos sit offset, like a lookbook.
///
/// ```swift
/// ScrollView {
///     KitoProductGrid(products, wishlist: $saved, onSelect: { open($0) },
///                     onQuickAdd: { product, variant in cart.add(product.cartItem(for: variant)) })
///         .padding()
/// }
/// ```
public struct KitoProductGrid: View {
    public enum Layout: Sendable, CaseIterable {
        case uniform
        case staggered
    }

    @Environment(\.kitoTheme) private var theme
    let products: [KitoProduct]
    let style: KitoProductCard.Style
    let layout: Layout
    let wishlist: Binding<Set<String>>?
    let tint: Color?
    let onSelect: ((KitoProduct) -> Void)?
    let onQuickAdd: ((KitoProduct, KitoProductVariant) -> Void)?

    public init(
        _ products: [KitoProduct],
        style: KitoProductCard.Style = .grid,
        layout: Layout = .uniform,
        wishlist: Binding<Set<String>>? = nil,
        tint: Color? = nil,
        onSelect: ((KitoProduct) -> Void)? = nil,
        onQuickAdd: ((KitoProduct, KitoProductVariant) -> Void)? = nil
    ) {
        self.products = products
        self.style = style == .horizontal ? .grid : style
        self.layout = layout
        self.wishlist = wishlist
        self.tint = tint
        self.onSelect = onSelect
        self.onQuickAdd = onQuickAdd
    }

    public var body: some View {
        switch layout {
        case .uniform:
            LazyVGrid(columns: [GridItem(.flexible(), spacing: theme.spacing.md, alignment: .top),
                                GridItem(.flexible(), spacing: theme.spacing.md, alignment: .top)],
                      spacing: theme.spacing.xl) {
                ForEach(Array(products.enumerated()), id: \.element.id) { index, product in
                    cell(product, index: index)
                }
            }
        case .staggered:
            HStack(alignment: .top, spacing: theme.spacing.md) {
                column(parity: 0)
                column(parity: 1).padding(.top, theme.spacing.xxl * 1.5)
            }
        }
    }

    private func column(parity: Int) -> some View {
        LazyVStack(spacing: theme.spacing.xl) {
            ForEach(Array(products.enumerated()).filter { $0.offset % 2 == parity }, id: \.element.id) { index, product in
                cell(product, index: index)
            }
        }
    }

    private func cell(_ product: KitoProduct, index: Int) -> some View {
        KitoProductCard(product, style: style, isWishlisted: binding(for: product), tint: tint,
                        onQuickAdd: onQuickAdd, onSelect: onSelect.map { select in { select(product) } })
            .modifier(StaggeredAppear(index: index))
    }

    private func binding(for product: KitoProduct) -> Binding<Bool>? {
        guard let wishlist else { return nil }
        return Binding(
            get: { wishlist.wrappedValue.contains(product.id) },
            set: { isOn in
                if isOn { wishlist.wrappedValue.insert(product.id) } else { wishlist.wrappedValue.remove(product.id) }
            }
        )
    }
}

/// Fades and lifts a view in on first appearance, delayed by its position.
struct StaggeredAppear: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let index: Int
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 28)
            .scaleEffect(shown || reduceMotion ? 1 : 0.97, anchor: .top)
            .onAppear {
                guard !shown else { return }
                let delay = Double(min(index, 8)) * 0.06
                withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.55, dampingFraction: 0.82).delay(delay)) {
                    shown = true
                }
            }
    }
}
