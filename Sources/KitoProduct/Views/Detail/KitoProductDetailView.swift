//
//  KitoProductDetailView.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// A complete product page: a full-bleed gallery (with a 360° view when there are spin frames),
/// brand and name, rating, price with instalments, colour and size pickers, stock, delivery
/// estimate, an accordion, "Complete the look" and a sticky add-to-bag bar. Adding flies the photo
/// into the bag button, which bounces and counts up.
///
/// ```swift
/// KitoProductDetailView(product: runner, related: looks, wishlist: $savedIDs, sizeGuide: runnerGuide,
///                       onAddToBag: { product, variant in cart.add(product.cartItem(for: variant)) },
///                       onSelectRelated: { path.append($0) })
/// ```
///
/// Pass `wishlist` (a set of product ids) and every heart on the page — the product's own and
/// the ones on "Complete the look" — reads from and writes to it. Without it the hearts keep
/// their own state.
public struct KitoProductDetailView: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model: KitoProductDetailModel
    let related: [KitoProduct]
    let wishlist: Binding<Set<String>>?
    let sizeGuide: KitoSizeGuide?
    let delivery: KitoDeliveryEstimator?
    let deliveryDetail: String?
    let instalments: Int?
    let showsBagButton: Bool
    let tint: Color?
    let onAddToBag: ((KitoProduct, KitoProductVariant) -> Void)?
    let onSelectRelated: ((KitoProduct) -> Void)?
    let onNotifyMe: ((KitoProduct, KitoProductSize) -> Void)?
    let onShowReviews: (() -> Void)?
    let onOpenBag: (() -> Void)?

    @State private var showsGuide = false
    @State private var showsSpin = false
    @State private var frames: [String: CGRect] = [:]
    @State private var flight: CGFloat = 0
    @State private var isFlying = false
    @State private var bagBounces = 0
    @State private var relatedSaved: Set<String> = []

    public init(
        product: KitoProduct,
        related: [KitoProduct] = [],
        wishlist: Binding<Set<String>>? = nil,
        sizeGuide: KitoSizeGuide? = nil,
        delivery: KitoDeliveryEstimator? = KitoDeliveryEstimator(minDays: 1, maxDays: 3),
        deliveryDetail: String? = "Free delivery and 30-day returns",
        instalments: Int? = 4,
        showsBagButton: Bool = true,
        tint: Color? = nil,
        onAddToBag: ((KitoProduct, KitoProductVariant) -> Void)? = nil,
        onSelectRelated: ((KitoProduct) -> Void)? = nil,
        onNotifyMe: ((KitoProduct, KitoProductSize) -> Void)? = nil,
        onShowReviews: (() -> Void)? = nil,
        onOpenBag: (() -> Void)? = nil
    ) {
        self.init(model: KitoProductDetailModel(product), related: related, wishlist: wishlist, sizeGuide: sizeGuide, delivery: delivery,
                  deliveryDetail: deliveryDetail, instalments: instalments, showsBagButton: showsBagButton, tint: tint,
                  onAddToBag: onAddToBag, onSelectRelated: onSelectRelated, onNotifyMe: onNotifyMe,
                  onShowReviews: onShowReviews, onOpenBag: onOpenBag)
    }

    public init(
        model: KitoProductDetailModel,
        related: [KitoProduct] = [],
        wishlist: Binding<Set<String>>? = nil,
        sizeGuide: KitoSizeGuide? = nil,
        delivery: KitoDeliveryEstimator? = KitoDeliveryEstimator(minDays: 1, maxDays: 3),
        deliveryDetail: String? = "Free delivery and 30-day returns",
        instalments: Int? = 4,
        showsBagButton: Bool = true,
        tint: Color? = nil,
        onAddToBag: ((KitoProduct, KitoProductVariant) -> Void)? = nil,
        onSelectRelated: ((KitoProduct) -> Void)? = nil,
        onNotifyMe: ((KitoProduct, KitoProductSize) -> Void)? = nil,
        onShowReviews: (() -> Void)? = nil,
        onOpenBag: (() -> Void)? = nil
    ) {
        _model = State(initialValue: model)
        self.related = related
        self.wishlist = wishlist
        self.sizeGuide = sizeGuide
        self.delivery = delivery
        self.deliveryDetail = deliveryDetail
        self.instalments = instalments
        self.showsBagButton = showsBagButton
        self.tint = tint
        self.onAddToBag = onAddToBag
        self.onSelectRelated = onSelectRelated
        self.onNotifyMe = onNotifyMe
        self.onShowReviews = onShowReviews
        self.onOpenBag = onOpenBag
    }

    private var product: KitoProduct { model.product }
    private var palette: ProductPalette { ProductPalette(theme: theme, tint: tint) }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                galleryArea
                VStack(alignment: .leading, spacing: theme.spacing.xl) {
                    titleBlock
                    variantBlock
                    fulfilmentBlock
                    if !product.sections.isEmpty {
                        KitoProductAccordion(product.sections, initiallyExpanded: product.sections.first?.id, tint: tint)
                    }
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.top, theme.spacing.xl)
                if !related.isEmpty { completeTheLook.padding(.top, theme.spacing.xxl) }
                Spacer(minLength: theme.spacing.xxl)
            }
        }
        .scrollIndicators(.hidden)
        .background(theme.colors.background)
        .safeAreaInset(edge: .bottom) { bar }
        .overlay(alignment: .topTrailing) { if showsBagButton { bagButton } }
        .overlay(alignment: .topLeading) { if isFlying { flyingThumbnail } }
        .coordinateSpace(name: ProductDetailSpace.name)
        .onPreferenceChange(ProductFrameKey.self) { frames = $0 }
        .kitoProductViewerHost()
        .sheet(isPresented: $showsGuide) { guideSheet }
    }

    // MARK: Gallery

    private var galleryArea: some View {
        ZStack(alignment: .bottomLeading) {
            if showsSpin {
                KitoProductSpinViewer(frames: product.spinFrames, tint: tint)
                    .transition(.opacity)
            } else {
                KitoProductGallery(model.galleryMedia, selection: $model.galleryPage, indicator: .dots, tint: tint)
                    .transition(.opacity)
            }
            if !product.spinFrames.isEmpty { spinToggle }
        }
        .animation(.easeInOut(duration: 0.3), value: showsSpin)
    }

    private var spinToggle: some View {
        Button {
            showsSpin.toggle()
        } label: {
            Label(showsSpin ? "Photos" : "360°", systemImage: showsSpin ? "photo.on.rectangle" : "rotate.3d")
                .font(theme.typography.caption.weight(.semibold))
                .foregroundStyle(theme.colors.onSurface)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(ProductPressStyle())
        .padding(theme.spacing.md)
        .padding(.bottom, showsSpin ? theme.spacing.xxl : 0)
        .accessibilityLabel(showsSpin ? "Show photos" : "Show 360 degree view")
    }

    // MARK: Title

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            if !product.badges.isEmpty { KitoProductBadges(product.badges, tint: tint) }
            EyebrowText(product.brand)
            Text(product.name)
                .font(theme.typography.titleLarge)
                .foregroundStyle(theme.colors.onBackground)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let rating = product.rating {
                KitoProductRatingLine(rating: rating, reviewCount: product.reviewCount, tint: tint, onTap: onShowReviews)
            }
            KitoPriceTag(price: model.price, compareAt: product.compareAtPrice, currencyCode: product.currencyCode,
                         instalments: instalments, tint: tint)
                .padding(.top, theme.spacing.xs)
            if let summary = product.summary {
                Text(summary)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.onBackground.opacity(0.7))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, theme.spacing.xs)
            }
        }
    }

    // MARK: Variants

    private var variantBlock: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xl) {
            if !product.colors.isEmpty {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    KitoColorSwatches(model.colorOptions, selection: colorBinding, tint: tint)
                    if model.issue == .chooseColor || model.issue == .unavailable, let issue = model.issue {
                        Label(issue.message, systemImage: "exclamationmark.circle")
                            .font(theme.typography.caption.weight(.medium))
                            .foregroundStyle(theme.colors.danger)
                    }
                }
            }
            if !product.sizes.isEmpty {
                KitoSizePicker(model.sizeOptions, selection: sizeBinding, error: sizeError,
                               shakeTrigger: model.failedAttempts, tint: tint,
                               onSizeGuide: sizeGuide == nil ? nil : { showsGuide = true },
                               onNotifyMe: { size in onNotifyMe?(product, size) })
            }
            if product.sizes.isEmpty || model.selectedSize != nil {
                KitoStockIndicator(level: model.stockLevel, tint: tint)
            }
        }
    }

    private var sizeError: String? {
        guard let issue = model.issue, issue == .chooseSize || issue == .soldOut else { return nil }
        return issue == .chooseSize ? issue.message : nil
    }

    private var colorBinding: Binding<String?> {
        Binding(get: { model.selection.colorID }, set: { id in if let id { model.selectColor(id) } })
    }

    private var sizeBinding: Binding<String?> {
        Binding(get: { model.selection.sizeID }, set: { model.selectSize($0) })
    }

    // MARK: Fulfilment

    @ViewBuilder private var fulfilmentBlock: some View {
        if let delivery {
            KitoDeliveryEstimateRow(estimator: delivery, detail: deliveryDetail, tint: tint)
        }
    }

    // MARK: Complete the look

    private var completeTheLook: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Complete the look")
                .font(theme.typography.titleMedium)
                .foregroundStyle(theme.colors.onBackground)
                .padding(.horizontal, theme.spacing.lg)
                .accessibilityAddTraits(.isHeader)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: theme.spacing.md) {
                    ForEach(Array(related.enumerated()), id: \.element.id) { index, item in
                        KitoProductCard(item, style: .compact, isWishlisted: savedBinding(item.id), tint: tint,
                                        onSelect: onSelectRelated.map { select in { select(item) } })
                            .modifier(StaggeredAppear(index: index))
                    }
                }
                .padding(.horizontal, theme.spacing.lg)
            }
        }
    }

    /// A heart for one product: backed by the app's `wishlist` when there is one, otherwise by
    /// this page's own state.
    private func savedBinding(_ id: String) -> Binding<Bool> {
        if let wishlist {
            return Binding(get: { wishlist.wrappedValue.contains(id) },
                           set: { isOn in
                               if isOn { wishlist.wrappedValue.insert(id) } else { wishlist.wrappedValue.remove(id) }
                           })
        }
        return Binding(get: { relatedSaved.contains(id) },
                       set: { isOn in if isOn { relatedSaved.insert(id) } else { relatedSaved.remove(id) } })
    }

    /// The main product's heart: kept in step with `wishlist` when there is one.
    private var productSaved: Binding<Bool> {
        guard let wishlist else { return $model.isWishlisted }
        let id = product.id
        let model = model
        return Binding(get: { wishlist.wrappedValue.contains(id) },
                       set: { isOn in
                           if isOn { wishlist.wrappedValue.insert(id) } else { wishlist.wrappedValue.remove(id) }
                           model.isWishlisted = isOn
                       })
    }

    // MARK: Bag

    private var bar: some View {
        KitoAddToBagBar(price: KitoMoney.string(model.price, currencyCode: product.currencyCode),
                        state: model.addState, isWishlisted: productSaved, tint: tint, action: add)
            .background(FrameReader(id: ProductDetailSpace.source))
    }

    private var bagButton: some View {
        Button { onOpenBag?() } label: {
            Image(systemName: "bag")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(theme.colors.onSurface)
                .symbolEffect(.bounce, value: bagBounces)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(alignment: .topTrailing) { bagCount }
        }
        .buttonStyle(ProductPressStyle(scale: 0.9))
        .background(FrameReader(id: ProductDetailSpace.target))
        .padding(theme.spacing.lg)
        .accessibilityLabel("Bag, \(model.bagCount) items")
    }

    @ViewBuilder private var bagCount: some View {
        if model.bagCount > 0 {
            Text("\(model.bagCount)")
                .font(.system(size: 10, weight: .bold).monospacedDigit())
                .foregroundStyle(palette.onInk)
                .contentTransition(.numericText())
                .frame(minWidth: 17, minHeight: 17)
                .background(palette.ink, in: Capsule())
                .offset(x: 3, y: -3)
                .transition(.scale.combined(with: .opacity))
        }
    }

    private var flyingThumbnail: some View {
        let media = model.galleryMedia.first ?? KitoProductMedia.artwork(.tote(primary: .gray, accent: .white))
        return KitoProductMediaView(media)
            .frame(width: 64, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.md, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
            .modifier(FlightEffect(progress: flight, from: flightStart, to: flightEnd))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var flightStart: CGPoint {
        let frame = frames[ProductDetailSpace.source] ?? .zero
        return CGPoint(x: frame.midX, y: frame.minY + 10)
    }

    private var flightEnd: CGPoint {
        let frame = frames[ProductDetailSpace.target] ?? .zero
        return CGPoint(x: frame.midX, y: frame.midY)
    }

    private var guideSheet: some View {
        Group {
            if let sizeGuide {
                KitoSizeGuideSheet(guide: sizeGuide, selection: sizeBinding, tint: tint)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private func add() {
        guard let variant = withAnimation(ProductMotion.select(reduceMotion), { model.addToBag() }) else { return }
        onAddToBag?(product, variant)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            if reduceMotion || !showsBagButton || frames[ProductDetailSpace.target] == nil {
                arrive()
            } else {
                fly()
            }
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            withAnimation(ProductMotion.select(reduceMotion)) { model.settle() }
        }
    }

    private func fly() {
        flight = 0
        isFlying = true
        withAnimation(.easeIn(duration: 0.6)) {
            flight = 1
        } completion: {
            isFlying = false
            flight = 0
            arrive()
        }
    }

    private func arrive() {
        withAnimation(ProductMotion.select(reduceMotion)) { model.finishAdding() }
        bagBounces += 1
    }
}

// MARK: - Flight

enum ProductDetailSpace {
    static let name = "kito-product-detail"
    static let source = "bag-source"
    static let target = "bag-target"
}

struct ProductFrameKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

struct FrameReader: View {
    let id: String

    var body: some View {
        GeometryReader { proxy in
            Color.clear.preference(key: ProductFrameKey.self,
                                   value: [id: proxy.frame(in: .named(ProductDetailSpace.name))])
        }
    }
}

/// Moves a view along an arc from `from` to `to`, shrinking and fading as it lands.
struct FlightEffect: GeometryEffect {
    var progress: CGFloat
    let from: CGPoint
    let to: CGPoint

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let point = position(at: progress)
        let scale = 1 - 0.75 * progress
        let x = point.x - size.width * scale / 2
        let y = point.y - size.height * scale / 2
        let transform = CGAffineTransform(scaleX: scale, y: scale)
            .concatenating(CGAffineTransform(translationX: x, y: y))
        return ProjectionTransform(transform)
    }

    /// A quadratic curve with its control point above both ends.
    private func position(at t: CGFloat) -> CGPoint {
        let control = CGPoint(x: (from.x + to.x) / 2 - 40, y: min(from.y, to.y) - 120)
        let a = (1 - t) * (1 - t)
        let b = 2 * (1 - t) * t
        let c = t * t
        return CGPoint(x: a * from.x + b * control.x + c * to.x,
                       y: a * from.y + b * control.y + c * to.y)
    }
}
