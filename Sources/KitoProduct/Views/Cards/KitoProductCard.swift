//
//  KitoProductCard.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// A product tile in four styles, with a wishlist heart and quick add. Quick add on a product with
/// sizes slides a frosted size strip up over the photo; without sizes it adds straight away.
///
/// ```swift
/// KitoProductCard(product, style: .grid, isWishlisted: $saved,
///                 onQuickAdd: { product, variant in cart.add(product.cartItem(for: variant)) },
///                 onSelect: { path.append(product) })
/// ```
public struct KitoProductCard: View {
    public enum Style: String, Sendable, CaseIterable {
        /// A tall full-bleed photo with the name set large underneath, for lookbooks.
        case editorial
        /// A small fixed-width tile for carousels such as "Complete the look".
        case compact
        /// The everyday two-column tile.
        case grid
        /// A row with the photo on the left, for lists and search results.
        case horizontal
    }

    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let product: KitoProduct
    let style: Style
    let isWishlisted: Binding<Bool>?
    let tint: Color?
    let onQuickAdd: ((KitoProduct, KitoProductVariant) -> Void)?
    let onSelect: (() -> Void)?

    @State private var sizesShown = false
    @State private var added = false

    public init(
        _ product: KitoProduct,
        style: Style = .grid,
        isWishlisted: Binding<Bool>? = nil,
        tint: Color? = nil,
        onQuickAdd: ((KitoProduct, KitoProductVariant) -> Void)? = nil,
        onSelect: (() -> Void)? = nil
    ) {
        self.product = product
        self.style = style
        self.isWishlisted = isWishlisted
        self.tint = tint
        self.onQuickAdd = onQuickAdd
        self.onSelect = onSelect
    }

    private var palette: ProductPalette { ProductPalette(theme: theme, tint: tint) }
    private var matrix: KitoVariantMatrix { KitoVariantMatrix(product) }
    private var colorID: String? { matrix.initialSelection().colorID }

    public var body: some View {
        Group {
            switch style {
            case .horizontal: horizontal
            default: vertical
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onSelect?() }
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: "Open") { onSelect?() }
    }

    // MARK: Layouts

    private var vertical: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            photo
                .aspectRatio(photoAspect, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: photoRadius, style: .continuous))
            info
                .padding(.horizontal, style == .editorial ? theme.spacing.xs : 0)
        }
        .frame(width: style == .compact ? 150 : nil)
    }

    private var horizontal: some View {
        HStack(alignment: .top, spacing: theme.spacing.md) {
            KitoProductMediaView(heroMedia)
                .frame(width: 96, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: theme.radii.md, style: .continuous))
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                if let badge = product.badges.first { KitoProductBadgeView(badge, tint: tint) }
                info
            }
            Spacer(minLength: 0)
            VStack(spacing: theme.spacing.sm) {
                if let isWishlisted { KitoWishlistButton(isOn: isWishlisted, size: 17, tint: tint) }
                if onQuickAdd != nil { quickAddButton }
            }
        }
        .overlay(alignment: .bottom) {
            if sizesShown { sizeStrip.padding(.leading, 108) }
        }
    }

    private var photo: some View {
        Color.clear
            .overlay { KitoProductMediaView(heroMedia) }
            .overlay(alignment: .topLeading) {
                if style != .compact, !product.badges.isEmpty {
                    KitoProductBadges(Array(product.badges.prefix(2)), style: .glass, tint: tint)
                        .padding(theme.spacing.sm)
                }
            }
            .overlay(alignment: .topTrailing) {
                if let isWishlisted {
                    KitoWishlistButton(isOn: isWishlisted, style: .glass, size: style == .compact ? 14 : 16, tint: tint)
                        .padding(theme.spacing.xs)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if onQuickAdd != nil, !sizesShown { quickAddButton.padding(theme.spacing.sm) }
            }
            .overlay(alignment: .bottom) {
                if sizesShown { sizeStrip.padding(theme.spacing.sm) }
            }
            .clipped()
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 3) {
            EyebrowText(product.brand)
                .lineLimit(1)
            Text(product.name)
                .font(nameFont)
                .foregroundStyle(theme.colors.onBackground)
                .lineLimit(style == .compact ? 1 : 2)
                .multilineTextAlignment(.leading)
            KitoPriceTag(product: product, size: style == .editorial ? .regular : .small, tint: tint)
                .padding(.top, 1)
            if style != .compact, product.colors.count > 1 { swatchDots }
        }
    }

    private var swatchDots: some View {
        HStack(spacing: 4) {
            ForEach(product.colors.prefix(4)) { color in
                SwatchFill(color: color, size: 10)
            }
            if product.colors.count > 4 {
                Text("+\(product.colors.count - 4)")
                    .font(theme.typography.caption)
                    .foregroundStyle(palette.muted)
            }
        }
        .padding(.top, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(product.colors.count) colours")
    }

    // MARK: Quick add

    private var quickAddButton: some View {
        Button(action: quickAdd) {
            Image(systemName: added ? "checkmark" : "plus")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(added ? .white : theme.colors.onSurface)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 34, height: 34)
                .background {
                    if added {
                        Circle().fill(theme.colors.success)
                    } else {
                        Circle().fill(.ultraThinMaterial)
                    }
                }
                .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
        }
        .buttonStyle(ProductPressStyle(scale: 0.88))
        .disabled(matrix.isSoldOut)
        .opacity(matrix.isSoldOut ? 0.4 : 1)
        .sensoryFeedback(.success, trigger: added)
        .accessibilityLabel(added ? "Added to bag" : "Quick add \(product.name)")
    }

    private var sizeStrip: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(matrix.sizeOptions(for: colorID)) { option in
                        sizeChip(option)
                    }
                }
                .padding(4)
            }
            Button {
                withAnimation(ProductMotion.layout(reduceMotion)) { sizesShown = false }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.colors.onSurface)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close sizes")
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: theme.radii.md, style: .continuous))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func sizeChip(_ option: KitoSizeOption) -> some View {
        let usable = option.level.isPurchasable
        return Button {
            add(color: colorID, size: option.id)
        } label: {
            Text(option.size.label)
                .font(theme.typography.caption.weight(.semibold))
                .strikethrough(!usable)
                .foregroundStyle(usable ? theme.colors.onSurface : theme.colors.onSurface.opacity(0.35))
                .padding(.horizontal, 9)
                .frame(minWidth: 34, minHeight: 28)
                .background(theme.colors.surface.opacity(usable ? 0.9 : 0.4),
                            in: RoundedRectangle(cornerRadius: theme.radii.sm, style: .continuous))
        }
        .buttonStyle(ProductPressStyle(scale: 0.92))
        .disabled(!usable)
        .accessibilityLabel(usable ? "Add size \(option.size.label)" : "\(option.size.label), \(option.level.message)")
    }

    private func quickAdd() {
        if matrix.sizes(for: colorID).count > 1 {
            withAnimation(ProductMotion.layout(reduceMotion)) { sizesShown = true }
        } else {
            add(color: colorID, size: matrix.sizes(for: colorID).first?.id)
        }
    }

    private func add(color: String?, size: String?) {
        let selection = KitoProductSelection(colorID: color, sizeID: size)
        guard case .success(let variant) = matrix.validate(selection) else { return }
        onQuickAdd?(product, variant)
        withAnimation(ProductMotion.select(reduceMotion)) {
            sizesShown = false
            added = true
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            withAnimation(ProductMotion.select(reduceMotion)) { added = false }
        }
    }

    // MARK: Metrics

    private var heroMedia: KitoProductMedia {
        product.media(for: colorID).first ?? KitoProductMedia.artwork(.tote(primary: .gray, accent: .white))
    }

    private var photoAspect: CGFloat {
        switch style {
        case .editorial: 2 / 3
        case .compact: 3 / 4
        case .grid, .horizontal: 4 / 5
        }
    }

    private var photoRadius: CGFloat {
        style == .editorial ? theme.radii.none : theme.radii.md
    }

    private var nameFont: Font {
        style == .editorial ? theme.typography.titleMedium : theme.typography.label.weight(.regular)
    }
}
