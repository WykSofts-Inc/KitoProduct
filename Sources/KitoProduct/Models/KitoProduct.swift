//
//  KitoProduct.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// Everything a product page shows: who makes it, what it costs, how it's rated, its photos and
/// the colours and sizes it comes in.
///
/// ```swift
/// let runner = KitoProduct(
///     id: "runner-01", name: "Runner 01", brand: "Kora Athletics",
///     price: 9_900, compareAtPrice: 13_200, rating: 4.6, reviewCount: 214,
///     badges: [.bestseller],
///     media: [.artwork(.sneaker(primary: .black, accent: .white))],
///     colors: [KitoProductColor("black", name: "Black", swatch: .black)],
///     sizes: KitoProductSize.range(["UK 6", "UK 7", "UK 8", "UK 9"]),
///     variants: [KitoProductVariant(colorID: "black", sizeID: "UK 8", stock: 2)])
/// ```
public struct KitoProduct: Identifiable, Hashable, Sendable {
    public let id: String
    public var name: String
    public var brand: String
    /// What the customer pays now.
    public var price: Decimal
    /// The price before a sale. Shown struck through when it's higher than `price`.
    public var compareAtPrice: Decimal?
    public var currencyCode: String
    /// Average rating out of 5, or `nil` before the first review.
    public var rating: Double?
    public var reviewCount: Int
    public var badges: [KitoProductBadge]
    /// Photos, artwork and video, in gallery order. Media tagged with a colour only shows when
    /// that colour is picked.
    public var media: [KitoProductMedia]
    /// Frames for the 360° viewer, in rotation order. Empty when there's no spin.
    public var spinFrames: [KitoProductMedia]
    public var colors: [KitoProductColor]
    /// Every size the product is made in, in display order.
    public var sizes: [KitoProductSize]
    /// One entry per purchasable combination (a SKU) with its stock. Variants without an id of
    /// their own get one that starts with the product id.
    public var variants: [KitoProductVariant] {
        didSet { variants = variants.map { $0.scoped(to: id) } }
    }
    /// A short paragraph under the title.
    public var summary: String?
    /// The accordion under the buy box: details, materials and care, shipping and returns.
    public var sections: [KitoProductInfoSection]

    public init(
        id: String,
        name: String,
        brand: String,
        price: Decimal,
        compareAtPrice: Decimal? = nil,
        currencyCode: String = "KES",
        rating: Double? = nil,
        reviewCount: Int = 0,
        badges: [KitoProductBadge] = [],
        media: [KitoProductMedia] = [],
        spinFrames: [KitoProductMedia] = [],
        colors: [KitoProductColor] = [],
        sizes: [KitoProductSize] = [],
        variants: [KitoProductVariant] = [],
        summary: String? = nil,
        sections: [KitoProductInfoSection] = []
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.price = price
        self.compareAtPrice = compareAtPrice
        self.currencyCode = currencyCode
        self.rating = rating
        self.reviewCount = reviewCount
        self.badges = badges
        self.media = media
        self.spinFrames = spinFrames
        self.colors = colors
        self.sizes = sizes
        self.variants = variants.map { $0.scoped(to: id) }
        self.summary = summary
        self.sections = sections
    }

    /// Whether the product is on sale: a compare-at price above the current price.
    public var isOnSale: Bool {
        KitoPriceMath.discountPercent(price: price, compareAt: compareAtPrice) != nil
    }

    /// Media for a colour: everything tagged with that colour plus everything untagged. Falls back
    /// to all media when nothing matches, so the gallery is never empty.
    public func media(for colorID: String?) -> [KitoProductMedia] {
        let matching = media.filter { $0.colorID == nil || $0.colorID == colorID }
        return matching.isEmpty ? media : matching
    }

    /// The colour with this id.
    public func color(_ id: String?) -> KitoProductColor? {
        guard let id else { return nil }
        return colors.first { $0.id == id }
    }

    /// The size with this id.
    public func size(_ id: String?) -> KitoProductSize? {
        guard let id else { return nil }
        return sizes.first { $0.id == id }
    }

    /// The total units in stock across every variant, or `nil` when no variant tracks stock.
    public var totalStock: Int? {
        let tracked = variants.compactMap(\.stock)
        return tracked.isEmpty ? nil : tracked.reduce(0, +)
    }
}

/// A section of the product accordion.
public struct KitoProductInfoSection: Identifiable, Hashable, Sendable {
    public var id: String { title }
    public var title: String
    public var body: String?
    /// Short lines shown as a list under the body ("100% organic cotton").
    public var bullets: [String]
    public var systemImage: String?

    public init(_ title: String, body: String? = nil, bullets: [String] = [], systemImage: String? = nil) {
        self.title = title
        self.body = body
        self.bullets = bullets
        self.systemImage = systemImage
    }
}
