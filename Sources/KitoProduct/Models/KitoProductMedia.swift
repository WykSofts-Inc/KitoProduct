//
//  KitoProductMedia.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// One item in a product gallery: a photo from a URL, artwork drawn on the device, or a video.
public struct KitoProductMedia: Identifiable, Hashable, Sendable {
    public enum Source: Hashable, Sendable {
        /// A photo loaded (and cached) from a URL.
        case image(URL)
        /// A product "photo" drawn offline — see `KitoProductArtwork`.
        case artwork(KitoProductArtwork)
        /// A looping, muted video, with a poster shown until it plays.
        case video(URL, poster: KitoProductArtwork?)
    }

    public let id: String
    public var source: Source
    /// When set, the gallery only shows this item while that colour is selected.
    public var colorID: String?
    /// What VoiceOver reads ("Side view in black").
    public var accessibilityLabel: String?

    public init(id: String? = nil, _ source: Source, colorID: String? = nil, accessibilityLabel: String? = nil) {
        self.id = id ?? Self.makeID(source, colorID: colorID)
        self.source = source
        self.colorID = colorID
        self.accessibilityLabel = accessibilityLabel
    }

    public static func image(_ url: URL, colorID: String? = nil, accessibilityLabel: String? = nil) -> KitoProductMedia {
        KitoProductMedia(.image(url), colorID: colorID, accessibilityLabel: accessibilityLabel)
    }

    public static func artwork(_ artwork: KitoProductArtwork, colorID: String? = nil, accessibilityLabel: String? = nil) -> KitoProductMedia {
        KitoProductMedia(.artwork(artwork), colorID: colorID, accessibilityLabel: accessibilityLabel ?? artwork.kind.label)
    }

    public static func video(_ url: URL, poster: KitoProductArtwork? = nil, colorID: String? = nil, accessibilityLabel: String? = nil) -> KitoProductMedia {
        KitoProductMedia(.video(url, poster: poster), colorID: colorID, accessibilityLabel: accessibilityLabel ?? "Video")
    }

    public var isVideo: Bool {
        if case .video = source { return true }
        return false
    }

    /// The photo URL, when this is a remote image.
    public var imageURL: URL? {
        if case .image(let url) = source { return url }
        return nil
    }

    private static func makeID(_ source: Source, colorID: String?) -> String {
        let tag = colorID.map { "\($0)-" } ?? ""
        switch source {
        case .image(let url): return tag + url.absoluteString
        case .artwork(let artwork): return tag + artwork.cacheKey
        case .video(let url, _): return tag + "video-" + url.absoluteString
        }
    }
}
