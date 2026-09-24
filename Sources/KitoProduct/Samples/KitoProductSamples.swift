//
//  KitoProductSamples.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

/// Ready-made products with drawn artwork, for previews, demos and tests. Brands are invented.
///
/// ```swift
/// KitoProductDetailView(product: KitoProductSamples.runner, related: KitoProductSamples.looks,
///                       sizeGuide: KitoProductSamples.shoeGuide)
/// KitoProductGrid(KitoProductSamples.all)
/// ```
public enum KitoProductSamples {
    // MARK: Palette

    static let ink = Color(red: 0.10, green: 0.10, blue: 0.12)
    static let ember = Color(red: 0.95, green: 0.45, blue: 0.20)
    static let sand = Color(red: 0.86, green: 0.78, blue: 0.64)
    static let bone = Color(red: 0.96, green: 0.94, blue: 0.90)
    static let olive = Color(red: 0.36, green: 0.40, blue: 0.26)
    static let cognac = Color(red: 0.62, green: 0.40, blue: 0.24)
    static let brass = Color(red: 0.85, green: 0.70, blue: 0.36)
    static let claret = Color(red: 0.55, green: 0.12, blue: 0.20)
    static let midnight = Color(red: 0.14, green: 0.18, blue: 0.30)
    static let sage = Color(red: 0.62, green: 0.70, blue: 0.60)
    static let tortoise = Color(red: 0.30, green: 0.18, blue: 0.10)

    // MARK: Products

    /// A sneaker in three colourways with a sale price, low stock in some sizes and a 360° spin.
    public static let runner: KitoProduct = {
        let black = KitoProductArtwork.sneaker(primary: ink, accent: ember)
        let sandShoe = KitoProductArtwork.sneaker(primary: sand, accent: bone, backdrop: Color(red: 0.91, green: 0.89, blue: 0.86))
        let oliveShoe = KitoProductArtwork.sneaker(primary: olive, accent: sand)
        let sizes = ["UK 6", "UK 7", "UK 8", "UK 9", "UK 10", "UK 11"]
        var variants: [KitoProductVariant] = []
        let blackStock = [4, 12, 2, 0, 7, 1]
        let sandStock = [0, 3, 9, 14, 0, 0]
        for (index, size) in sizes.enumerated() {
            variants.append(KitoProductVariant(colorID: "black", sizeID: size, stock: blackStock[index]))
            if index < 5 { variants.append(KitoProductVariant(colorID: "sand", sizeID: size, stock: sandStock[index])) }
            variants.append(KitoProductVariant(colorID: "olive", sizeID: size, stock: 0))
        }
        return KitoProduct(
            id: "runner-01", name: "Runner 01 Leather Sneaker", brand: "Kora Athletics",
            price: 9_900, compareAtPrice: 13_200, rating: 4.6, reviewCount: 214,
            badges: [.bestseller, .sale(percent: 25)],
            media: [
                .artwork(black, colorID: "black", accessibilityLabel: "Side view in black"),
                .artwork(black.framed(.closeUp), colorID: "black", accessibilityLabel: "Toe detail in black"),
                .artwork(black.framed(.angled), colorID: "black", accessibilityLabel: "Angled view in black"),
                .artwork(sandShoe, colorID: "sand", accessibilityLabel: "Side view in sand"),
                .artwork(sandShoe.framed(.closeUp), colorID: "sand", accessibilityLabel: "Toe detail in sand"),
                .artwork(sandShoe.framed(.angled), colorID: "sand", accessibilityLabel: "Angled view in sand"),
                .artwork(oliveShoe, colorID: "olive", accessibilityLabel: "Side view in olive"),
                .artwork(oliveShoe.framed(.angled), colorID: "olive", accessibilityLabel: "Angled view in olive"),
            ],
            spinFrames: black.spin(frames: 24),
            colors: [
                KitoProductColor("black", name: "Black / Ember", swatch: ink, secondarySwatch: ember),
                KitoProductColor("sand", name: "Sand", swatch: sand),
                KitoProductColor("olive", name: "Olive", swatch: olive),
            ],
            sizes: sizes.map { KitoProductSize($0) },
            variants: variants,
            summary: "A low-profile runner in full-grain leather on a cushioned cup sole. Made to be worn in.",
            sections: standardSections(details: "Full-grain leather upper with a padded collar and a removable foam insole. Cup sole stitched for a longer life.",
                                       materials: ["Upper: 100% leather", "Lining: recycled polyester", "Sole: natural rubber",
                                                   "Wipe clean with a damp cloth"])
        )
    }()

    /// A leather tote in two colours, no sizes.
    public static let tote: KitoProduct = {
        let brown = KitoProductArtwork.tote(primary: cognac, accent: brass)
        let black = KitoProductArtwork.tote(primary: ink, accent: brass)
        return KitoProduct(
            id: "soko-tote", name: "Soko Structured Tote", brand: "Maison Tana",
            price: 18_500, rating: 4.8, reviewCount: 96, badges: [.new],
            media: [
                .artwork(brown, colorID: "cognac", accessibilityLabel: "Tote in cognac"),
                .artwork(brown.framed(.closeUp), colorID: "cognac", accessibilityLabel: "Clasp detail"),
                .artwork(black, colorID: "black", accessibilityLabel: "Tote in black"),
                .artwork(black.framed(.angled), colorID: "black", accessibilityLabel: "Tote in black, angled"),
            ],
            colors: [
                KitoProductColor("cognac", name: "Cognac", swatch: cognac),
                KitoProductColor("black", name: "Black", swatch: ink),
            ],
            variants: [KitoProductVariant(colorID: "cognac", stock: 6), KitoProductVariant(colorID: "black", stock: 2)],
            summary: "A roomy, structured tote with a brass clasp. Fits a 14-inch laptop.",
            sections: standardSections(details: "Two top handles with a 22 cm drop, an inner zip pocket and a magnetic brass clasp.",
                                       materials: ["Vegetable-tanned leather", "Cotton twill lining", "Brass hardware"])
        )
    }()

    /// A pleated midi dress in letter sizes.
    public static let dress: KitoProduct = {
        let wine = KitoProductArtwork.dress(primary: claret, accent: Color(red: 0.2, green: 0.08, blue: 0.1))
        let navy = KitoProductArtwork.dress(primary: midnight, accent: sand)
        let sizes = ["XS", "S", "M", "L", "XL"]
        let wineStock = [2, 8, 11, 5, 0]
        var variants: [KitoProductVariant] = []
        for (index, size) in sizes.enumerated() {
            variants.append(KitoProductVariant(colorID: "claret", sizeID: size, stock: wineStock[index]))
            if index > 0 { variants.append(KitoProductVariant(colorID: "midnight", sizeID: size, stock: 6)) }
        }
        return KitoProduct(
            id: "pleat-midi", name: "Pleated Midi Dress", brand: "Atelier Lumo",
            price: 12_400, rating: 4.4, reviewCount: 58, badges: [.eco],
            media: [
                .artwork(wine, colorID: "claret", accessibilityLabel: "Dress in claret"),
                .artwork(wine.framed(.closeUp), colorID: "claret", accessibilityLabel: "Bodice detail"),
                .artwork(navy, colorID: "midnight", accessibilityLabel: "Dress in midnight"),
            ],
            colors: [
                KitoProductColor("claret", name: "Claret", swatch: claret),
                KitoProductColor("midnight", name: "Midnight", swatch: midnight),
            ],
            sizes: sizes.map { KitoProductSize($0) },
            variants: variants,
            summary: "Knife pleats from a fitted bodice, cut from recycled satin that moves as you do.",
            sections: standardSections(details: "Sweetheart neckline, adjustable straps and a concealed side zip. Falls below the knee.",
                                       materials: ["100% recycled polyester satin", "Machine wash cold, hang to dry"])
        )
    }()

    /// A waxed field jacket.
    public static let jacket: KitoProduct = {
        let green = KitoProductArtwork.jacket(primary: olive, accent: cognac)
        return KitoProduct(
            id: "field-jacket", name: "Waxed Field Jacket", brand: "Northbound Supply",
            price: 21_000, compareAtPrice: 26_000, rating: 4.7, reviewCount: 131, badges: [.lowStock],
            media: [.artwork(green), .artwork(green.framed(.closeUp)), .artwork(green.framed(.angled))],
            colors: [KitoProductColor("olive", name: "Olive", swatch: olive)],
            sizes: KitoProductSize.range(["S", "M", "L", "XL"]),
            variants: [
                KitoProductVariant(colorID: "olive", sizeID: "S", stock: 1),
                KitoProductVariant(colorID: "olive", sizeID: "M", stock: 3),
                KitoProductVariant(colorID: "olive", sizeID: "L", stock: 0),
                KitoProductVariant(colorID: "olive", sizeID: "XL", stock: 2),
            ],
            summary: "Waxed cotton with a corduroy collar. Rain off, character in.",
            sections: standardSections(details: "Two-way zip, storm flap and four patch pockets.",
                                       materials: ["Waxed cotton", "Corduroy collar", "Re-wax once a year"])
        )
    }()

    /// Sunglasses in two frames.
    public static let sunglasses: KitoProduct = {
        let shell = KitoProductArtwork.sunglasses(primary: tortoise, accent: Color(red: 0.3, green: 0.25, blue: 0.2))
        let jet = KitoProductArtwork.sunglasses(primary: ink, accent: Color(red: 0.18, green: 0.24, blue: 0.22))
        return KitoProduct(
            id: "oval-acetate", name: "Oval Acetate Sunglasses", brand: "Studio Rift",
            price: 7_800, rating: 4.3, reviewCount: 42,
            media: [
                .artwork(shell, colorID: "tortoise", accessibilityLabel: "Tortoiseshell frame"),
                .artwork(jet, colorID: "jet", accessibilityLabel: "Black frame"),
            ],
            colors: [
                KitoProductColor("tortoise", name: "Tortoiseshell", swatch: tortoise, secondarySwatch: brass),
                KitoProductColor("jet", name: "Jet", swatch: ink),
            ],
            summary: "Hand-polished acetate with UV400 lenses."
        )
    }()

    /// A scent in a glass bottle, sold out.
    public static let scent: KitoProduct = {
        let amber = KitoProductArtwork.bottle(primary: Color(white: 0.25), accent: brass)
        return KitoProduct(
            id: "dusk-scent", name: "Dusk Eau de Parfum 50 ml", brand: "Maison Tana",
            price: 9_500, rating: 4.9, reviewCount: 305, badges: [.exclusive],
            media: [.artwork(amber), .artwork(amber.framed(.closeUp))],
            variants: [KitoProductVariant(id: "dusk-50", stock: 0)],
            summary: "Smoked cedar, fig leaf and a little amber."
        )
    }()

    /// Every sample product.
    public static let all: [KitoProduct] = [runner, tote, dress, jacket, sunglasses, scent]

    /// Pieces to show under "Complete the look".
    public static let looks: [KitoProduct] = [jacket, tote, sunglasses, dress]

    // MARK: Size guides

    /// A shoe size chart with foot length, fit feedback and measuring tips.
    public static let shoeGuide = KitoSizeGuide(
        title: "Shoe size guide",
        measurements: ["EU", "Foot (cm)"],
        rows: [
            KitoSizeGuideRow("UK 6", values: [39, 24.6]),
            KitoSizeGuideRow("UK 7", values: [40.5, 25.4]),
            KitoSizeGuideRow("UK 8", values: [42, 26.2]),
            KitoSizeGuideRow("UK 9", values: [43, 27.1]),
            KitoSizeGuideRow("UK 10", values: [44.5, 27.9]),
            KitoSizeGuideRow("UK 11", values: [45.5, 28.8]),
        ],
        allowsInches: false,
        howToMeasure: [
            KitoMeasureStep("Stand on paper", detail: "Heel against a wall, weight on both feet.", systemImage: "figure.stand"),
            KitoMeasureStep("Mark your longest toe", detail: "Measure from the wall to the mark in centimetres.", systemImage: "ruler"),
            KitoMeasureStep("Pick the next size up", detail: "If you're between sizes, or measuring late in the day.", systemImage: "arrow.up.right"),
        ],
        fit: KitoFitFeedback(value: 0.35, reviewCount: 214)
    )

    /// A clothing chart in centimetres that can switch to inches.
    public static let apparelGuide = KitoSizeGuide(
        measurements: ["Bust", "Waist", "Hip"],
        rows: [
            KitoSizeGuideRow("XS", values: [80, 62, 88]),
            KitoSizeGuideRow("S", values: [84, 66, 92]),
            KitoSizeGuideRow("M", values: [88, 70, 96]),
            KitoSizeGuideRow("L", values: [94, 76, 102]),
            KitoSizeGuideRow("XL", values: [100, 82, 108]),
        ],
        howToMeasure: [
            KitoMeasureStep("Bust", detail: "Around the fullest part, keeping the tape level.", systemImage: "circle.dashed"),
            KitoMeasureStep("Waist", detail: "Around the narrowest part of your natural waist.", systemImage: "arrow.left.and.right"),
            KitoMeasureStep("Hip", detail: "Around the fullest part, feet together.", systemImage: "ruler"),
        ],
        fit: KitoFitFeedback(value: -0.1, reviewCount: 58)
    )

    // MARK: Helpers

    static func standardSections(details: String, materials: [String]) -> [KitoProductInfoSection] {
        [
            KitoProductInfoSection("Details", body: details, systemImage: "text.alignleft"),
            KitoProductInfoSection("Materials & care", bullets: materials, systemImage: "leaf"),
            KitoProductInfoSection("Shipping & returns",
                                   body: "Free delivery on orders over KES 5,000. Free returns within 30 days, collected from your door.",
                                   systemImage: "shippingbox"),
        ]
    }
}
