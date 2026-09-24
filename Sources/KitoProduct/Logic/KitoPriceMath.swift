//
//  KitoPriceMath.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// Sale, discount and instalment maths on `Decimal`, so no cents go missing to floating point.
public enum KitoPriceMath {
    /// The whole-number discount from `compareAt` down to `price`, rounded down so a sale is never
    /// overstated: 9,900 from 13,200 is 25; 7,999 from 9,999 is 20. `nil` when there's no discount
    /// of at least 1%.
    public static func discountPercent(price: Decimal, compareAt: Decimal?) -> Int? {
        guard let compareAt, compareAt > 0, compareAt > price else { return nil }
        let ratio = (compareAt - price) / compareAt * 100
        let percent = NSDecimalNumber(decimal: rounded(ratio, scale: 0, mode: .down)).intValue
        return percent >= 1 ? percent : nil
    }

    /// How much is saved, or `nil` when it isn't on sale.
    public static func savings(price: Decimal, compareAt: Decimal?) -> Decimal? {
        guard let compareAt, compareAt > price else { return nil }
        return compareAt - price
    }

    /// The price after taking `percent` off, to the nearest `increment` (1 for whole shillings).
    public static func salePrice(from original: Decimal, percentOff percent: Int, increment: Decimal = 1) -> Decimal {
        let clamped = Decimal(min(max(percent, 0), 100))
        let raw = original * (100 - clamped) / 100
        return roundedToIncrement(raw, increment: increment, mode: .plain)
    }

    /// One of `count` equal payments, rounded up to `increment` so the payments always cover the
    /// total: 9,900 over 4 is 2,475; 10,000 over 3 is 3,334.
    public static func instalment(of total: Decimal, count: Int, increment: Decimal = 1) -> Decimal {
        guard count > 0 else { return total }
        return roundedToIncrement(total / Decimal(count), increment: increment, mode: .up)
    }

    /// Rounds to a number of decimal places.
    public static func rounded(_ value: Decimal, scale: Int, mode: NSDecimalNumber.RoundingMode) -> Decimal {
        var input = value
        var output = Decimal()
        NSDecimalRound(&output, &input, scale, mode)
        return output
    }

    private static func roundedToIncrement(_ value: Decimal, increment: Decimal, mode: NSDecimalNumber.RoundingMode) -> Decimal {
        guard increment > 0 else { return value }
        return rounded(value / increment, scale: 0, mode: mode) * increment
    }
}

/// Money as text: "KES 9,900", "KES 1,250.50". Grouped with commas, and decimals only when there
/// are some, whatever the device language, so prices read the same everywhere.
public enum KitoMoney {
    public static func string(_ amount: Decimal, currencyCode: String = "KES") -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        formatter.decimalSeparator = "."
        let whole = KitoPriceMath.rounded(amount, scale: 0, mode: .plain) == amount
        formatter.minimumFractionDigits = whole ? 0 : 2
        formatter.maximumFractionDigits = whole ? 0 : 2
        let number = formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount)"
        return currencyCode.isEmpty ? number : "\(currencyCode) \(number)"
    }

    /// "or 4 × KES 2,475".
    public static func instalmentLine(total: Decimal, count: Int, currencyCode: String = "KES", increment: Decimal = 1) -> String {
        let each = KitoPriceMath.instalment(of: total, count: count, increment: increment)
        return "or \(count) × \(string(each, currencyCode: currencyCode))"
    }
}
