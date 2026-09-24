//
//  KitoStockLevel.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// When stock counts turn into "Selling fast" and "Only 2 left".
public struct KitoStockThresholds: Hashable, Sendable {
    /// At or below this many units the exact count is shown ("Only 2 left").
    public var low: Int
    /// At or below this many units (and above `low`) the product is "Selling fast". `nil` turns it off.
    public var sellingFast: Int?

    public init(low: Int = 3, sellingFast: Int? = 10) {
        self.low = max(low, 1)
        self.sellingFast = sellingFast.map { max($0, self.low) }
    }

    public static let standard = KitoStockThresholds()
}

/// How much of something is left, as the customer should hear it.
public enum KitoStockLevel: Hashable, Sendable {
    case inStock
    /// Above the low threshold but running down.
    case sellingFast(Int)
    /// This many left, at or below the low threshold. `low(1)` reads "Last one".
    case low(Int)
    case soldOut
    /// This combination isn't made at all (a size that doesn't exist in this colour).
    case unavailable

    /// The level for a stock count. `nil` means stock isn't tracked, which reads as in stock.
    public static func level(for stock: Int?, thresholds: KitoStockThresholds = .standard) -> KitoStockLevel {
        guard let stock else { return .inStock }
        if stock <= 0 { return .soldOut }
        if stock <= thresholds.low { return .low(stock) }
        if let fast = thresholds.sellingFast, stock <= fast { return .sellingFast(stock) }
        return .inStock
    }

    /// Whether it can be added to the bag.
    public var isPurchasable: Bool {
        switch self {
        case .inStock, .sellingFast, .low: true
        case .soldOut, .unavailable: false
        }
    }

    /// Whether the level is worth drawing attention to.
    public var isUrgent: Bool {
        switch self {
        case .low, .sellingFast: true
        default: false
        }
    }

    /// "In stock", "Selling fast", "Only 2 left", "Last one", "Sold out", "Unavailable".
    public var message: String {
        switch self {
        case .inStock: "In stock"
        case .sellingFast: "Selling fast"
        case .low(1): "Last one"
        case .low(let count): "Only \(count) left"
        case .soldOut: "Sold out"
        case .unavailable: "Unavailable"
        }
    }

    /// A hint for a chosen size: "Only 2 left in UK 8", or `nil` when there's nothing to say.
    public func hint(for sizeLabel: String) -> String? {
        switch self {
        case .low(1): "Last one in \(sizeLabel)"
        case .low(let count): "Only \(count) left in \(sizeLabel)"
        case .sellingFast: "\(sizeLabel) is selling fast"
        case .soldOut: "\(sizeLabel) is sold out"
        case .inStock, .unavailable: nil
        }
    }
}
