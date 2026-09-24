//
//  KitoProductGallery.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// A full-bleed pager of product photos. Swipe between them, pinch to peek closer, and tap to open a
/// full-screen viewer with pinch and double-tap zoom and swipe-down to close. Under
/// `.kitoProductViewerHost()` the photo grows out of the pager into the viewer.
///
/// ```swift
/// KitoProductGallery(product.media(for: colorID), selection: $page, indicator: .thumbnails)
/// KitoProductGallery(media, indicator: .counter, aspectRatio: 3 / 4, cornerRadius: 16)
/// ```
public struct KitoProductGallery: View {
    public enum Indicator: Sendable, CaseIterable {
        /// Dots on a frosted pill; the current one stretches.
        case dots
        /// A strip of thumbnails under the pager.
        case thumbnails
        /// "2 / 5" in the corner.
        case counter
        case none
    }

    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(ProductViewerPresenter.self) private var presenter: ProductViewerPresenter?
    @Environment(\.productViewerNamespace) private var namespace
    @Namespace private var thumbRing

    let media: [KitoProductMedia]
    let external: Binding<Int>?
    let indicator: Indicator
    let aspectRatio: CGFloat
    let cornerRadius: CGFloat
    let allowsFullScreen: Bool
    let tint: Color?

    @State private var galleryID = UUID()
    @State private var scrolled: Int? = 0
    @State private var peek: CGFloat = 1
    @State private var peekAnchor: UnitPoint = .center
    @State private var coverShown = false

    public init(
        _ media: [KitoProductMedia],
        selection: Binding<Int>? = nil,
        indicator: Indicator = .dots,
        aspectRatio: CGFloat = 4 / 5,
        cornerRadius: CGFloat = 0,
        allowsFullScreen: Bool = true,
        tint: Color? = nil
    ) {
        self.media = media
        self.external = selection
        self.indicator = indicator
        self.aspectRatio = aspectRatio
        self.cornerRadius = cornerRadius
        self.allowsFullScreen = allowsFullScreen
        self.tint = tint
    }

    private var current: Int { min(max(scrolled ?? 0, 0), max(media.count - 1, 0)) }
    private var palette: ProductPalette { ProductPalette(theme: theme, tint: tint) }

    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            pager
                .overlay(alignment: .bottom) { if indicator == .dots { dots } }
                .overlay(alignment: .bottomTrailing) { if indicator == .counter { counter } }
            if indicator == .thumbnails { thumbnails }
        }
        .onChange(of: media.map(\.id)) { _, _ in scrolled = 0 }
        .onChange(of: current) { _, value in
            if external?.wrappedValue != value { external?.wrappedValue = value }
        }
        .onChange(of: external?.wrappedValue) { _, value in
            guard let value, value != current else { return }
            withAnimation(ProductMotion.layout(reduceMotion)) { scrolled = value }
        }
        .onChange(of: presenter?.index) { _, value in
            guard let value, presenter?.sourceID == galleryID, value != current else { return }
            scrolled = value
        }
        .fullScreenCover(isPresented: $coverShown) {
            ProductMediaViewer(media: media, index: coverIndex, namespace: nil, heroID: { "\($0)" }, tint: tint) {
                coverShown = false
            }
        }
    }

    // MARK: Pager

    private var pager: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(Array(media.enumerated()), id: \.element.id) { item, entry in
                    page(item, entry)
                        .containerRelativeFrame(.horizontal)
                        .id(item)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $scrolled)
        .scrollClipDisabled(peek > 1)
        .aspectRatio(aspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: peek > 1 ? 0 : cornerRadius, style: .continuous))
        .zIndex(peek > 1 ? 5 : 0)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Photos, \(current + 1) of \(media.count)")
        .accessibilityAdjustableAction { direction in
            let next = direction == .increment ? current + 1 : current - 1
            scrolled = min(max(next, 0), media.count - 1)
        }
    }

    @ViewBuilder
    private func page(_ item: Int, _ entry: KitoProductMedia) -> some View {
        let isHero = presenter?.isPresented == true && presenter?.sourceID == galleryID && presenter?.index == item
        ZStack {
            if isHero {
                theme.colors.surfaceMuted
            } else {
                heroSource(item, entry)
            }
        }
        .scaleEffect(item == current ? peek : 1, anchor: peekAnchor)
        .contentShape(Rectangle())
        .onTapGesture { open(item) }
        .simultaneousGesture(peekGesture)
        .accessibilityAddTraits(allowsFullScreen ? .isButton : [])
        .accessibilityHint(allowsFullScreen ? "Opens full screen" : "")
    }

    @ViewBuilder
    private func heroSource(_ item: Int, _ entry: KitoProductMedia) -> some View {
        let content = KitoProductMediaView(entry, playsVideo: item == current)
        if let namespace, presenter != nil, !reduceMotion {
            content.matchedGeometryEffect(id: heroID(item), in: namespace)
        } else {
            content
        }
    }

    private var peekGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                peekAnchor = value.startAnchor
                peek = min(max(value.magnification, 1), 3)
            }
            .onEnded { _ in
                withAnimation(ProductMotion.layout(reduceMotion)) { peek = 1 }
            }
    }

    private func heroID(_ item: Int) -> String {
        "\(galleryID.uuidString)-\(item)"
    }

    private func open(_ item: Int) {
        guard allowsFullScreen, !media.isEmpty else { return }
        guard let presenter else {
            coverShown = true
            return
        }
        presenter.media = media
        presenter.sourceID = galleryID
        presenter.index = item
        presenter.tint = tint
        withAnimation(ProductMotion.layout(reduceMotion)) { presenter.isPresented = true }
    }

    private var coverIndex: Binding<Int> {
        Binding(get: { current }, set: { scrolled = $0 })
    }

    // MARK: Indicators

    @ViewBuilder private var dots: some View {
        if media.count > 1 {
            HStack(spacing: 5) {
                ForEach(media.indices, id: \.self) { item in
                    Capsule()
                        .fill(item == current ? theme.colors.onSurface : theme.colors.onSurface.opacity(0.3))
                        .frame(width: item == current ? 16 : 5, height: 5)
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.bottom, theme.spacing.md)
            .animation(ProductMotion.select(reduceMotion), value: current)
            .accessibilityHidden(true)
        }
    }

    @ViewBuilder private var counter: some View {
        if media.count > 1 {
            Text("\(current + 1) / \(media.count)")
                .font(theme.typography.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(theme.colors.onSurface)
                .contentTransition(.numericText())
                .padding(.horizontal, 10)
                .frame(height: 26)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(theme.spacing.md)
                .animation(.snappy, value: current)
                .accessibilityHidden(true)
        }
    }

    private var thumbnails: some View {
        ScrollViewReader { reader in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.sm) {
                    ForEach(Array(media.enumerated()), id: \.element.id) { item, entry in
                        thumbnail(item, entry).id(item)
                    }
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.vertical, 3)
            }
            .onChange(of: current) { _, value in
                withAnimation(ProductMotion.layout(reduceMotion)) { reader.scrollTo(value, anchor: .center) }
            }
        }
    }

    private func thumbnail(_ item: Int, _ entry: KitoProductMedia) -> some View {
        let isSelected = item == current
        let shape = RoundedRectangle(cornerRadius: theme.radii.sm, style: .continuous)
        return Button {
            withAnimation(ProductMotion.layout(reduceMotion)) { scrolled = item }
        } label: {
            KitoProductMediaView(entry, playsVideo: false)
                .frame(width: 52, height: 52 / aspectRatio)
                .clipShape(shape)
                .opacity(isSelected ? 1 : 0.55)
                .overlay {
                    if isSelected {
                        shape.inset(by: -3).strokeBorder(palette.ink, lineWidth: 1.5)
                            .matchedGeometryEffect(id: "thumb", in: thumbRing)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if entry.isVideo {
                        Image(systemName: "play.fill").font(.system(size: 8)).foregroundStyle(.white).padding(4)
                    }
                }
        }
        .buttonStyle(ProductPressStyle(scale: 0.94))
        .accessibilityLabel("Photo \(item + 1)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
