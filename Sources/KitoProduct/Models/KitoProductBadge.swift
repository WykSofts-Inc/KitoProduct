//
//  KitoProductBadge.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// A small label over a product image or next to its name.
public struct KitoProductBadge: Identifiable, Hashable, Sendable {
    public enum Kind: Hashable, Sendable {
        case new
        case bestseller
        case lowStock
        case eco
        case sale
        case exclusive
        case custom
    }

    public var id: String { "\(kind)-\(text)" }
    public var kind: Kind
    public var text: String
    public var systemImage: String?

    public init(_ text: String, kind: Kind = .custom, systemImage: String? = nil) {
        self.text = text
        self.kind = kind
        self.systemImage = systemImage
    }

    public static let new = KitoProductBadge("New", kind: .new)
    public static let bestseller = KitoProductBadge("Bestseller", kind: .bestseller, systemImage: "star.fill")
    public static let lowStock = KitoProductBadge("Low stock", kind: .lowStock, systemImage: "flame.fill")
    public static let eco = KitoProductBadge("Eco", kind: .eco, systemImage: "leaf.fill")
    public static let exclusive = KitoProductBadge("Exclusive", kind: .exclusive)

    /// "−25%".
    public static func sale(percent: Int) -> KitoProductBadge {
        KitoProductBadge("−\(percent)%", kind: .sale)
    }
}
