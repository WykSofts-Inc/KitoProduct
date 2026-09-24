//
//  KitoProduct+Cart.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation
import KitoCart

public extension KitoProduct {
    /// A `KitoCart` line for this product in a variant: a line id that's unique to this product and
    /// variant, the variant's price, the picture for its colour and a subtitle such as "Sand · UK 8".
    ///
    /// Photos from a URL go in `imageURL`. Drawn artwork is remembered for the line too, so
    /// `KitoProductCartThumbnail(item)` (or `item.productMedia`) can draw it in the cart.
    ///
    /// ```swift
    /// KitoProductDetailView(product: runner) { product, variant in
    ///     cart.add(product.cartItem(for: variant))
    /// }
    /// ```
    func cartItem(for variant: KitoProductVariant, quantity: Int = 1) -> KitoCartItem {
        let lineID = cartLineID(for: variant)
        let picture = cartMedia(for: variant)
        KitoProductCartMedia.register(picture, forLineID: lineID)
        return KitoCartItem(id: lineID,
                            name: name,
                            unitPrice: variant.price ?? price,
                            quantity: max(quantity, 1),
                            imageURL: picture?.imageURL,
                            subtitle: variantDescription(variant))
    }

    /// The cart line id for a variant. Always starts with the product id, so two products that
    /// share a colour and size never merge into one line: "runner-01-black-UK 8". A variant id that
    /// already starts with the product id ("runner-01~black~UK 8") is used as it is.
    func cartLineID(for variant: KitoProductVariant) -> String {
        let variantID = variant.id
        if variantID.isEmpty || variantID == id { return id }
        if variantID.hasPrefix(id), let next = variantID.dropFirst(id.count).first, Self.idSeparators.contains(next) {
            return variantID
        }
        return "\(id)-\(variantID)"
    }

    /// "Sand · UK 8", "Sand", "UK 8", or `nil` for a product without options.
    func variantDescription(_ variant: KitoProductVariant) -> String? {
        let parts = [color(variant.colorID)?.name, size(variant.sizeID)?.label].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// The still picture a cart line shows for a variant: the first photo or artwork in its colour
    /// (a video's poster counts), or `nil` when the product has none.
    func cartMedia(for variant: KitoProductVariant) -> KitoProductMedia? {
        for item in media(for: variant.colorID) {
            switch item.source {
            case .image, .artwork:
                return item
            case .video(_, let poster):
                if let poster { return .artwork(poster, colorID: item.colorID, accessibilityLabel: item.accessibilityLabel) }
            }
        }
        return nil
    }

    internal static let idSeparators: Set<Character> = ["-", "~", "/", ":", "_", "|", "."]
}

public extension KitoCartItem {
    /// The product picture for a line made with `KitoProduct.cartItem(for:)` — drawn artwork
    /// included — or the line's `imageURL` as a photo. `nil` when there's nothing to show.
    var productMedia: KitoProductMedia? {
        KitoProductCartMedia.media(forLineID: id) ?? imageURL.map { KitoProductMedia.image($0) }
    }
}

/// Remembers the picture of each cart line made by `KitoProduct.cartItem(for:)`, so offline
/// artwork (which has no URL) can be drawn in the cart. Register lines yourself when you rebuild a
/// saved cart without going through `cartItem(for:)`.
public enum KitoProductCartMedia {
    /// Remembers `media` for a cart line id. Passing `nil` forgets the line.
    public static func register(_ media: KitoProductMedia?, forLineID lineID: String) {
        store.set(media, for: lineID)
    }

    /// The picture remembered for a cart line id.
    public static func media(forLineID lineID: String) -> KitoProductMedia? {
        store.get(lineID)
    }

    private static let store = Store()

    private final class Store: @unchecked Sendable {
        private let lock = NSLock()
        private var media: [String: KitoProductMedia] = [:]

        func set(_ value: KitoProductMedia?, for key: String) {
            lock.lock()
            defer { lock.unlock() }
            media[key] = value
        }

        func get(_ key: String) -> KitoProductMedia? {
            lock.lock()
            defer { lock.unlock() }
            return media[key]
        }
    }
}
