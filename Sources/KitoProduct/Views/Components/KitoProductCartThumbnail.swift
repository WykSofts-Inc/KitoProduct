//
//  KitoProductCartThumbnail.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore
import KitoCart

/// The product picture for a cart line — the photo or drawn artwork in the colour that was
/// chosen — for `KitoCartView`, `KitoCheckoutFlow` or your own cart rows. Falls back to a bag
/// symbol on a muted fill.
///
/// ```swift
/// KitoCartView(cart: cart, onCheckout: pay) { item in
///     KitoProductCartThumbnail(item)
/// }
/// ```
public struct KitoProductCartThumbnail: View {
    @Environment(\.kitoTheme) private var theme
    let item: KitoCartItem
    let placeholderSystemImage: String

    public init(_ item: KitoCartItem, placeholderSystemImage: String = "bag") {
        self.item = item
        self.placeholderSystemImage = placeholderSystemImage
    }

    public var body: some View {
        Group {
            if let media = item.productMedia {
                KitoProductMediaView(media, playsVideo: false)
            } else {
                theme.colors.surfaceMuted
                    .overlay(Image(systemName: placeholderSystemImage).foregroundStyle(theme.colors.onSurface.opacity(0.4)))
            }
        }
        .accessibilityHidden(true)
    }
}
