# ``KitoProduct``

Product pages, galleries, variant pickers, prices, and product cards for SwiftUI shops.

## Overview

KitoProduct covers everything a product page needs: a full-bleed gallery with
zoom, a full-screen viewer and a 360° spin, colour swatches, a size picker with
a size guide, sale prices with instalments, stock and delivery messages,
product cards and grids, and an add-to-bag bar that flies the item into the
bag. Offline artwork draws sneakers, bags, dresses and more, so everything
looks finished without a network.

``KitoProductDetailView`` assembles a complete page from a
``KitoProduct/KitoProduct``. Picking a colour swaps the gallery to that
colour's photos, and tapping "Add to bag" without a size asks the user to
choose one. Pass your own ``KitoProductDetailModel`` to drive the page from
outside.

```swift
KitoProductDetailView(
    product: KitoProductSamples.runner,
    related: KitoProductSamples.looks,
    sizeGuide: KitoProductSamples.shoeGuide,
    delivery: KitoDeliveryEstimator(minDays: 1, maxDays: 3, cutoffHour: 14),
    onAddToBag: { product, variant in cart.add(product.cartItem(for: variant)) }
)
```

``KitoVariantMatrix`` answers which colours and sizes are available and
validates a ``KitoProductSelection`` before it is added. The calculations
behind the price, stock and delivery views are plain functions in
``KitoPriceMath``, ``KitoMoney``, ``KitoStockLevel`` and
``KitoDeliveryEstimator``. `cartItem(for:quantity:)` turns a product variant
into a KitoCart line item, and ``KitoProductCartThumbnail`` draws it in the
cart. ``KitoProductSamples`` provides finished products and size guides to try
things with.

## Topics

### Essentials

- ``KitoProductDetailView``
- ``KitoProductDetailModel``
- ``KitoProductSamples``

### Products

- ``KitoProduct/KitoProduct``
- ``KitoProductColor``
- ``KitoProductSize``
- ``KitoProductVariant``
- ``KitoProductMedia``
- ``KitoProductBadge``
- ``KitoProductInfoSection``

### Gallery and Media

- ``KitoProductGallery``
- ``KitoProductSpinViewer``
- ``KitoProductMediaView``
- ``KitoProductArtwork``
- ``KitoProductArtworkView``

### Choosing a Variant

- ``KitoVariantMatrix``
- ``KitoProductSelection``
- ``KitoSelectionIssue``
- ``KitoColorOption``
- ``KitoSizeOption``
- ``KitoColorSwatches``
- ``KitoSizePicker``
- ``KitoSizeGuide``
- ``KitoSizeGuideRow``
- ``KitoMeasureStep``
- ``KitoFitFeedback``
- ``KitoSizeGuideSheet``
- ``KitoFitFeedbackBar``

### Price, Stock, and Delivery

- ``KitoPriceTag``
- ``KitoPriceMath``
- ``KitoMoney``
- ``KitoStockIndicator``
- ``KitoStockLevel``
- ``KitoStockThresholds``
- ``KitoDeliveryEstimateRow``
- ``KitoDeliveryEstimator``
- ``KitoDeliveryEstimate``

### Page Components

- ``KitoAddToBagBar``
- ``KitoAddToBagButton``
- ``KitoAddToBagState``
- ``KitoWishlistButton``
- ``KitoProductBadges``
- ``KitoProductBadgeView``
- ``KitoProductRatingLine``
- ``KitoStars``
- ``KitoProductAccordion``

### Cards, Grids, and Cart

- ``KitoProductCard``
- ``KitoProductGrid``
- ``KitoProductCartThumbnail``
- ``KitoProductCartMedia``
