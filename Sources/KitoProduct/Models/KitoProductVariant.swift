//
//  KitoProductVariant.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

/// A colour option with its swatch. `secondarySwatch` draws a two-tone swatch split on the
/// diagonal, for colourways such as "Black / White".
public struct KitoProductColor: Identifiable, Hashable, Sendable {
    public let id: String
    public var name: String
    public var swatch: Color
    public var secondarySwatch: Color?

    public init(_ id: String, name: String, swatch: Color, secondarySwatch: Color? = nil) {
        self.id = id
        self.name = name
        self.swatch = swatch
        self.secondarySwatch = secondarySwatch
    }
}

/// A size option. `id` is what variants refer to; `label` is what's shown ("UK 8", "M", "38").
public struct KitoProductSize: Identifiable, Hashable, Sendable {
    public let id: String
    public var label: String
    /// A second line such as "EU 42" or "Fits 86–91 cm chest".
    public var detail: String?

    public init(_ id: String, label: String? = nil, detail: String? = nil) {
        self.id = id
        self.label = label ?? id
        self.detail = detail
    }

    /// Sizes whose id and label are the same text, in the order given.
    public static func range(_ labels: [String]) -> [KitoProductSize] {
        labels.map { KitoProductSize($0) }
    }
}

/// One purchasable combination of colour and size (a SKU).
///
/// Leave out `id` and one is made from the colour and size. Inside a `KitoProduct` that id is
/// prefixed with the product id ("runner-01-black-UK 8"), so every product's variants stay unique.
public struct KitoProductVariant: Identifiable, Hashable, Sendable {
    public let id: String
    public var colorID: String?
    public var sizeID: String?
    /// Units in stock. `nil` means stock isn't tracked, and the variant is always available.
    public var stock: Int?
    /// A price for this variant only, when it differs from the product's.
    public var price: Decimal?

    /// Whether `id` was made from the colour and size rather than given.
    var hasGeneratedID: Bool

    public init(id: String? = nil, colorID: String? = nil, sizeID: String? = nil, stock: Int? = nil, price: Decimal? = nil) {
        self.id = id ?? [colorID, sizeID].compactMap { $0 }.joined(separator: "-")
        self.hasGeneratedID = id == nil
        self.colorID = colorID
        self.sizeID = sizeID
        self.stock = stock
        self.price = price
    }

    /// This variant with a made-up id prefixed by the product id. Given ids are left alone.
    func scoped(to productID: String) -> KitoProductVariant {
        guard hasGeneratedID else { return self }
        let scopedID = [productID, colorID, sizeID].compactMap { $0 }.joined(separator: "-")
        return KitoProductVariant(id: scopedID, colorID: colorID, sizeID: sizeID, stock: stock, price: price)
    }

    public var isInStock: Bool { stock.map { $0 > 0 } ?? true }
}
