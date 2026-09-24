//
//  KitoPriceTag.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// A price with its sale treatment: the sale price, the old price struck through, the discount and
/// an instalments line such as "or 4 × KES 2,475".
///
/// ```swift
/// KitoPriceTag(price: 9_900, compareAt: 13_200, instalments: 4)
/// KitoPriceTag(price: product.price, size: .small)            // on a card
/// ```
public struct KitoPriceTag: View {
    public enum Size: Sendable, CaseIterable {
        case small
        case regular
        case large
    }

    @Environment(\.kitoTheme) private var theme
    let price: Decimal
    let compareAt: Decimal?
    let currencyCode: String
    let instalments: Int?
    let showsDiscount: Bool
    let size: Size
    let tint: Color?

    public init(
        price: Decimal,
        compareAt: Decimal? = nil,
        currencyCode: String = "KES",
        instalments: Int? = nil,
        showsDiscount: Bool = true,
        size: Size = .regular,
        tint: Color? = nil
    ) {
        self.price = price
        self.compareAt = compareAt
        self.currencyCode = currencyCode
        self.instalments = instalments
        self.showsDiscount = showsDiscount
        self.size = size
        self.tint = tint
    }

    /// The price tag for a product, with its compare-at price and currency.
    public init(product: KitoProduct, price: Decimal? = nil, instalments: Int? = nil, size: Size = .regular, tint: Color? = nil) {
        self.init(price: price ?? product.price, compareAt: product.compareAtPrice, currencyCode: product.currencyCode,
                  instalments: instalments, size: size, tint: tint)
    }

    private var discount: Int? { KitoPriceMath.discountPercent(price: price, compareAt: compareAt) }

    public var body: some View {
        VStack(alignment: .leading, spacing: size == .small ? 2 : theme.spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: theme.spacing.sm) {
                Text(KitoMoney.string(price, currencyCode: currencyCode))
                    .font(priceFont)
                    .foregroundStyle(discount == nil ? theme.colors.onBackground : (tint ?? theme.colors.danger))
                    .contentTransition(.numericText())
                if discount != nil, let compareAt {
                    Text(KitoMoney.string(compareAt, currencyCode: currencyCode))
                        .font(wasFont)
                        .strikethrough(true, color: theme.colors.onBackground.opacity(0.45))
                        .foregroundStyle(theme.colors.onBackground.opacity(0.45))
                }
                if showsDiscount, let discount, size != .small {
                    discountPill(discount)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            if let instalments, instalments > 1, size != .small {
                Text(KitoMoney.instalmentLine(total: price, count: instalments, currencyCode: currencyCode))
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.onBackground.opacity(0.6))
                    .contentTransition(.numericText())
            }
        }
        .animation(.snappy, value: price)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private func discountPill(_ percent: Int) -> some View {
        Text("−\(percent)%")
            .font(theme.typography.caption.weight(.bold))
            .foregroundStyle(tint ?? theme.colors.danger)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background((tint ?? theme.colors.danger).opacity(0.12), in: Capsule())
    }

    private var priceFont: Font {
        switch size {
        case .small: theme.typography.label
        case .regular: theme.typography.titleMedium
        case .large: theme.typography.titleLarge
        }
    }

    private var wasFont: Font {
        switch size {
        case .small: theme.typography.caption
        case .regular: theme.typography.body
        case .large: theme.typography.bodyEmphasized
        }
    }

    private var accessibilityText: String {
        var parts = [KitoMoney.string(price, currencyCode: currencyCode)]
        if let discount, let compareAt {
            parts.append("was \(KitoMoney.string(compareAt, currencyCode: currencyCode)), \(discount)% off")
        }
        if let instalments, instalments > 1 {
            let each = KitoPriceMath.instalment(of: price, count: instalments)
            parts.append("or \(instalments) payments of \(KitoMoney.string(each, currencyCode: currencyCode))")
        }
        return parts.joined(separator: ", ")
    }
}
