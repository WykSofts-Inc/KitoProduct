# KitoProduct

Product pages for SwiftUI: a full-bleed gallery with zoom, a full-screen viewer and a 360° spin,
colour swatches, a size picker with a size guide, sale prices with instalments, stock and delivery
messages, product cards and grids, and a complete product page with an add-to-bag bar that flies the
item into the bag. Offline artwork draws sneakers, bags, dresses and more, so everything looks
finished without a network. Part of the [Kito](https://github.com/WykSofts-Inc/KitoDevKit) ecosystem.

## A product page in one view

```swift
KitoProductDetailView(
    product: runner,
    related: completeTheLook,
    sizeGuide: shoeGuide,
    delivery: KitoDeliveryEstimator(minDays: 1, maxDays: 3, cutoffHour: 14),
    onAddToBag: { product, variant in cart.add(product.cartItem(for: variant)) },
    onSelectRelated: { path.append($0) },
    onNotifyMe: { product, size in alerts.subscribe(product.id, size: size.id) }
)
```

Pass `wishlist: $savedIDs` (a `Set` of product ids) and every heart on the page, including the
ones on "Complete the look", reads from and saves to your wishlist.

Picking a colour swaps the gallery to that colour's photos. Tapping "Add to bag" without a size
shakes the size grid and says "Choose a size". A valid tap turns the button into a spinner and then
"Added ✓", and the photo flies into the bag button, which bounces and counts up. The heart bursts
when you save it. To drive the page from outside, pass your own `KitoProductDetailModel`.

## Products

```swift
let runner = KitoProduct(
    id: "runner-01", name: "Runner 01", brand: "Kora Athletics",
    price: 9_900, compareAtPrice: 13_200, rating: 4.6, reviewCount: 214,
    badges: [.bestseller, .new, .eco, .lowStock],
    media: [.artwork(.sneaker(primary: .black, accent: .orange), colorID: "black"),
            .image(photoURL, colorID: "sand"),
            .video(clipURL)],
    spinFrames: KitoProductArtwork.sneaker(primary: .black, accent: .orange).spin(frames: 24),
    colors: [KitoProductColor("black", name: "Black", swatch: .black),
             KitoProductColor("sand", name: "Sand", swatch: sandColor)],
    sizes: KitoProductSize.range(["UK 7", "UK 8", "UK 9"]),
    variants: [KitoProductVariant(colorID: "black", sizeID: "UK 8", stock: 2)])
```

`KitoProductSamples` has six finished products (`runner`, `tote`, `dress`, `jacket`,
`sunglasses`, `scent`) and two size guides to try things with.

## Gallery

```swift
KitoProductGallery(product.media(for: colorID), selection: $page, indicator: .thumbnails)  // .dots, .counter
KitoProductSpinViewer(frames: product.spinFrames)
```

Swipe between photos and pinch to look closer. Tap to open the full-screen viewer, where you can
pinch or double-tap to zoom, drag to pan, swipe between photos and drag down to close. Add
`.kitoProductViewerHost()` at the root of your screen and the photo grows out of the pager into the
viewer and shrinks back when you close it. `KitoProductDetailView` does this already. The spin viewer
turns as you drag, keeps turning after a fling, and turns once by itself when it appears.

## Choosing a variant

```swift
let matrix = KitoVariantMatrix(product)
KitoColorSwatches(matrix.colorOptions(), selection: $colorID)
KitoSizePicker(matrix.sizeOptions(for: colorID), selection: $sizeID, style: .grid,   // or .chips
               error: issue?.message, onSizeGuide: { showGuide = true },
               onNotifyMe: { size in subscribe(size) })
    .sheet(isPresented: $showGuide) { KitoSizeGuideSheet(guide: guide, selection: $sizeID) }

switch matrix.validate(KitoProductSelection(colorID: colorID, sizeID: sizeID)) {
case .success(let variant): add(variant)
case .failure(let issue): show(issue.message)     // "Choose a size", "This size is sold out"
}
```

Sizes that aren't made in the chosen colour are struck through. Sold-out sizes can still be picked,
and then offer "Notify me". A size with only a few left says "Only 2 left in UK 8". The size guide
has a centimetre/inch switch, highlights the chosen size, explains how to measure, and shows a fit
bar from "Runs small" through "True to size" to "Runs large".

## Price, stock and delivery

```swift
KitoPriceTag(price: 9_900, compareAt: 13_200, instalments: 4)   // KES 9,900  KES 13,200  −25%  or 4 × KES 2,475
KitoStockIndicator(stock: 2)                                    // pulsing dot, "Only 2 left"
KitoDeliveryEstimateRow(estimator: KitoDeliveryEstimator(minDays: 1, maxDays: 2))
                                                                // "Get it Fri 25 – Mon 28 Sep", "Order within 3 h 12 min"
KitoProductBadges([.new, .bestseller, .lowStock, .eco])
KitoProductRatingLine(rating: 4.6, reviewCount: 214)
KitoProductAccordion(product.sections)
KitoAddToBagBar(price: "KES 9,900", state: .idle, isWishlisted: $saved) { add() }
```

The maths behind them are plain functions: `KitoPriceMath.discountPercent`, `.instalment` (rounded
up so the payments cover the total), `KitoMoney.string`, `KitoStockLevel.level(for:thresholds:)`
and `KitoDeliveryEstimator.estimate(from:)`, which skips weekends and holidays and moves orders
after the cut-off to the next working day.

## Cards and grids

```swift
KitoProductCard(product, style: .grid, isWishlisted: $saved,           // .editorial, .compact, .horizontal
                onQuickAdd: { product, variant in cart.add(product.cartItem(for: variant)) },
                onSelect: { open(product) })

KitoProductGrid(products, layout: .staggered, wishlist: $saved,
                onSelect: { open($0) }, onQuickAdd: { cart.add($0.cartItem(for: $1)) })
```

Quick add on a product with sizes slides a size strip up over the photo. The grid's cards rise into
place one after another.

## In the cart

```swift
cart.add(product.cartItem(for: variant))      // line id "runner-01-black-UK 8", price, subtitle, picture

KitoCartView(cart: cart, onCheckout: pay) { item in
    KitoProductCartThumbnail(item)            // the photo or drawn artwork in the chosen colour
}
```

Cart line ids always start with the product id, so two products in the same colour and size stay
on separate lines. Drawn artwork has no URL, so `cartItem(for:)` remembers it for the line;
`item.productMedia` gives it back, and `KitoProductCartThumbnail` draws it.

## Artwork

```swift
let art = KitoProductArtwork.tote(primary: .brown, accent: .yellow)   // sneaker, dress, jacket, sunglasses, bottle
KitoProductArtworkView(art.framed(.closeUp))                           // .full, .angled
let image = art.renderedImage(size: CGSize(width: 400, height: 500))   // a UIImage, via ImageRenderer
```

Every view follows the Kito theme, works in light and dark mode, has VoiceOver labels and honours
Reduce Motion.

## Migrating from 0.1

- `KitoRatingSummary` is now **`KitoProductRatingLine`**, so KitoProduct and
  [KitoReviews](https://github.com/WykSofts-Inc/KitoReviews) (which keeps `KitoRatingSummary`) can be
  imported in the same file. Same parameters.
- Variants created without an `id` now get one that starts with the product id:
  `"black-UK 8"` becomes `"runner-01-black-UK 8"`. Ids you pass yourself are unchanged.
- `cartItem(for:)` line ids always start with the product id (see `cartLineID(for:)`). Variant ids
  that already start with it, such as `"runner-01~black~UK 8"`, are used as they are.

## Right-to-left

Layouts mirror with the layout direction: the gallery pager, dots, variant rows, fit bar and price
tags all flip in Arabic or Hebrew. The full-screen viewer converts on-screen drags, so paging, the
zoomed pan and double-tap-to-zoom follow the finger; the gallery's pinch peek zooms where you pinch,
and the add-to-bag flight lands on the bag. The 360° viewer turns with the finger in every layout
(its dial fills from the trailing side, like any progress bar). Discount pills use the locale's
percent format.

## Installation

```swift
.package(url: "https://github.com/WykSofts-Inc/KitoProduct.git", from: "0.2.0")
```

KitoProduct uses [KitoCore](https://github.com/WykSofts-Inc/KitoCore),
[KitoCart](https://github.com/WykSofts-Inc/KitoCart) (for `cartItem(for:)`) and
[KitoImageLoader](https://github.com/WykSofts-Inc/KitoImageLoader) (for cached photos).

## License

MIT — see [LICENSE](LICENSE).
