//
//  KitoProductMediaView.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import AVFoundation
import KitoCore
import KitoImageLoader

/// Shows one gallery item — a cached remote photo, drawn artwork or a looping muted video — filling
/// the frame it's given. Size and clip it from outside.
///
/// ```swift
/// KitoProductMediaView(product.media[0])
///     .aspectRatio(4 / 5, contentMode: .fit)
///     .clipShape(RoundedRectangle(cornerRadius: 12))
/// ```
public struct KitoProductMediaView: View {
    /// How drawn artwork is shown.
    public enum ArtworkRendering: Sendable {
        /// Drawn once into a bitmap with `ImageRenderer` and cached — cheapest in scrolling grids.
        case cached
        /// Drawn live as shapes — stays sharp at any zoom.
        case live
    }

    let media: KitoProductMedia
    let contentMode: ContentMode
    let rendering: ArtworkRendering
    let playsVideo: Bool

    public init(_ media: KitoProductMedia, contentMode: ContentMode = .fill,
                artwork rendering: ArtworkRendering = .cached, playsVideo: Bool = true) {
        self.media = media
        self.contentMode = contentMode
        self.rendering = rendering
        self.playsVideo = playsVideo
    }

    public var body: some View {
        content
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(media.accessibilityLabel ?? "Product image")
            .accessibilityAddTraits(.isImage)
    }

    @ViewBuilder private var content: some View {
        switch media.source {
        case .image(let url):
            KitoRemoteImage(url: url, loading: .shimmer, appearance: .fade, contentMode: contentMode,
                            accessibilityLabel: media.accessibilityLabel)
        case .artwork(let artwork):
            if rendering == .live {
                KitoProductArtworkView(artwork)
            } else {
                CachedArtworkView(artwork: artwork)
            }
        case .video(let url, let poster):
            ProductVideoView(url: url, poster: poster, plays: playsVideo, contentMode: contentMode)
        }
    }
}

// MARK: - Cached artwork

private struct CachedArtworkView: View {
    let artwork: KitoProductArtwork
    @Environment(\.displayScale) private var displayScale
    @State private var image: UIImage?

    var body: some View {
        GeometryReader { proxy in
            let size = Self.bucket(proxy.size)
            ZStack {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    KitoProductArtworkView(artwork)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
            .task(id: RenderKey(artwork: artwork, size: size)) {
                image = artwork.renderedImage(size: size, scale: min(displayScale, 3))
            }
        }
    }

    private struct RenderKey: Hashable {
        let artwork: KitoProductArtwork
        let size: CGSize

        static func == (lhs: RenderKey, rhs: RenderKey) -> Bool {
            lhs.artwork == rhs.artwork && lhs.size == rhs.size
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(artwork)
            hasher.combine(size.width)
            hasher.combine(size.height)
        }
    }

    /// Rounds up to 40-point steps (keeping the aspect ratio) so nearby sizes share a bitmap.
    static func bucket(_ size: CGSize) -> CGSize {
        guard size.width > 0, size.height > 0 else { return CGSize(width: 40, height: 50) }
        let width = (size.width / 40).rounded(.up) * 40
        return CGSize(width: width, height: (width * size.height / size.width).rounded())
    }
}

// MARK: - Video

private struct ProductVideoView: View {
    let url: URL
    let poster: KitoProductArtwork?
    let plays: Bool
    let contentMode: ContentMode

    @Environment(\.kitoTheme) private var theme

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let poster {
                KitoProductArtworkView(poster)
            } else {
                theme.colors.surfaceMuted
            }
            LoopingPlayerView(url: url, plays: plays, fill: contentMode == .fill)
            Image(systemName: "speaker.slash.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
                .padding(7)
                .background(.black.opacity(0.35), in: Circle())
                .padding(12)
                .accessibilityHidden(true)
        }
    }
}

private struct LoopingPlayerView: UIViewRepresentable {
    let url: URL
    let plays: Bool
    let fill: Bool

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.configure(url: url, fill: fill)
        return view
    }

    func updateUIView(_ view: PlayerContainerView, context: Context) {
        view.configure(url: url, fill: fill)
        view.setPlaying(plays)
    }

    static func dismantleUIView(_ view: PlayerContainerView, coordinator: ()) {
        view.setPlaying(false)
    }
}

final class PlayerContainerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    private var playerLayer: AVPlayerLayer? { layer as? AVPlayerLayer }
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var currentURL: URL?

    func configure(url: URL, fill: Bool) {
        playerLayer?.videoGravity = fill ? .resizeAspectFill : .resizeAspect
        guard url != currentURL else { return }
        currentURL = url
        let item = AVPlayerItem(url: url)
        let queue = AVQueuePlayer()
        queue.isMuted = true
        looper = AVPlayerLooper(player: queue, templateItem: item)
        player = queue
        playerLayer?.player = queue
        backgroundColor = .clear
    }

    func setPlaying(_ playing: Bool) {
        if playing { player?.play() } else { player?.pause() }
    }
}
