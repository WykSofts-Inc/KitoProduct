//
//  KitoProductSpinViewer.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// A 360° viewer from a sequence of frames: drag sideways to turn the product, let go to spin on
/// with momentum. It turns once by itself when it appears (not with Reduce Motion) to show it can.
///
/// ```swift
/// KitoProductSpinViewer(frames: product.spinFrames)
/// KitoProductSpinViewer(frames: KitoProductArtwork.sneaker(primary: .black, accent: .orange).spin(frames: 24))
/// ```
public struct KitoProductSpinViewer: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let frames: [KitoProductMedia]
    let aspectRatio: CGFloat
    let pointsPerFrame: CGFloat
    let autoplay: Bool
    let tint: Color?

    @State private var position: Double = 0
    @State private var dragStart: Double?
    @State private var hasInteracted = false
    @State private var spin: Task<Void, Never>?

    public init(frames: [KitoProductMedia], aspectRatio: CGFloat = 4 / 5, pointsPerFrame: CGFloat = 9,
                autoplay: Bool = true, tint: Color? = nil) {
        self.frames = frames
        self.aspectRatio = aspectRatio
        self.pointsPerFrame = max(pointsPerFrame, 1)
        self.autoplay = autoplay
        self.tint = tint
    }

    private var palette: ProductPalette { ProductPalette(theme: theme, tint: tint) }

    private var frameIndex: Int {
        guard !frames.isEmpty else { return 0 }
        let count = frames.count
        let rounded = Int(position.rounded())
        return ((rounded % count) + count) % count
    }

    public var body: some View {
        ZStack {
            if frames.isEmpty {
                theme.colors.surfaceMuted
            } else {
                KitoProductMediaView(frames[frameIndex], artwork: .live, playsVideo: false)
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .clipped()
        .overlay(alignment: .topLeading) { badge }
        .overlay(alignment: .bottom) { dial }
        .contentShape(Rectangle())
        .gesture(drag)
        .onAppear(perform: teaser)
        .onDisappear { spin?.cancel() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("360 degree view")
        .accessibilityValue("\(frameIndex * 360 / max(frames.count, 1)) degrees")
        .accessibilityAdjustableAction { direction in
            let step = Double(max(frames.count / 8, 1))
            position += direction == .increment ? step : -step
        }
    }

    private var badge: some View {
        HStack(spacing: 5) {
            Image(systemName: "rotate.3d")
                .font(.system(size: 11, weight: .semibold))
            Text("360°")
                .font(theme.typography.caption.weight(.semibold))
        }
        .foregroundStyle(theme.colors.onSurface)
        .padding(.horizontal, 10)
        .frame(height: 26)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(theme.spacing.md)
    }

    private var dial: some View {
        VStack(spacing: theme.spacing.sm) {
            if !hasInteracted {
                Label("Drag to turn", systemImage: "hand.draw")
                    .font(theme.typography.caption.weight(.medium))
                    .foregroundStyle(theme.colors.onSurface)
                    .padding(.horizontal, 12)
                    .frame(height: 28)
                    .background(.ultraThinMaterial, in: Capsule())
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
            SpinDial(progress: Double(frameIndex) / Double(max(frames.count, 1)), color: palette.ink)
                .frame(width: 120, height: 4)
        }
        .padding(.bottom, theme.spacing.lg)
        .accessibilityHidden(true)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                spin?.cancel()
                if dragStart == nil { dragStart = position }
                if !hasInteracted { withAnimation(.easeOut(duration: 0.25)) { hasInteracted = true } }
                position = (dragStart ?? 0) - Double(value.translation.width / pointsPerFrame)
            }
            .onEnded { value in
                dragStart = nil
                let fling = value.predictedEndTranslation.width - value.translation.width
                coast(frames: -Double(fling / pointsPerFrame) * 0.6)
            }
    }

    /// Keeps turning after a fling, slowing to a stop.
    private func coast(frames distance: Double) {
        guard !reduceMotion, abs(distance) >= 1 else { return }
        spin?.cancel()
        let steps = min(Int(abs(distance)), 48)
        let direction: Double = distance > 0 ? 1 : -1
        spin = Task { @MainActor in
            for step in 0..<steps {
                let delay = 16 + Double(step * step) * 60 / Double(max(steps * steps, 1)) * 2
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000))
                if Task.isCancelled { return }
                position += direction
            }
        }
    }

    private func teaser() {
        guard autoplay, !reduceMotion, !hasInteracted, frames.count > 1 else { return }
        spin?.cancel()
        let count = frames.count
        spin = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            for _ in 0..<count {
                try? await Task.sleep(nanoseconds: UInt64(1_800_000_000 / count))
                if Task.isCancelled { return }
                position += 1
            }
        }
    }
}

private struct SpinDial: View {
    let progress: Double
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(color.opacity(0.15))
                Capsule().fill(color).frame(width: 18)
                    .offset(x: (proxy.size.width - 18) * CGFloat(progress))
            }
        }
    }
}
