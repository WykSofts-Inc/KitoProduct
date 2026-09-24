//
//  KitoProductViewerHost.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import Observation

/// Which gallery opened the full-screen viewer, on which item.
@Observable
final class ProductViewerPresenter {
    var media: [KitoProductMedia] = []
    var index = 0
    var isPresented = false
    var sourceID: UUID?
    var tint: Color?

    func heroID(_ index: Int) -> String {
        "\(sourceID?.uuidString ?? "viewer")-\(index)"
    }
}

private struct ProductViewerNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var productViewerNamespace: Namespace.ID? {
        get { self[ProductViewerNamespaceKey.self] }
        set { self[ProductViewerNamespaceKey.self] = newValue }
    }
}

public extension View {
    /// Lets every `KitoProductGallery` inside open its full-screen viewer with a hero animation: the
    /// tapped photo grows out of the pager and shrinks back into it. Put it once at the root of the
    /// screen. `KitoProductDetailView` already does. Without it, galleries open a plain full-screen cover.
    ///
    /// ```swift
    /// ScrollView { KitoProductGallery(product.media) }
    ///     .kitoProductViewerHost()
    /// ```
    func kitoProductViewerHost() -> some View {
        modifier(ProductViewerHost())
    }
}

private struct ProductViewerHost: ViewModifier {
    @State private var presenter = ProductViewerPresenter()
    @Namespace private var hero

    func body(content: Content) -> some View {
        content
            .environment(presenter)
            .environment(\.productViewerNamespace, hero)
            .overlay {
                if presenter.isPresented {
                    ProductMediaViewer(
                        media: presenter.media,
                        index: Binding(get: { presenter.index }, set: { presenter.index = $0 }),
                        namespace: hero,
                        heroID: presenter.heroID,
                        tint: presenter.tint
                    ) {
                        presenter.isPresented = false
                    }
                    .zIndex(10)
                }
            }
    }
}
