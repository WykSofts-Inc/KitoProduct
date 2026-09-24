//
//  KitoProductDetailModel.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import Observation
import KitoCore

/// The state behind a product page: what's selected, what's wrong with it, the add-to-bag button's
/// state, the wishlist and the bag count. `KitoProductDetailView` makes one for you; make your own
/// to read or drive it from outside.
///
/// ```swift
/// @State private var page = KitoProductDetailModel(runner)
/// KitoProductDetailView(model: page) { product, variant in cart.add(product.cartItem(for: variant)) }
/// page.selectColor("sand")
/// ```
@Observable
public final class KitoProductDetailModel: KitoViewModel {
    public private(set) var product: KitoProduct
    public private(set) var selection: KitoProductSelection
    /// Set when "Add to bag" was tapped with something missing.
    public private(set) var issue: KitoSelectionIssue?
    /// Goes up on every failed attempt, so the picker can shake again.
    public private(set) var failedAttempts = 0
    public private(set) var addState: KitoAddToBagState = .idle
    public var isWishlisted: Bool
    public private(set) var bagCount: Int
    public var galleryPage = 0
    public let thresholds: KitoStockThresholds

    public init(_ product: KitoProduct, isWishlisted: Bool = false, bagCount: Int = 0,
                thresholds: KitoStockThresholds = .standard) {
        self.product = product
        self.thresholds = thresholds
        self.isWishlisted = isWishlisted
        self.bagCount = max(bagCount, 0)
        self.selection = KitoVariantMatrix(product, thresholds: thresholds).initialSelection()
    }

    public var matrix: KitoVariantMatrix { KitoVariantMatrix(product, thresholds: thresholds) }

    // MARK: Derived

    public var selectedColor: KitoProductColor? { product.color(selection.colorID) }
    public var selectedSize: KitoProductSize? { product.size(selection.sizeID) }
    public var galleryMedia: [KitoProductMedia] { product.media(for: selection.colorID) }
    public var colorOptions: [KitoColorOption] { matrix.colorOptions() }
    public var sizeOptions: [KitoSizeOption] { matrix.sizeOptions(for: selection.colorID) }
    public var price: Decimal { matrix.price(for: selection) }

    /// The stock of what's chosen, or of the colour when no size is chosen yet.
    public var stockLevel: KitoStockLevel {
        matrix.stockLevel(color: selection.colorID, size: selection.sizeID)
    }

    /// What the bag button should show when it isn't mid-animation.
    public var restingState: KitoAddToBagState {
        if matrix.isSoldOut { return .soldOut }
        if selection.sizeID != nil, stockLevel == .soldOut { return .soldOut }
        return .idle
    }

    // MARK: Intents

    public func selectColor(_ id: String) {
        selection = matrix.selecting(color: id, in: selection)
        galleryPage = 0
        if issue == .chooseColor { issue = nil }
        if issue == .unavailable || issue == .soldOut { issue = nil }
        settle()
    }

    public func selectSize(_ id: String?) {
        selection.sizeID = id
        if issue == .chooseSize || issue == .soldOut { issue = nil }
        settle()
    }

    /// Checks the selection. Returns the variant and starts the "adding" state, or records what's
    /// missing and returns `nil`.
    @discardableResult
    public func addToBag() -> KitoProductVariant? {
        switch matrix.validate(selection) {
        case .failure(let problem):
            issue = problem
            failedAttempts += 1
            return nil
        case .success(let variant):
            issue = nil
            addState = .adding
            return variant
        }
    }

    /// Marks the item as in the bag and bumps the count.
    public func finishAdding() {
        addState = .added
        bagCount += selection.quantity
    }

    /// Returns the button to its resting state after "Added ✓".
    public func settle() {
        addState = restingState
    }

    /// Replaces the product, for example after a fresh stock fetch, keeping the selection where it
    /// still makes sense.
    public func update(_ product: KitoProduct) {
        self.product = product
        if product.color(selection.colorID) == nil {
            selection = matrix.initialSelection()
        } else if let colorID = selection.colorID {
            selection = matrix.selecting(color: colorID, in: selection)
        }
        settle()
    }
}
