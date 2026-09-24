//
//  ProductStyle.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// The colours every product view draws selection and buttons in. By default the "ink" is the
/// theme's text colour — black in light mode, white in dark — for a quiet, editorial look. A `tint`
/// replaces it.
struct ProductPalette {
    let theme: KitoTheme
    let tint: Color?

    var ink: Color { tint ?? theme.colors.onBackground }
    var onInk: Color { tint == nil ? theme.colors.background : .white }
    var muted: Color { theme.colors.onBackground.opacity(0.55) }
    var faint: Color { theme.colors.onBackground.opacity(0.35) }
    var hairline: Color { theme.colors.border }
}

enum ProductMotion {
    /// The spring used for selection: quick with a little overshoot.
    static let select = Animation.spring(response: 0.34, dampingFraction: 0.72)
    /// A softer spring for layout changes.
    static let layout = Animation.spring(response: 0.45, dampingFraction: 0.86)

    static func select(_ reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.18) : select
    }

    static func layout(_ reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : layout
    }
}

/// Small uppercase, letter-spaced text for section labels and brand names.
struct EyebrowText: View {
    @Environment(\.kitoTheme) private var theme
    let text: String
    var color: Color?

    init(_ text: String, color: Color? = nil) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(theme.typography.caption.weight(.semibold))
            .tracking(1.4)
            .foregroundStyle(color ?? theme.colors.onBackground.opacity(0.55))
    }
}

/// A side-to-side shake that plays whenever `attempts` changes.
struct ShakeEffect: GeometryEffect {
    var attempts: CGFloat
    var amplitude: CGFloat = 7

    var animatableData: CGFloat {
        get { attempts }
        set { attempts = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = amplitude * sin(attempts * .pi * 4)
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}

/// Scales a button down while pressed.
struct ProductPressStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// A diagonal line from bottom-left to top-right, for sold-out swatches and sizes.
struct SlashShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}
