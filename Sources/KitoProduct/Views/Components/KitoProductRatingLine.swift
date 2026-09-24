//
//  KitoProductRatingLine.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// Stars, the average and the review count on one line: "★★★★☆ 4.6 · 214 reviews".
///
/// ```swift
/// KitoProductRatingLine(rating: 4.6, reviewCount: 214) { showReviews = true }
/// ```
public struct KitoProductRatingLine: View {
    @Environment(\.kitoTheme) private var theme
    let rating: Double
    let reviewCount: Int
    let starSize: CGFloat
    let tint: Color?
    let onTap: (() -> Void)?

    public init(rating: Double, reviewCount: Int, starSize: CGFloat = 12, tint: Color? = nil, onTap: (() -> Void)? = nil) {
        self.rating = min(max(rating, 0), 5)
        self.reviewCount = max(reviewCount, 0)
        self.starSize = starSize
        self.tint = tint
        self.onTap = onTap
    }

    public var body: some View {
        if let onTap {
            Button(action: onTap) { line }
                .buttonStyle(.plain)
                .accessibilityHint("Shows reviews")
        } else {
            line
        }
    }

    private var line: some View {
        HStack(spacing: theme.spacing.sm) {
            KitoStars(rating: rating, size: starSize, tint: tint)
            Text(rating.formatted(.number.precision(.fractionLength(1))))
                .font(theme.typography.label)
                .foregroundStyle(theme.colors.onBackground)
            Text(reviewText)
                .font(theme.typography.label.weight(.regular))
                .foregroundStyle(theme.colors.onBackground.opacity(0.55))
                .underline(onTap != nil, color: theme.colors.onBackground.opacity(0.25))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rated \(rating.formatted(.number.precision(.fractionLength(1)))) out of 5, \(reviewText)")
    }

    private var reviewText: String {
        reviewCount == 1 ? "1 review" : "\(reviewCount.formatted()) reviews"
    }
}

/// Five stars filled to a rating, including part-filled stars.
public struct KitoStars: View {
    @Environment(\.kitoTheme) private var theme
    let rating: Double
    let size: CGFloat
    let tint: Color?

    public init(rating: Double, size: CGFloat = 12, tint: Color? = nil) {
        self.rating = min(max(rating, 0), 5)
        self.size = size
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: size * 0.18) {
            ForEach(0..<5, id: \.self) { index in
                star(fill: min(max(rating - Double(index), 0), 1))
            }
        }
        .accessibilityHidden(true)
    }

    private func star(fill: Double) -> some View {
        ZStack(alignment: .leading) {
            Image(systemName: "star.fill")
                .font(.system(size: size))
                .foregroundStyle(theme.colors.onBackground.opacity(0.14))
            Image(systemName: "star.fill")
                .font(.system(size: size))
                .foregroundStyle(tint ?? theme.colors.onBackground)
                .mask(alignment: .leading) {
                    Rectangle().frame(width: size * 1.1 * CGFloat(fill))
                }
        }
    }
}
