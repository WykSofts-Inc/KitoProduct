//
//  KitoDeliveryEstimateRow.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// "Get it by Fri 25 Sep" with a live "Order within 3 h 12 min" countdown to the dispatch cut-off.
///
/// ```swift
/// KitoDeliveryEstimateRow(estimator: KitoDeliveryEstimator(minDays: 1, maxDays: 2, cutoffHour: 14),
///                         detail: "Free delivery over KES 5,000")
/// ```
public struct KitoDeliveryEstimateRow: View {
    @Environment(\.kitoTheme) private var theme
    let source: Source
    let detail: String?
    let systemImage: String
    let tint: Color?

    enum Source {
        case fixed(KitoDeliveryEstimate)
        case live(KitoDeliveryEstimator)
    }

    /// Recomputes the estimate every minute, so the countdown and dates stay right.
    public init(estimator: KitoDeliveryEstimator, detail: String? = nil, systemImage: String = "shippingbox", tint: Color? = nil) {
        self.source = .live(estimator)
        self.detail = detail
        self.systemImage = systemImage
        self.tint = tint
    }

    /// Shows an estimate you worked out yourself.
    public init(estimate: KitoDeliveryEstimate, detail: String? = nil, systemImage: String = "shippingbox", tint: Color? = nil) {
        self.source = .fixed(estimate)
        self.detail = detail
        self.systemImage = systemImage
        self.tint = tint
    }

    public var body: some View {
        switch source {
        case .fixed(let estimate):
            row(estimate)
        case .live(let estimator):
            TimelineView(.periodic(from: .now, by: 60)) { context in
                row(estimator.estimate(from: context.date))
            }
        }
    }

    private func row(_ estimate: KitoDeliveryEstimate) -> some View {
        HStack(alignment: .top, spacing: theme.spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(tint ?? theme.colors.onBackground)
                .frame(width: 36, height: 36)
                .background(theme.colors.surfaceMuted, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(estimate.title)
                    .font(theme.typography.bodyEmphasized)
                    .foregroundStyle(theme.colors.onBackground)
                if let countdown = estimate.countdown {
                    Text(countdown)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.success)
                        .contentTransition(.numericText())
                }
                if let detail {
                    Text(detail)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.onBackground.opacity(0.55))
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
