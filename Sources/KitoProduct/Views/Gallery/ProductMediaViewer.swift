//
//  ProductMediaViewer.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// The full-screen viewer: swipe between items, pinch or double-tap to zoom, drag to pan while
/// zoomed, and drag down to dismiss. One drag gesture decides its axis on the first movement, so
/// paging, panning and dismissing never fight.
struct ProductMediaViewer: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let media: [KitoProductMedia]
    @Binding var index: Int
    let namespace: Namespace.ID?
    let heroID: (Int) -> String
    let tint: Color?
    let onClose: () -> Void

    @State private var axis: Axis?
    @State private var pageDrag: CGFloat = 0
    @State private var dismissDrag: CGSize = .zero
    @State private var scale: CGFloat = 1
    @State private var baseScale: CGFloat = 1
    @State private var pan: CGSize = .zero
    @State private var basePan: CGSize = .zero
    @State private var chromeVisible = true

    private var isZoomed: Bool { scale > 1.01 }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black
                    .opacity(backgroundOpacity)
                    .ignoresSafeArea()
                pages(in: proxy.size)
                chrome
                    .opacity(chromeVisible && dismissDrag == .zero ? 1 : 0)
            }
            .contentShape(Rectangle())
            .gesture(drag(width: proxy.size.width, size: proxy.size))
            .simultaneousGesture(magnify(size: proxy.size))
        }
        .transition(.opacity)
        .onChange(of: index) { _, _ in
            scale = 1
            baseScale = 1
            resetPan()
        }
        .statusBarHidden(true)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) { close() }
    }

    // MARK: Pages

    private func pages(in size: CGSize) -> some View {
        ZStack {
            ForEach(visibleIndices, id: \.self) { item in
                page(item, size: size)
                    .offset(x: CGFloat(item - index) * (size.width + 16) + pageDrag)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private var visibleIndices: [Int] {
        guard !media.isEmpty else { return [] }
        return Array(max(index - 1, 0)...min(index + 1, media.count - 1))
    }

    @ViewBuilder
    private func page(_ item: Int, size: CGSize) -> some View {
        let isCurrent = item == index
        let frame = fittedSize(in: size)
        heroFrame(item: item, isCurrent: isCurrent, size: frame)
            .scaleEffect(isCurrent ? scale * dismissScale : 1)
            .offset(isCurrent ? combinedOffset : .zero)
            .onTapGesture(count: 2, coordinateSpace: .local) { location in
                doubleTap(at: location, frame: frame)
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) { chromeVisible.toggle() }
            }
    }

    @ViewBuilder
    private func heroFrame(item: Int, isCurrent: Bool, size: CGSize) -> some View {
        let content = KitoProductMediaView(media[item], artwork: .live, playsVideo: isCurrent)
            .frame(width: size.width, height: size.height)
            .clipped()
        if isCurrent, let namespace, !reduceMotion {
            content.matchedGeometryEffect(id: heroID(item), in: namespace)
        } else {
            content
        }
    }

    /// The largest 4:5 frame that fits on screen.
    private func fittedSize(in size: CGSize) -> CGSize {
        let width = min(size.width, size.height * 0.8)
        return CGSize(width: width, height: width * 1.25)
    }

    // MARK: Chrome

    private var chrome: some View {
        VStack {
            HStack {
                Text("\(index + 1) / \(media.count)")
                    .font(theme.typography.label.monospacedDigit())
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(.white.opacity(0.14), in: Capsule())
                Spacer()
                Button(action: close) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.14), in: Circle())
                }
                .buttonStyle(ProductPressStyle(scale: 0.9))
                .accessibilityLabel("Close")
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.top, theme.spacing.sm)
            Spacer()
            HStack(spacing: 6) {
                ForEach(media.indices, id: \.self) { item in
                    Capsule()
                        .fill(.white.opacity(item == index ? 1 : 0.35))
                        .frame(width: item == index ? 18 : 6, height: 6)
                }
            }
            .animation(ProductMotion.select(reduceMotion), value: index)
            .padding(.bottom, theme.spacing.xl)
            .accessibilityHidden(true)
        }
    }

    // MARK: Gestures

    private func drag(width: CGFloat, size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in dragChanged(value, width: width, size: size) }
            .onEnded { value in dragEnded(value, width: width, size: size) }
    }

    private func dragChanged(_ value: DragGesture.Value, width: CGFloat, size: CGSize) {
        if isZoomed {
            pan = clampedPan(CGSize(width: basePan.width + value.translation.width,
                                    height: basePan.height + value.translation.height), size: size)
            return
        }
        if axis == nil {
            axis = abs(value.translation.width) > abs(value.translation.height) ? .horizontal : .vertical
        }
        if axis == .horizontal {
            pageDrag = rubberBanded(value.translation.width)
        } else {
            dismissDrag = value.translation
        }
    }

    private func dragEnded(_ value: DragGesture.Value, width: CGFloat, size: CGSize) {
        defer { axis = nil }
        if isZoomed {
            basePan = pan
            return
        }
        if axis == .horizontal {
            endPaging(value, width: width)
        } else if axis == .vertical {
            endDismiss(value)
        }
    }

    private func endPaging(_ value: DragGesture.Value, width: CGFloat) {
        let travel = value.predictedEndTranslation.width
        var next = index
        if travel < -width * 0.3 { next = min(index + 1, media.count - 1) }
        if travel > width * 0.3 { next = max(index - 1, 0) }
        withAnimation(ProductMotion.layout(reduceMotion)) {
            index = next
            pageDrag = 0
        }
    }

    private func endDismiss(_ value: DragGesture.Value) {
        let far = value.translation.height > 110 || value.predictedEndTranslation.height > 320
        if far {
            close()
        } else {
            withAnimation(ProductMotion.layout(reduceMotion)) { dismissDrag = .zero }
        }
    }

    private func magnify(size: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(max(baseScale * value.magnification, 0.8), 4)
            }
            .onEnded { _ in
                withAnimation(ProductMotion.layout(reduceMotion)) {
                    if scale < 1 { scale = 1 }
                    baseScale = scale
                    if scale <= 1 { resetPan() } else { pan = clampedPan(pan, size: size); basePan = pan }
                }
            }
    }

    private func doubleTap(at location: CGPoint, frame: CGSize) {
        withAnimation(ProductMotion.layout(reduceMotion)) {
            if isZoomed {
                scale = 1
                baseScale = 1
                resetPan()
            } else {
                scale = 2.5
                baseScale = 2.5
                let target = CGSize(width: (frame.width / 2 - location.x) * 1.5,
                                    height: (frame.height / 2 - location.y) * 1.5)
                pan = clampedPan(target, size: frame)
                basePan = pan
            }
        }
    }

    // MARK: Maths

    private var combinedOffset: CGSize {
        CGSize(width: pan.width + dismissDrag.width, height: pan.height + dismissDrag.height)
    }

    private var dismissProgress: CGFloat {
        min(max(dismissDrag.height, 0) / 400, 1)
    }

    private var dismissScale: CGFloat { 1 - dismissProgress * 0.25 }

    private var backgroundOpacity: Double { Double(1 - dismissProgress * 0.9) }

    private func rubberBanded(_ translation: CGFloat) -> CGFloat {
        let atStart = index == 0 && translation > 0
        let atEnd = index == media.count - 1 && translation < 0
        return atStart || atEnd ? translation * 0.3 : translation
    }

    private func clampedPan(_ proposed: CGSize, size: CGSize) -> CGSize {
        let maxX = max((size.width * scale - size.width) / 2, 0)
        let maxY = max((size.height * scale - size.height) / 2, 0)
        return CGSize(width: min(max(proposed.width, -maxX), maxX),
                      height: min(max(proposed.height, -maxY), maxY))
    }

    private func resetPan() {
        pan = .zero
        basePan = .zero
    }

    private func close() {
        withAnimation(ProductMotion.layout(reduceMotion)) {
            scale = 1
            baseScale = 1
            resetPan()
            dismissDrag = .zero
            onClose()
        }
    }
}
