//
//  KitoWishlistButton.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// A heart that fills with a bounce and a burst of sparks when saved.
///
/// ```swift
/// KitoWishlistButton(isOn: $saved)                         // plain heart
/// KitoWishlistButton(isOn: $saved, style: .glass)          // frosted circle, over a photo
/// KitoWishlistButton(isOn: $saved, style: .outlined)       // bordered circle, beside a button
/// ```
public struct KitoWishlistButton: View {
    public enum Style: Sendable, CaseIterable {
        case plain
        case glass
        case outlined
    }

    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var isOn: Bool
    let style: Style
    let size: CGFloat
    let tint: Color?
    let onChange: ((Bool) -> Void)?
    @State private var bursts = 0

    public init(isOn: Binding<Bool>, style: Style = .plain, size: CGFloat = 20, tint: Color? = nil,
                onChange: ((Bool) -> Void)? = nil) {
        _isOn = isOn
        self.style = style
        self.size = size
        self.tint = tint
        self.onChange = onChange
    }

    public var body: some View {
        Button(action: toggle) {
            ZStack {
                if !reduceMotion {
                    HeartBurst(color: fill, size: size)
                        .keyframeAnimator(initialValue: CGFloat(1), trigger: bursts) { burst, progress in
                            burst.environment(\.heartBurstProgress, progress)
                        } keyframes: { _ in
                            KeyframeTrack {
                                MoveKeyframe(CGFloat(0))
                                CubicKeyframe(CGFloat(1), duration: 0.6)
                            }
                        }
                }
                Image(systemName: isOn ? "heart.fill" : "heart")
                    .font(.system(size: size, weight: .medium))
                    .foregroundStyle(isOn ? fill : outline)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: bursts)
            }
            .frame(width: size * 2.2, height: size * 2.2)
            .background { background }
            .contentShape(Circle())
        }
        .buttonStyle(ProductPressStyle(scale: 0.9))
        .sensoryFeedback(.impact(weight: .light), trigger: isOn)
        .accessibilityLabel(isOn ? "Saved to wishlist" : "Save to wishlist")
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private var fill: Color { tint ?? theme.colors.danger }

    private var outline: Color {
        style == .glass ? theme.colors.onSurface : theme.colors.onBackground
    }

    @ViewBuilder private var background: some View {
        switch style {
        case .plain:
            Color.clear
        case .glass:
            Circle().fill(.ultraThinMaterial)
                .overlay(Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5))
        case .outlined:
            Circle().strokeBorder(theme.colors.border, lineWidth: 1)
        }
    }

    private func toggle() {
        let next = !isOn
        withAnimation(ProductMotion.select(reduceMotion)) { isOn = next }
        if next { bursts += 1 }
        onChange?(next)
    }
}

private struct HeartBurstProgressKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1
}

extension EnvironmentValues {
    var heartBurstProgress: CGFloat {
        get { self[HeartBurstProgressKey.self] }
        set { self[HeartBurstProgressKey.self] = newValue }
    }
}

/// A ring and eight sparks flying out from the heart; `progress` runs 0…1 and rests at 1 (hidden).
private struct HeartBurst: View {
    @Environment(\.heartBurstProgress) private var progress
    let color: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.7), lineWidth: max(size * 0.12 * (1 - progress), 0.01))
                .frame(width: size, height: size)
                .scaleEffect(0.4 + progress * 1.1)
            ForEach(0..<8, id: \.self) { index in
                spark(index)
            }
        }
        .opacity(progress >= 1 ? 0 : 1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func spark(_ index: Int) -> some View {
        let angle = Double(index) * .pi / 4
        let distance = size * (0.55 + 0.55 * progress)
        let dot = max(size * 0.22 * (1 - progress), 0.1)
        return Circle()
            .fill(index.isMultiple(of: 2) ? color : color.opacity(0.6))
            .frame(width: dot, height: dot)
            .offset(x: CGFloat(cos(angle)) * distance, y: CGFloat(sin(angle)) * distance)
    }
}
