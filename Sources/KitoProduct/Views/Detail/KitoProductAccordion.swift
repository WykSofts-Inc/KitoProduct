//
//  KitoProductAccordion.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// Hairline-separated sections that open one at a time: Details, Materials & care, Shipping &
/// returns.
///
/// ```swift
/// KitoProductAccordion(product.sections, initiallyExpanded: "Details")
/// ```
public struct KitoProductAccordion: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let sections: [KitoProductInfoSection]
    let allowsMultiple: Bool
    let tint: Color?
    @State private var expanded: Set<String>

    public init(_ sections: [KitoProductInfoSection], initiallyExpanded: String? = nil,
                allowsMultiple: Bool = false, tint: Color? = nil) {
        self.sections = sections
        self.allowsMultiple = allowsMultiple
        self.tint = tint
        _expanded = State(initialValue: initiallyExpanded.map { [$0] } ?? [])
    }

    private var palette: ProductPalette { ProductPalette(theme: theme, tint: tint) }

    public var body: some View {
        VStack(spacing: 0) {
            ForEach(sections) { section in
                item(section)
                Rectangle().fill(palette.hairline).frame(height: 0.5)
            }
        }
        .overlay(alignment: .top) { Rectangle().fill(palette.hairline).frame(height: 0.5) }
    }

    private func item(_ section: KitoProductInfoSection) -> some View {
        let isOpen = expanded.contains(section.id)
        return VStack(alignment: .leading, spacing: 0) {
            Button { toggle(section.id) } label: {
                HStack(spacing: theme.spacing.md) {
                    if let symbol = section.systemImage {
                        Image(systemName: symbol)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(palette.muted)
                            .frame(width: 20)
                    }
                    Text(section.title)
                        .font(theme.typography.bodyEmphasized)
                        .foregroundStyle(theme.colors.onBackground)
                    Spacer()
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(theme.colors.onBackground)
                        .rotationEffect(.degrees(isOpen ? 45 : 0))
                }
                .padding(.vertical, theme.spacing.lg)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(isOpen ? "Expanded" : "Collapsed")
            .accessibilityHint(isOpen ? "Collapses" : "Expands")
            if isOpen {
                content(section)
                    .padding(.bottom, theme.spacing.lg)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .clipped()
    }

    private func content(_ section: KitoProductInfoSection) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            if let body = section.body {
                Text(body)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.onBackground.opacity(0.75))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(section.bullets, id: \.self) { bullet in
                HStack(alignment: .firstTextBaseline, spacing: theme.spacing.sm) {
                    Circle().fill(palette.muted).frame(width: 3, height: 3).offset(y: -3)
                    Text(bullet)
                        .font(theme.typography.label.weight(.regular))
                        .foregroundStyle(theme.colors.onBackground.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func toggle(_ id: String) {
        withAnimation(ProductMotion.layout(reduceMotion)) {
            if expanded.contains(id) {
                expanded.remove(id)
            } else {
                if !allowsMultiple { expanded.removeAll() }
                expanded.insert(id)
            }
        }
    }
}
