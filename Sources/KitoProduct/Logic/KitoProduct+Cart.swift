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
    /// A `KitoCart` line for this product in a variant: the variant id, the variant's price, the first
    /// photo URL for its colour and a subtitle such as "Sand · UK 8".
    ///
    /// ```swift
    /// KitoProductDetailView(product: runner) { product, variant in
    ///     cart.add(product.cartItem(for: variant))
    /// }
    /// ```
    func cartItem(for variant: KitoProductVariant, quantity: Int = 1) -> KitoCartItem {
        let photo = media(for: variant.colorID).lazy.compactMap(\.imageURL).first
        return KitoCartItem(id: variant.id.isEmpty ? id : variant.id,
                            name: name,
                            unitPrice: variant.price ?? price,
                            quantity: max(quantity, 1),
                            imageURL: photo,
                            subtitle: variantDescription(variant))
    }

    /// "Sand · UK 8", "Sand", "UK 8", or `nil` for a product without options.
    func variantDescription(_ variant: KitoProductVariant) -> String? {
        let parts = [color(variant.colorID)?.name, size(variant.sizeID)?.label].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
