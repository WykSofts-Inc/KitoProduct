//
//  KitoVariantMatrix.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// A size as offered for one colour: whether it exists, how much is left, and its SKU.
public struct KitoSizeOption: Identifiable, Hashable, Sendable {
    public var size: KitoProductSize
    public var level: KitoStockLevel
    /// The SKU, or `nil` when this size isn't made in the colour.
    public var variant: KitoProductVariant?

    public var id: String { size.id }

    public init(size: KitoProductSize, level: KitoStockLevel, variant: KitoProductVariant? = nil) {
        self.size = size
        self.level = level
        self.variant = variant
    }
}

/// A colour as offered: its swatch and whether any size is left.
public struct KitoColorOption: Identifiable, Hashable, Sendable {
    public var color: KitoProductColor
    public var isSoldOut: Bool

    public var id: String { color.id }

    public init(color: KitoProductColor, isSoldOut: Bool = false) {
        self.color = color
        self.isSoldOut = isSoldOut
    }
}

/// Answers "which sizes exist in this colour, and which are left?" for a product's variants.
///
/// A variant with no colour applies to every colour, and one with no size to every size. A
/// product with no variants at all is treated as always available.
///
/// ```swift
/// let matrix = KitoVariantMatrix(product)
/// matrix.sizeOptions(for: "sand")      // every size, each .inStock, .low(2), .soldOut or .unavailable
/// matrix.isSoldOut(color: "olive")     // true when nothing is left in olive
/// matrix.validate(selection)           // .success(variant) or .failure(.chooseSize)
/// ```
public struct KitoVariantMatrix: Sendable {
    public let product: KitoProduct
    public var thresholds: KitoStockThresholds

    public init(_ product: KitoProduct, thresholds: KitoStockThresholds = .standard) {
        self.product = product
        self.thresholds = thresholds
    }

    // MARK: Lookup

    /// Variants that belong to a colour. With `nil`, every variant.
    public func variants(for colorID: String?) -> [KitoProductVariant] {
        guard let colorID else { return product.variants }
        return product.variants.filter { $0.colorID == nil || $0.colorID == colorID }
    }

    /// The SKU for a colour and size. A product without variants gets a stand-in with no stock limit.
    public func variant(color colorID: String?, size sizeID: String?) -> KitoProductVariant? {
        if product.variants.isEmpty {
            return KitoProductVariant(id: [product.id, colorID, sizeID].compactMap { $0 }.joined(separator: "-"),
                                      colorID: colorID, sizeID: sizeID)
        }
        return product.variants.first { variant in
            Self.matches(variant.colorID, colorID) && Self.matches(variant.sizeID, sizeID)
        }
    }

    /// Only the sizes that are made in this colour, in display order.
    public func sizes(for colorID: String?) -> [KitoProductSize] {
        sizeOptions(for: colorID).filter { $0.level != .unavailable }.map(\.size)
    }

    /// Every size of the product with its stock level in this colour. With a `nil` colour, stock is
    /// added up across colours.
    public func sizeOptions(for colorID: String?) -> [KitoSizeOption] {
        product.sizes.map { option(for: $0, colorID: colorID) }
    }

    /// Every colour, marked sold out when none of its sizes are left.
    public func colorOptions() -> [KitoColorOption] {
        product.colors.map { KitoColorOption(color: $0, isSoldOut: isSoldOut(color: $0.id)) }
    }

    /// The stock level of one combination.
    public func stockLevel(color colorID: String?, size sizeID: String?) -> KitoStockLevel {
        if let sizeID, let size = product.size(sizeID) {
            return option(for: size, colorID: colorID).level
        }
        let pool = variants(for: colorID)
        if product.variants.isEmpty { return .inStock }
        if pool.isEmpty { return .unavailable }
        return KitoStockLevel.level(for: Self.totalStock(pool), thresholds: thresholds)
    }

    /// Whether nothing is left in a colour.
    public func isSoldOut(color colorID: String) -> Bool {
        guard !product.variants.isEmpty else { return false }
        return !variants(for: colorID).contains { $0.isInStock }
    }

    /// Whether nothing at all is left.
    public var isSoldOut: Bool {
        !product.variants.isEmpty && !product.variants.contains { $0.isInStock }
    }

    // MARK: Selection

    /// Where a product page starts: the first colour with stock, and the size already chosen when
    /// there's only one.
    public func initialSelection() -> KitoProductSelection {
        let color = product.colors.first { !isSoldOut(color: $0.id) } ?? product.colors.first
        var selection = KitoProductSelection(colorID: color?.id)
        let made = sizes(for: color?.id)
        if made.count == 1 { selection.sizeID = made[0].id }
        return selection
    }

    /// The selection after choosing a colour. The size is kept when it's made in the new colour
    /// (even if sold out, so "Notify me" still makes sense) and cleared when it isn't.
    public func selecting(color colorID: String, in selection: KitoProductSelection) -> KitoProductSelection {
        var next = selection
        next.colorID = colorID
        if let sizeID = selection.sizeID, !sizes(for: colorID).contains(where: { $0.id == sizeID }) {
            next.sizeID = nil
        }
        let made = sizes(for: colorID)
        if next.sizeID == nil, made.count == 1 { next.sizeID = made[0].id }
        return next
    }

    /// The SKU to add to the bag, or what's missing: "Choose a colour", "Choose a size", sold out.
    public func validate(_ selection: KitoProductSelection) -> Result<KitoProductVariant, KitoSelectionIssue> {
        if !product.colors.isEmpty, product.color(selection.colorID) == nil { return .failure(.chooseColor) }
        if !product.sizes.isEmpty, product.size(selection.sizeID) == nil { return .failure(.chooseSize) }
        guard let variant = variant(color: selection.colorID, size: selection.sizeID) else {
            return .failure(.unavailable)
        }
        let level = stockLevel(color: selection.colorID, size: selection.sizeID)
        guard level.isPurchasable else { return .failure(level == .unavailable ? .unavailable : .soldOut) }
        return .success(variant)
    }

    /// The price for a selection: the variant's own price when it has one, else the product's.
    public func price(for selection: KitoProductSelection) -> Decimal {
        variant(color: selection.colorID, size: selection.sizeID)?.price ?? product.price
    }

    // MARK: Helpers

    private func option(for size: KitoProductSize, colorID: String?) -> KitoSizeOption {
        if product.variants.isEmpty {
            return KitoSizeOption(size: size, level: .inStock, variant: variant(color: colorID, size: size.id))
        }
        let pool = variants(for: colorID).filter { $0.sizeID == nil || $0.sizeID == size.id }
        guard !pool.isEmpty else { return KitoSizeOption(size: size, level: .unavailable) }
        let level = KitoStockLevel.level(for: Self.totalStock(pool), thresholds: thresholds)
        let sku = colorID == nil && pool.count > 1 ? nil : pool.first
        return KitoSizeOption(size: size, level: level, variant: sku)
    }

    /// The sum of stock, or `nil` when any variant doesn't track it (so it never runs out).
    private static func totalStock(_ variants: [KitoProductVariant]) -> Int? {
        var total = 0
        for variant in variants {
            guard let stock = variant.stock else { return nil }
            total += max(stock, 0)
        }
        return total
    }

    private static func matches(_ value: String?, _ wanted: String?) -> Bool {
        value == nil || value == wanted
    }
}

/// What the customer has picked on a product page.
public struct KitoProductSelection: Hashable, Sendable {
    public var colorID: String?
    public var sizeID: String?
    public var quantity: Int

    public init(colorID: String? = nil, sizeID: String? = nil, quantity: Int = 1) {
        self.colorID = colorID
        self.sizeID = sizeID
        self.quantity = max(quantity, 1)
    }
}

/// Why a selection can't go in the bag yet.
public enum KitoSelectionIssue: Error, Hashable, Sendable {
    case chooseColor
    case chooseSize
    case soldOut
    case unavailable

    /// "Choose a colour", "Choose a size", "This size is sold out", "Not available in this colour".
    public var message: String {
        switch self {
        case .chooseColor: "Choose a colour"
        case .chooseSize: "Choose a size"
        case .soldOut: "This size is sold out"
        case .unavailable: "Not available in this colour"
        }
    }
}
