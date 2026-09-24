//
//  KitoSizeGuide.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// A size chart with measuring tips and what customers say about the fit.
public struct KitoSizeGuide: Hashable, Sendable {
    public var title: String
    /// Column headings after the size column ("Chest", "Waist", "Hip").
    public var measurements: [String]
    public var rows: [KitoSizeGuideRow]
    /// Measurements in the table are in centimetres; the sheet can show them in inches too.
    public var allowsInches: Bool
    public var howToMeasure: [KitoMeasureStep]
    public var fit: KitoFitFeedback?

    public init(
        title: String = "Size guide",
        measurements: [String],
        rows: [KitoSizeGuideRow],
        allowsInches: Bool = true,
        howToMeasure: [KitoMeasureStep] = [],
        fit: KitoFitFeedback? = nil
    ) {
        self.title = title
        self.measurements = measurements
        self.rows = rows
        self.allowsInches = allowsInches
        self.howToMeasure = howToMeasure
        self.fit = fit
    }

    /// A measurement as text in the chosen unit: 96 cm reads "96" or "37.8".
    public static func format(_ centimetres: Double, inches: Bool) -> String {
        let value = inches ? centimetres / 2.54 : centimetres
        let rounded = (value * 10).rounded() / 10
        if rounded == rounded.rounded() { return String(Int(rounded)) }
        return String(format: "%.1f", rounded)
    }
}

/// One row of a size chart. `values` are in centimetres, one per measurement column.
public struct KitoSizeGuideRow: Identifiable, Hashable, Sendable {
    public var id: String { sizeID }
    /// The `KitoProductSize.id` this row describes, so the chosen size is highlighted.
    public var sizeID: String
    public var label: String
    public var values: [Double]

    public init(_ sizeID: String, label: String? = nil, values: [Double]) {
        self.sizeID = sizeID
        self.label = label ?? sizeID
        self.values = values
    }
}

/// A "how to measure" tip.
public struct KitoMeasureStep: Identifiable, Hashable, Sendable {
    public var id: String { title }
    public var title: String
    public var detail: String
    public var systemImage: String

    public init(_ title: String, detail: String, systemImage: String = "ruler") {
        self.title = title
        self.detail = detail
        self.systemImage = systemImage
    }
}

/// How the product fits according to customers: -1 runs small, 0 true to size, +1 runs large.
public struct KitoFitFeedback: Hashable, Sendable {
    public var value: Double
    public var reviewCount: Int

    public init(value: Double, reviewCount: Int = 0) {
        self.value = min(max(value, -1), 1)
        self.reviewCount = max(reviewCount, 0)
    }

    /// Averages individual votes of -1, 0 or +1.
    public init(votes: [Int]) {
        let total = votes.reduce(0) { $0 + min(max($1, -1), 1) }
        self.init(value: votes.isEmpty ? 0 : Double(total) / Double(votes.count), reviewCount: votes.count)
    }

    /// "Runs small", "Runs slightly small", "True to size", "Runs slightly large", "Runs large".
    public var label: String {
        switch value {
        case ..<(-0.6): "Runs small"
        case ..<(-0.2): "Runs slightly small"
        case ...0.2: "True to size"
        case ...0.6: "Runs slightly large"
        default: "Runs large"
        }
    }

    /// Advice to go with the label.
    public var advice: String {
        switch value {
        case ..<(-0.6): "We suggest one size up."
        case ..<(-0.2): "Between sizes? Go up."
        case ...0.2: "Take your usual size."
        case ...0.6: "Between sizes? Go down."
        default: "We suggest one size down."
        }
    }

    /// The marker position on a 0…1 track.
    public var position: Double { (value + 1) / 2 }
}
