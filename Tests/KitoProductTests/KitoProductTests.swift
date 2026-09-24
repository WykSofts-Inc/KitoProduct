//
//  KitoProductTests.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
@testable import KitoProduct

// MARK: - Variant matrix

final class KitoVariantMatrixTests: XCTestCase {
    private let runner = KitoProductSamples.runner
    private var matrix: KitoVariantMatrix { KitoVariantMatrix(runner) }

    func testSizeLevelsForAColour() {
        let levels = matrix.sizeOptions(for: "black").map(\.level)
        XCTAssertEqual(levels, [.sellingFast(4), .inStock, .low(2), .soldOut, .sellingFast(7), .low(1)])
    }

    func testSizesNotMadeInAColourAreUnavailable() {
        let sand = matrix.sizeOptions(for: "sand")
        XCTAssertEqual(sand.last?.level, .unavailable)
        XCTAssertNil(sand.last?.variant)
        XCTAssertEqual(matrix.sizes(for: "sand").map(\.id), ["UK 6", "UK 7", "UK 8", "UK 9", "UK 10"])
        XCTAssertEqual(matrix.sizes(for: "black").count, 6)
    }

    func testStockIsAddedUpAcrossColoursWithoutAColour() {
        XCTAssertEqual(matrix.sizeOptions(for: nil).first?.level, .sellingFast(4))
        XCTAssertEqual(matrix.stockLevel(color: nil, size: "UK 9"), .inStock)
    }

    func testColourSoldOut() {
        XCTAssertTrue(matrix.isSoldOut(color: "olive"))
        XCTAssertFalse(matrix.isSoldOut(color: "sand"))
        XCTAssertEqual(matrix.colorOptions().map(\.isSoldOut), [false, false, true])
        XCTAssertFalse(matrix.isSoldOut)
    }

    func testVariantLookup() {
        XCTAssertEqual(matrix.variant(color: "black", size: "UK 8")?.stock, 2)
        XCTAssertNil(matrix.variant(color: "sand", size: "UK 11"))
    }

    func testInitialSelectionSkipsSoldOutColoursAndPicksTheOnlySize() {
        XCTAssertEqual(matrix.initialSelection(), KitoProductSelection(colorID: "black"))
        let jacket = KitoVariantMatrix(KitoProductSamples.jacket).initialSelection()
        XCTAssertEqual(jacket.colorID, "olive")
        XCTAssertNil(jacket.sizeID)

        let oneSize = KitoProduct(id: "cap", name: "Cap", brand: "B", price: 10,
                                  colors: [KitoProductColor("red", name: "Red", swatch: .red)],
                                  sizes: [KitoProductSize("One size")],
                                  variants: [KitoProductVariant(colorID: "red", sizeID: "One size", stock: 3)])
        XCTAssertEqual(KitoVariantMatrix(oneSize).initialSelection().sizeID, "One size")
    }

    func testChangingColourKeepsOrClearsTheSize() {
        let keep = matrix.selecting(color: "sand", in: KitoProductSelection(colorID: "black", sizeID: "UK 9"))
        XCTAssertEqual(keep.sizeID, "UK 9")
        let clear = matrix.selecting(color: "sand", in: KitoProductSelection(colorID: "black", sizeID: "UK 11"))
        XCTAssertNil(clear.sizeID)
        XCTAssertEqual(clear.colorID, "sand")
    }

    func testProductWithoutVariantsIsAlwaysAvailable() throws {
        let simple = KitoProduct(id: "tee", name: "Tee", brand: "B", price: 100, sizes: KitoProductSize.range(["S", "M"]))
        let matrix = KitoVariantMatrix(simple)
        XCTAssertEqual(matrix.sizeOptions(for: nil).map(\.level), [.inStock, .inStock])
        let variant = try matrix.validate(KitoProductSelection(sizeID: "M")).get()
        XCTAssertEqual(variant.id, "tee-M")
    }

    func testVariantPriceOverridesProductPrice() {
        let product = KitoProduct(id: "p", name: "P", brand: "B", price: 100, sizes: KitoProductSize.range(["S", "XL"]),
                                  variants: [KitoProductVariant(sizeID: "S", stock: 1),
                                             KitoProductVariant(sizeID: "XL", stock: 1, price: 120)])
        let matrix = KitoVariantMatrix(product)
        XCTAssertEqual(matrix.price(for: KitoProductSelection(sizeID: "S")), 100)
        XCTAssertEqual(matrix.price(for: KitoProductSelection(sizeID: "XL")), 120)
    }
}

// MARK: - Selection validation

final class KitoSelectionValidationTests: XCTestCase {
    private let matrix = KitoVariantMatrix(KitoProductSamples.runner)

    func testMissingSize() {
        XCTAssertEqual(matrix.validate(KitoProductSelection(colorID: "black")), .failure(.chooseSize))
        XCTAssertEqual(KitoSelectionIssue.chooseSize.message, "Choose a size")
    }

    func testMissingColour() {
        XCTAssertEqual(matrix.validate(KitoProductSelection(sizeID: "UK 8")), .failure(.chooseColor))
        XCTAssertEqual(KitoSelectionIssue.chooseColor.message, "Choose a colour")
    }

    func testSoldOutAndUnavailable() {
        XCTAssertEqual(matrix.validate(KitoProductSelection(colorID: "black", sizeID: "UK 9")), .failure(.soldOut))
        XCTAssertEqual(matrix.validate(KitoProductSelection(colorID: "sand", sizeID: "UK 11")), .failure(.unavailable))
    }

    func testUnknownSizeCountsAsMissing() {
        XCTAssertEqual(matrix.validate(KitoProductSelection(colorID: "black", sizeID: "UK 14")), .failure(.chooseSize))
    }

    func testValidSelection() throws {
        let variant = try matrix.validate(KitoProductSelection(colorID: "black", sizeID: "UK 8")).get()
        XCTAssertEqual(variant.id, "black-UK 8")
    }

    func testProductWithoutSizes() throws {
        let tote = KitoVariantMatrix(KitoProductSamples.tote)
        XCTAssertEqual(try tote.validate(KitoProductSelection(colorID: "black")).get().id, "black")
        let scent = KitoVariantMatrix(KitoProductSamples.scent)
        XCTAssertEqual(scent.validate(KitoProductSelection()), .failure(.soldOut))
        XCTAssertTrue(scent.isSoldOut)
    }

    func testQuantityIsAtLeastOne() {
        XCTAssertEqual(KitoProductSelection(quantity: 0).quantity, 1)
    }
}

// MARK: - Prices

final class KitoPriceMathTests: XCTestCase {
    func testDiscountPercentRoundsDown() {
        XCTAssertEqual(KitoPriceMath.discountPercent(price: 9_900, compareAt: 13_200), 25)
        XCTAssertEqual(KitoPriceMath.discountPercent(price: 7_999, compareAt: 9_999), 20)
        XCTAssertEqual(KitoPriceMath.discountPercent(price: 6_700, compareAt: 10_000), 33)
    }

    func testNoDiscount() {
        XCTAssertNil(KitoPriceMath.discountPercent(price: 100, compareAt: nil))
        XCTAssertNil(KitoPriceMath.discountPercent(price: 100, compareAt: 100))
        XCTAssertNil(KitoPriceMath.discountPercent(price: 120, compareAt: 100))
        XCTAssertNil(KitoPriceMath.discountPercent(price: Decimal(string: "99.5")!, compareAt: 100))
    }

    func testSavingsAndSalePrice() {
        XCTAssertEqual(KitoPriceMath.savings(price: 9_900, compareAt: 13_200), 3_300)
        XCTAssertNil(KitoPriceMath.savings(price: 9_900, compareAt: nil))
        XCTAssertEqual(KitoPriceMath.salePrice(from: 10_000, percentOff: 15), 8_500)
        XCTAssertEqual(KitoPriceMath.salePrice(from: 999, percentOff: 33), 669)
        XCTAssertEqual(KitoPriceMath.salePrice(from: 500, percentOff: 150), 0)
    }

    func testInstalmentsRoundUpToCoverTheTotal() {
        XCTAssertEqual(KitoPriceMath.instalment(of: 9_900, count: 4), 2_475)
        XCTAssertEqual(KitoPriceMath.instalment(of: 10_000, count: 3), 3_334)
        XCTAssertEqual(KitoPriceMath.instalment(of: Decimal(string: "1000.5")!, count: 2, increment: Decimal(string: "0.01")!),
                       Decimal(string: "500.25")!)
        XCTAssertEqual(KitoPriceMath.instalment(of: 500, count: 0), 500)
    }

    func testMoneyFormatting() {
        XCTAssertEqual(KitoMoney.string(9_900), "KES 9,900")
        XCTAssertEqual(KitoMoney.string(1_234_567, currencyCode: "USD"), "USD 1,234,567")
        XCTAssertEqual(KitoMoney.string(Decimal(string: "1250.5")!), "KES 1,250.50")
        XCTAssertEqual(KitoMoney.string(45, currencyCode: ""), "45")
        XCTAssertEqual(KitoMoney.instalmentLine(total: 9_900, count: 4), "or 4 × KES 2,475")
    }

    func testProductIsOnSale() {
        XCTAssertTrue(KitoProductSamples.runner.isOnSale)
        XCTAssertFalse(KitoProductSamples.tote.isOnSale)
    }
}

// MARK: - Delivery

final class KitoDeliveryEstimatorTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Africa/Nairobi")!
        return calendar
    }()

    private func date(_ day: Int, month: Int = 9, _ hour: Int = 10, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }

    private func estimator(_ min: Int, _ max: Int? = nil, holidays: [Date] = []) -> KitoDeliveryEstimator {
        KitoDeliveryEstimator(minDays: min, maxDays: max, cutoffHour: 14, holidays: holidays, calendar: calendar)
    }

    func testBeforeCutoffDispatchesToday() {
        // Thursday 24 September 2026, 10:00.
        let estimate = estimator(1, 2).estimate(from: date(24))
        XCTAssertTrue(calendar.isDate(estimate.earliest, inSameDayAs: date(25)))
        XCTAssertTrue(calendar.isDate(estimate.latest, inSameDayAs: date(28)))
        XCTAssertEqual(estimate.title, "Get it Fri 25 – Mon 28 Sep")
        XCTAssertEqual(estimate.countdown, "Order within 4 h")
    }

    func testAfterCutoffDispatchesNextWorkingDay() {
        let estimate = estimator(1, 2).estimate(from: date(24, 15))
        XCTAssertTrue(calendar.isDate(estimate.earliest, inSameDayAs: date(28)))
        XCTAssertTrue(calendar.isDate(estimate.latest, inSameDayAs: date(29)))
        XCTAssertNil(estimate.countdown)
    }

    func testWeekendOrdersCountFromMonday() {
        let estimate = estimator(1).estimate(from: date(26, 9))
        XCTAssertTrue(calendar.isDate(estimator(1).dispatchDate(for: date(26, 9)), inSameDayAs: date(28)))
        XCTAssertEqual(estimate.title, "Get it by Tue 29 Sep")
        XCTAssertNil(estimate.countdown)
    }

    func testHolidaysAreSkipped() {
        let estimate = estimator(1, holidays: [date(25, 0)]).estimate(from: date(24))
        XCTAssertTrue(calendar.isDate(estimate.earliest, inSameDayAs: date(28)))
    }

    func testTodayAndTomorrow() {
        XCTAssertEqual(estimator(0).estimate(from: date(24)).title, "Get it today")
        XCTAssertEqual(estimator(1).estimate(from: date(24)).title, "Get it tomorrow")
    }

    func testRangeAcrossMonths() {
        let estimate = estimator(1, 3).estimate(from: date(29))
        XCTAssertEqual(estimate.title, "Get it Wed 30 Sep – Fri 2 Oct")
    }

    func testCountdownWording() {
        XCTAssertEqual(estimator(1).estimate(from: date(24, 10, 48)).countdown, "Order within 3 h 12 min")
        XCTAssertEqual(estimator(1).estimate(from: date(24, 13, 30)).countdown, "Order within 30 min")
    }

    func testAddingWorkingDays() {
        let e = estimator(1)
        XCTAssertTrue(calendar.isDate(e.adding(workingDays: 3, to: date(25)), inSameDayAs: date(30)))
        XCTAssertTrue(calendar.isDate(e.adding(workingDays: 0, to: date(25)), inSameDayAs: date(25)))
        XCTAssertFalse(e.isWorkingDay(date(27)))
    }

    func testMaxNeverBelowMin() {
        let e = KitoDeliveryEstimator(minDays: 3, maxDays: 1, calendar: calendar)
        XCTAssertEqual(e.maxDays, 3)
    }
}

// MARK: - Stock

final class KitoStockLevelTests: XCTestCase {
    func testDefaultThresholds() {
        XCTAssertEqual(KitoStockLevel.level(for: 0), .soldOut)
        XCTAssertEqual(KitoStockLevel.level(for: -2), .soldOut)
        XCTAssertEqual(KitoStockLevel.level(for: 1), .low(1))
        XCTAssertEqual(KitoStockLevel.level(for: 3), .low(3))
        XCTAssertEqual(KitoStockLevel.level(for: 4), .sellingFast(4))
        XCTAssertEqual(KitoStockLevel.level(for: 10), .sellingFast(10))
        XCTAssertEqual(KitoStockLevel.level(for: 11), .inStock)
        XCTAssertEqual(KitoStockLevel.level(for: nil), .inStock)
    }

    func testCustomThresholds() {
        let thresholds = KitoStockThresholds(low: 5, sellingFast: nil)
        XCTAssertEqual(KitoStockLevel.level(for: 5, thresholds: thresholds), .low(5))
        XCTAssertEqual(KitoStockLevel.level(for: 6, thresholds: thresholds), .inStock)
        XCTAssertEqual(KitoStockThresholds(low: 8, sellingFast: 4).sellingFast, 8)
    }

    func testMessages() {
        XCTAssertEqual(KitoStockLevel.inStock.message, "In stock")
        XCTAssertEqual(KitoStockLevel.sellingFast(6).message, "Selling fast")
        XCTAssertEqual(KitoStockLevel.low(2).message, "Only 2 left")
        XCTAssertEqual(KitoStockLevel.low(1).message, "Last one")
        XCTAssertEqual(KitoStockLevel.soldOut.message, "Sold out")
        XCTAssertEqual(KitoStockLevel.low(2).hint(for: "UK 8"), "Only 2 left in UK 8")
        XCTAssertEqual(KitoStockLevel.low(1).hint(for: "M"), "Last one in M")
        XCTAssertNil(KitoStockLevel.inStock.hint(for: "M"))
    }

    func testPurchasable() {
        XCTAssertTrue(KitoStockLevel.low(1).isPurchasable)
        XCTAssertFalse(KitoStockLevel.soldOut.isPurchasable)
        XCTAssertFalse(KitoStockLevel.unavailable.isPurchasable)
        XCTAssertTrue(KitoStockLevel.sellingFast(5).isUrgent)
        XCTAssertFalse(KitoStockLevel.inStock.isUrgent)
    }
}

// MARK: - Size guide and fit

final class KitoSizeGuideTests: XCTestCase {
    func testFitLabels() {
        XCTAssertEqual(KitoFitFeedback(value: 0).label, "True to size")
        XCTAssertEqual(KitoFitFeedback(value: 0.35).label, "Runs slightly large")
        XCTAssertEqual(KitoFitFeedback(value: -0.4).label, "Runs slightly small")
        XCTAssertEqual(KitoFitFeedback(votes: [-1, -1, -1]).label, "Runs small")
        XCTAssertEqual(KitoFitFeedback(value: 3).value, 1)
        XCTAssertEqual(KitoFitFeedback(value: 0.5).position, 0.75, accuracy: 0.0001)
        XCTAssertEqual(KitoFitFeedback(votes: [1, 0, 1, 0]).reviewCount, 4)
    }

    func testMeasurementFormatting() {
        XCTAssertEqual(KitoSizeGuide.format(96, inches: false), "96")
        XCTAssertEqual(KitoSizeGuide.format(24.6, inches: false), "24.6")
        XCTAssertEqual(KitoSizeGuide.format(96, inches: true), "37.8")
        XCTAssertEqual(KitoSizeGuide.format(25.4, inches: true), "10")
    }
}

// MARK: - Models, cart and artwork

final class KitoProductModelTests: XCTestCase {
    func testMediaForColour() {
        let runner = KitoProductSamples.runner
        XCTAssertEqual(runner.media(for: "sand").count, 3)
        XCTAssertEqual(runner.media(for: nil).count, runner.media.count)
        XCTAssertEqual(KitoProductSamples.jacket.media(for: "olive").count, 3)
    }

    func testCartItem() {
        let runner = KitoProductSamples.runner
        let variant = KitoProductVariant(colorID: "black", sizeID: "UK 8", stock: 2)
        let item = runner.cartItem(for: variant, quantity: 2)
        XCTAssertEqual(item.id, "black-UK 8")
        XCTAssertEqual(item.subtitle, "Black / Ember · UK 8")
        XCTAssertEqual(item.unitPrice, 9_900)
        XCTAssertEqual(item.quantity, 2)
        XCTAssertNil(item.imageURL)
    }

    func testCartItemUsesPhotoURLAndVariantPrice() {
        let url = URL(string: "https://example.com/p.jpg")!
        let product = KitoProduct(id: "p", name: "P", brand: "B", price: 100, media: [.image(url)])
        let item = product.cartItem(for: KitoProductVariant(id: "p-1", price: 80))
        XCTAssertEqual(item.imageURL, url)
        XCTAssertEqual(item.unitPrice, 80)
        XCTAssertNil(item.subtitle)
    }

    func testSpinFrames() {
        let frames = KitoProductArtwork.sneaker(primary: .black, accent: .white).spin(frames: 12)
        XCTAssertEqual(frames.count, 12)
        XCTAssertEqual(Set(frames.map(\.id)).count, 12)
        if case .artwork(let art) = frames[3].source {
            XCTAssertEqual(art.rotation, 90)
        } else {
            XCTFail("Expected artwork")
        }
    }

    func testTotalStock() {
        XCTAssertEqual(KitoProductSamples.jacket.totalStock, 6)
        XCTAssertNil(KitoProductSamples.sunglasses.totalStock)
    }

    func testBadges() {
        XCTAssertEqual(KitoProductBadge.sale(percent: 25).text, "−25%")
        XCTAssertEqual(KitoProductBadge.eco.kind, .eco)
    }
}

// MARK: - Detail model

final class KitoProductDetailModelTests: XCTestCase {
    func testAddWithoutSizeRecordsTheIssue() {
        let model = KitoProductDetailModel(KitoProductSamples.runner)
        XCTAssertNil(model.addToBag())
        XCTAssertEqual(model.issue, .chooseSize)
        XCTAssertEqual(model.failedAttempts, 1)
        XCTAssertNil(model.addToBag())
        XCTAssertEqual(model.failedAttempts, 2)
        model.selectSize("UK 8")
        XCTAssertNil(model.issue)
    }

    func testAddFlow() {
        let model = KitoProductDetailModel(KitoProductSamples.runner)
        model.selectSize("UK 8")
        XCTAssertEqual(model.stockLevel, .low(2))
        XCTAssertEqual(model.addToBag()?.id, "black-UK 8")
        XCTAssertEqual(model.addState, .adding)
        model.finishAdding()
        XCTAssertEqual(model.addState, .added)
        XCTAssertEqual(model.bagCount, 1)
        model.settle()
        XCTAssertEqual(model.addState, .idle)
    }

    func testSoldOutSizeRestsAsSoldOut() {
        let model = KitoProductDetailModel(KitoProductSamples.runner)
        model.selectSize("UK 9")
        XCTAssertEqual(model.addState, .soldOut)
        model.selectColor("sand")
        XCTAssertEqual(model.selection.sizeID, "UK 9")
        XCTAssertEqual(model.addState, .idle)
        XCTAssertEqual(model.galleryMedia.count, 3)
    }

    func testSoldOutProduct() {
        XCTAssertEqual(KitoProductDetailModel(KitoProductSamples.scent).restingState, .soldOut)
    }
}
