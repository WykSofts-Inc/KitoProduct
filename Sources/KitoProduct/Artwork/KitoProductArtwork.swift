//
//  KitoProductArtwork.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

/// A product "photo" drawn on the device from shapes and gradients: a studio backdrop, a soft floor
/// shadow and a sneaker, tote, dress, jacket, pair of sunglasses or bottle in your colours. Lets
/// galleries, cards and previews look finished without a network or an asset catalogue.
///
/// ```swift
/// let hero = KitoProductArtwork.sneaker(primary: .black, accent: .orange)
/// KitoProductMedia.artwork(hero)                               // in a gallery
/// KitoProductMedia.artwork(hero.framed(.closeUp))              // a detail shot
/// hero.spin(frames: 24)                                        // frames for the 360° viewer
/// let image = hero.renderedImage(size: CGSize(width: 400, height: 500))   // a UIImage
/// ```
public struct KitoProductArtwork: Hashable, Sendable {
    public enum Kind: String, CaseIterable, Sendable {
        case sneaker
        case tote
        case dress
        case jacket
        case sunglasses
        case bottle

        public var label: String {
            switch self {
            case .sneaker: "Sneaker"
            case .tote: "Tote bag"
            case .dress: "Dress"
            case .jacket: "Jacket"
            case .sunglasses: "Sunglasses"
            case .bottle: "Bottle"
            }
        }
    }

    /// How the object sits in the frame.
    public enum Framing: String, CaseIterable, Sendable {
        /// The whole object, centred on the floor.
        case full
        /// A tight crop on a detail.
        case closeUp
        /// Tilted on a darker sweep, like a campaign shot.
        case angled
    }

    public var kind: Kind
    public var primary: Color
    public var accent: Color
    public var backdrop: Color
    public var framing: Framing
    /// Turn around the vertical axis in degrees, for spin frames. 0 is the side view.
    public var rotation: Double

    public init(_ kind: Kind, primary: Color, accent: Color, backdrop: Color? = nil,
                framing: Framing = .full, rotation: Double = 0) {
        self.kind = kind
        self.primary = primary
        self.accent = accent
        self.backdrop = backdrop ?? Color(red: 0.93, green: 0.92, blue: 0.90)
        self.framing = framing
        self.rotation = rotation
    }

    public static func sneaker(primary: Color, accent: Color, backdrop: Color? = nil) -> KitoProductArtwork {
        KitoProductArtwork(.sneaker, primary: primary, accent: accent, backdrop: backdrop)
    }

    public static func tote(primary: Color, accent: Color, backdrop: Color? = nil) -> KitoProductArtwork {
        KitoProductArtwork(.tote, primary: primary, accent: accent, backdrop: backdrop)
    }

    public static func dress(primary: Color, accent: Color, backdrop: Color? = nil) -> KitoProductArtwork {
        KitoProductArtwork(.dress, primary: primary, accent: accent, backdrop: backdrop)
    }

    public static func jacket(primary: Color, accent: Color, backdrop: Color? = nil) -> KitoProductArtwork {
        KitoProductArtwork(.jacket, primary: primary, accent: accent, backdrop: backdrop)
    }

    public static func sunglasses(primary: Color, accent: Color, backdrop: Color? = nil) -> KitoProductArtwork {
        KitoProductArtwork(.sunglasses, primary: primary, accent: accent, backdrop: backdrop)
    }

    public static func bottle(primary: Color, accent: Color, backdrop: Color? = nil) -> KitoProductArtwork {
        KitoProductArtwork(.bottle, primary: primary, accent: accent, backdrop: backdrop)
    }

    /// The same object with another framing.
    public func framed(_ framing: Framing) -> KitoProductArtwork {
        var copy = self
        copy.framing = framing
        return copy
    }

    /// The same object turned by `degrees`.
    public func rotated(_ degrees: Double) -> KitoProductArtwork {
        var copy = self
        copy.rotation = degrees
        return copy
    }

    /// A full turn in `frames` steps, for `KitoProductSpinViewer`.
    public func spin(frames: Int = 24) -> [KitoProductMedia] {
        let count = max(frames, 2)
        return (0..<count).map { index in
            let degrees = Double(index) * 360 / Double(count)
            return KitoProductMedia.artwork(framed(.full).rotated(degrees),
                                            accessibilityLabel: "\(kind.label), \(Int(degrees))°")
        }
    }

    /// A stable text key for caching and ids.
    public var cacheKey: String {
        [kind.rawValue, framing.rawValue, "\(Int(rotation))",
         String(describing: primary), String(describing: accent), String(describing: backdrop)]
            .joined(separator: "|")
    }

    /// The artwork drawn into a bitmap with `ImageRenderer`, cached by size. Use it where a
    /// `UIImage` is needed: a cart thumbnail, a share sheet, a notification.
    @MainActor
    public func renderedImage(size: CGSize, scale: CGFloat = 2) -> UIImage? {
        let width = max(size.width.rounded(), 1)
        let height = max(size.height.rounded(), 1)
        let key = "\(cacheKey)|\(Int(width))x\(Int(height))@\(scale)" as NSString
        if let cached = KitoArtworkCache.images.object(forKey: key) { return cached }
        let renderer = ImageRenderer(content: KitoProductArtworkView(self).frame(width: width, height: height))
        renderer.scale = scale
        renderer.isOpaque = true
        guard let image = renderer.uiImage else { return nil }
        let cost = Int(width * height * scale * scale * 4)
        KitoArtworkCache.images.setObject(image, forKey: key, cost: cost)
        return image
    }
}

@MainActor
enum KitoArtworkCache {
    static let images: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 64 * 1024 * 1024
        return cache
    }()
}
