//
//  KitoProductArtworkView.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

/// Draws a `KitoProductArtwork` live, filling whatever frame it's given. Use
/// `KitoProductMediaView` in galleries; it caches a rendered bitmap instead.
public struct KitoProductArtworkView: View {
    let artwork: KitoProductArtwork

    public init(_ artwork: KitoProductArtwork) {
        self.artwork = artwork
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                ArtworkBackdrop(color: artwork.backdrop, angled: artwork.framing == .angled, width: proxy.size.width)
                ArtworkStage(artwork: artwork, canvas: proxy.size)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

// MARK: - Backdrop

private struct ArtworkBackdrop: View {
    let color: Color
    let angled: Bool
    let width: CGFloat

    var body: some View {
        ZStack {
            color
            LinearGradient(colors: [.white.opacity(0.35), .clear, .black.opacity(0.10)], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [.white.opacity(0.45), .clear], center: UnitPoint(x: 0.5, y: 0.42),
                           startRadius: 0, endRadius: max(width * 0.75, 1))
            if angled {
                Color.black.opacity(0.16)
                LinearGradient(colors: [.white.opacity(0.28), .clear], startPoint: .topLeading, endPoint: UnitPoint(x: 0.6, y: 0.6))
            }
        }
    }
}

// MARK: - Stage

private struct ArtworkStage: View {
    let artwork: KitoProductArtwork
    let canvas: CGSize

    private var metrics: ArtworkMetrics { ArtworkMetrics(kind: artwork.kind, canvas: canvas) }

    var body: some View {
        let metrics = metrics
        ZStack {
            FloorShadow(width: metrics.shadowWidth * spinShadowFactor, height: metrics.box.width * 0.07)
                .offset(y: metrics.shadowOffset)
            ArtworkObject(artwork: artwork, box: metrics.box)
                .scaleEffect(x: spinScale, y: 1)
                .offset(y: metrics.objectOffset)
        }
        .frame(width: canvas.width, height: canvas.height)
        .modifier(FramingModifier(framing: artwork.framing, anchor: metrics.detailAnchor))
    }

    private var spinScale: CGFloat {
        let value = CGFloat(cos(artwork.rotation * .pi / 180))
        let magnitude = max(abs(value), 0.28)
        return value < 0 ? -magnitude : magnitude
    }

    private var spinShadowFactor: CGFloat {
        max(abs(spinScale), 0.55)
    }
}

private struct FramingModifier: ViewModifier {
    let framing: KitoProductArtwork.Framing
    let anchor: UnitPoint

    func body(content: Content) -> some View {
        switch framing {
        case .full:
            content
        case .closeUp:
            content.scaleEffect(1.9, anchor: anchor)
        case .angled:
            content.rotationEffect(.degrees(-12)).scaleEffect(0.9)
        }
    }
}

private struct FloorShadow: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Ellipse()
            .fill(Color.black.opacity(0.30))
            .frame(width: max(width, 1), height: max(height, 1))
            .blur(radius: max(height * 0.5, 0.5))
    }
}

/// Where the object sits and how big it is for a canvas.
struct ArtworkMetrics {
    let box: CGSize
    let objectOffset: CGFloat
    let shadowOffset: CGFloat
    let shadowWidth: CGFloat
    let detailAnchor: UnitPoint

    init(kind: KitoProductArtwork.Kind, canvas: CGSize) {
        let shape = Self.shape(for: kind)
        let byWidth = canvas.width * shape.fraction
        let byHeight = canvas.height * 0.70 * shape.aspect
        let width = max(min(byWidth, byHeight), 1)
        let height = width / shape.aspect
        box = CGSize(width: width, height: height)
        objectOffset = -canvas.height * 0.03
        shadowOffset = objectOffset + height / 2 + width * shape.shadowGap
        shadowWidth = width * shape.shadowScale
        detailAnchor = shape.anchor
    }

    private struct Shape {
        let aspect: CGFloat
        let fraction: CGFloat
        let shadowScale: CGFloat
        let shadowGap: CGFloat
        let anchor: UnitPoint
    }

    private static func shape(for kind: KitoProductArtwork.Kind) -> Shape {
        switch kind {
        case .sneaker: Shape(aspect: 2.0, fraction: 0.86, shadowScale: 0.92, shadowGap: -0.01, anchor: UnitPoint(x: 0.72, y: 0.52))
        case .tote: Shape(aspect: 1.0, fraction: 0.64, shadowScale: 0.86, shadowGap: -0.01, anchor: UnitPoint(x: 0.5, y: 0.45))
        case .dress: Shape(aspect: 0.62, fraction: 0.56, shadowScale: 0.7, shadowGap: 0.10, anchor: UnitPoint(x: 0.5, y: 0.36))
        case .jacket: Shape(aspect: 1.0, fraction: 0.76, shadowScale: 0.62, shadowGap: 0.04, anchor: UnitPoint(x: 0.5, y: 0.3))
        case .sunglasses: Shape(aspect: 2.6, fraction: 0.84, shadowScale: 0.86, shadowGap: 0.10, anchor: UnitPoint(x: 0.34, y: 0.5))
        case .bottle: Shape(aspect: 0.6, fraction: 0.40, shadowScale: 1.0, shadowGap: -0.01, anchor: UnitPoint(x: 0.5, y: 0.42))
        }
    }
}

// MARK: - Objects

private struct ArtworkObject: View {
    let artwork: KitoProductArtwork
    let box: CGSize

    var body: some View {
        Group {
            switch artwork.kind {
            case .sneaker: SneakerArt(primary: artwork.primary, accent: artwork.accent, line: line)
            case .tote: ToteArt(primary: artwork.primary, accent: artwork.accent, line: line)
            case .dress: DressArt(primary: artwork.primary, accent: artwork.accent, line: line)
            case .jacket: JacketArt(primary: artwork.primary, accent: artwork.accent, line: line)
            case .sunglasses: GlassesArt(primary: artwork.primary, accent: artwork.accent, line: line)
            case .bottle: BottleArt(primary: artwork.primary, accent: artwork.accent, line: line)
            }
        }
        .frame(width: box.width, height: box.height)
    }

    private var line: CGFloat { max(box.width * 0.012, 0.5) }
}

/// A part filled with a colour and lit from above.
private struct Shaded: View {
    let part: ArtworkPart
    let color: Color
    var shade: Double = 0.22

    var body: some View {
        ArtworkShape(part: part)
            .fill(color)
            .overlay {
                ArtworkShape(part: part).fill(
                    LinearGradient(colors: [.white.opacity(0.26), .clear, .black.opacity(shade)],
                                   startPoint: .top, endPoint: .bottom)
                )
            }
    }
}

private struct Stroked: View {
    let part: ArtworkPart
    let color: Color
    let width: CGFloat
    var dash: [CGFloat] = []

    var body: some View {
        ArtworkShape(part: part)
            .stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, dash: dash))
    }
}

private struct SneakerArt: View {
    let primary: Color
    let accent: Color
    let line: CGFloat

    var body: some View {
        ZStack {
            Shaded(part: .sneakerOutsole, color: primary, shade: 0.55)
            Shaded(part: .sneakerMidsole, color: Color(white: 0.97), shade: 0.14)
            Stroked(part: .sneakerStitch, color: .black.opacity(0.22), width: line * 0.5, dash: [line * 1.4, line])
            Shaded(part: .sneakerUpper, color: primary)
            Shaded(part: .sneakerToeCap, color: primary, shade: 0.32)
            Shaded(part: .sneakerPanel, color: accent)
            Shaded(part: .sneakerHeel, color: accent)
            Stroked(part: .sneakerCollar, color: .black.opacity(0.35), width: line * 1.6)
            Stroked(part: .sneakerLaces, color: .black.opacity(0.25), width: line * 1.5)
                .offset(y: line * 0.4)
            Stroked(part: .sneakerLaces, color: Color(white: 0.96), width: line * 1.2)
        }
    }
}

private struct ToteArt: View {
    let primary: Color
    let accent: Color
    let line: CGFloat

    var body: some View {
        ZStack {
            Stroked(part: .toteHandleBack, color: primary, width: line * 3)
                .brightness(-0.18)
            Shaded(part: .toteBody, color: primary)
            ArtworkShape(part: .toteBand).fill(Color.black.opacity(0.14))
            Stroked(part: .toteSeams, color: .black.opacity(0.2), width: line * 0.5, dash: [line * 1.4, line])
            Stroked(part: .toteHandleFront, color: primary, width: line * 3.2)
            Stroked(part: .toteHandleFront, color: .white.opacity(0.22), width: line * 0.8)
            ArtworkShape(part: .toteClasp)
                .fill(LinearGradient(colors: [accent, accent.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                .overlay { ArtworkShape(part: .toteClasp).stroke(Color.black.opacity(0.25), lineWidth: line * 0.4) }
        }
    }
}

private struct DressArt: View {
    let primary: Color
    let accent: Color
    let line: CGFloat

    var body: some View {
        ZStack {
            Stroked(part: .dressHanger, color: Color(white: 0.55), width: line * 1.3)
            Stroked(part: .dressStraps, color: primary, width: line * 1.2)
            Shaded(part: .dressSkirt, color: primary)
            Stroked(part: .dressPleats, color: .black.opacity(0.14), width: line * 0.9)
            Shaded(part: .dressBodice, color: primary, shade: 0.12)
            ArtworkShape(part: .dressBelt).fill(accent)
        }
    }
}

private struct JacketArt: View {
    let primary: Color
    let accent: Color
    let line: CGFloat

    var body: some View {
        ZStack {
            Shaded(part: .jacketSleeves, color: primary, shade: 0.34)
            Shaded(part: .jacketBody, color: primary)
            ArtworkShape(part: .jacketHem).fill(Color.black.opacity(0.18))
            ArtworkShape(part: .jacketPockets).fill(Color.black.opacity(0.22))
            Stroked(part: .jacketZip, color: .black.opacity(0.3), width: line * 1.6)
            Stroked(part: .jacketZip, color: Color(white: 0.8), width: line * 0.7, dash: [line * 0.6, line * 0.5])
            Shaded(part: .jacketLapels, color: accent, shade: 0.18)
        }
    }
}

private struct GlassesArt: View {
    let primary: Color
    let accent: Color
    let line: CGFloat

    var body: some View {
        ZStack {
            ArtworkShape(part: .glassesLenses)
                .fill(LinearGradient(colors: [accent.opacity(0.95), accent.opacity(0.65)], startPoint: .top, endPoint: .bottom))
                .overlay { ArtworkShape(part: .glassesLenses).fill(Color.black.opacity(0.25)) }
            ArtworkShape(part: .glassesGlint).fill(Color.white.opacity(0.22))
            Stroked(part: .glassesFrame, color: primary, width: line * 2.4)
            Stroked(part: .glassesBridge, color: primary, width: line * 2.4)
        }
    }
}

private struct BottleArt: View {
    let primary: Color
    let accent: Color
    let line: CGFloat

    var body: some View {
        ZStack {
            ArtworkShape(part: .bottleNeck).fill(primary.opacity(0.55))
            ArtworkShape(part: .bottleGlass).fill(primary.opacity(0.16))
            ArtworkShape(part: .bottleLiquid)
                .fill(LinearGradient(colors: [accent.opacity(0.75), accent], startPoint: .top, endPoint: .bottom))
            ArtworkShape(part: .bottleGlass).stroke(primary.opacity(0.45), lineWidth: line)
            ArtworkShape(part: .bottleLabel).fill(Color(white: 0.97))
            ArtworkShape(part: .bottleLabel).stroke(Color.black.opacity(0.12), lineWidth: line * 0.4)
            ArtworkShape(part: .bottleGlint).fill(Color.white.opacity(0.5))
            Shaded(part: .bottleCap, color: primary)
        }
    }
}
