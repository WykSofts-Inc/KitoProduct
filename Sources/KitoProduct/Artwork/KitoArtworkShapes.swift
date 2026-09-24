//
//  KitoArtworkShapes.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

/// Maps unit coordinates (0…1 across the object's box) into a rect.
struct UnitSpace {
    let rect: CGRect

    func callAsFunction(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
    }
}

/// Every piece the artwork is drawn from, each a path in its object's unit box.
enum ArtworkPart: Sendable {
    // Sneaker
    case sneakerOutsole, sneakerMidsole, sneakerUpper, sneakerToeCap, sneakerHeel, sneakerCollar
    case sneakerLaces, sneakerStitch, sneakerPanel
    // Tote
    case toteHandleBack, toteHandleFront, toteBody, toteBand, toteClasp, toteSeams
    // Dress
    case dressHanger, dressStraps, dressBodice, dressBelt, dressSkirt, dressPleats
    // Jacket
    case jacketSleeves, jacketBody, jacketLapels, jacketZip, jacketPockets, jacketHem
    // Sunglasses
    case glassesLenses, glassesFrame, glassesBridge, glassesGlint
    // Bottle
    case bottleCap, bottleNeck, bottleGlass, bottleLiquid, bottleLabel, bottleGlint
}

struct ArtworkShape: Shape {
    let part: ArtworkPart

    func path(in rect: CGRect) -> Path {
        let u = UnitSpace(rect: rect)
        var path = Path()
        switch part {
        case .sneakerOutsole, .sneakerMidsole, .sneakerUpper, .sneakerToeCap, .sneakerHeel,
             .sneakerCollar, .sneakerLaces, .sneakerStitch, .sneakerPanel:
            SneakerPaths.add(part, to: &path, u)
        case .toteHandleBack, .toteHandleFront, .toteBody, .toteBand, .toteClasp, .toteSeams:
            TotePaths.add(part, to: &path, u)
        case .dressHanger, .dressStraps, .dressBodice, .dressBelt, .dressSkirt, .dressPleats:
            DressPaths.add(part, to: &path, u)
        case .jacketSleeves, .jacketBody, .jacketLapels, .jacketZip, .jacketPockets, .jacketHem:
            JacketPaths.add(part, to: &path, u)
        case .glassesLenses, .glassesFrame, .glassesBridge, .glassesGlint:
            GlassesPaths.add(part, to: &path, u)
        case .bottleCap, .bottleNeck, .bottleGlass, .bottleLiquid, .bottleLabel, .bottleGlint:
            BottlePaths.add(part, to: &path, u)
        }
        return path
    }
}

// MARK: - Sneaker (box 2 : 1)

enum SneakerPaths {
    static func add(_ part: ArtworkPart, to p: inout Path, _ u: UnitSpace) {
        switch part {
        case .sneakerOutsole: outsole(&p, u)
        case .sneakerMidsole: midsole(&p, u)
        case .sneakerUpper: upper(&p, u)
        case .sneakerToeCap: toeCap(&p, u)
        case .sneakerHeel: heel(&p, u)
        case .sneakerCollar: collar(&p, u)
        case .sneakerLaces: laces(&p, u)
        case .sneakerStitch: stitch(&p, u)
        case .sneakerPanel: panel(&p, u)
        default: break
        }
    }

    static func outsole(_ p: inout Path, _ u: UnitSpace) {
        p.move(to: u(0.03, 0.83))
        p.addLine(to: u(0.93, 0.83))
        p.addQuadCurve(to: u(0.985, 0.90), control: u(0.99, 0.83))
        p.addQuadCurve(to: u(0.93, 0.97), control: u(0.98, 0.97))
        p.addLine(to: u(0.07, 0.97))
        p.addQuadCurve(to: u(0.015, 0.90), control: u(0.015, 0.97))
        p.addQuadCurve(to: u(0.03, 0.83), control: u(0.015, 0.84))
        p.closeSubpath()
    }

    static func midsole(_ p: inout Path, _ u: UnitSpace) {
        p.move(to: u(0.04, 0.70))
        p.addLine(to: u(0.62, 0.72))
        p.addQuadCurve(to: u(0.965, 0.76), control: u(0.88, 0.72))
        p.addQuadCurve(to: u(0.975, 0.85), control: u(0.995, 0.80))
        p.addLine(to: u(0.025, 0.85))
        p.addQuadCurve(to: u(0.04, 0.70), control: u(0.01, 0.76))
        p.closeSubpath()
    }

    static func upper(_ p: inout Path, _ u: UnitSpace) {
        p.move(to: u(0.05, 0.74))
        p.addCurve(to: u(0.09, 0.30), control1: u(0.02, 0.56), control2: u(0.04, 0.36))
        p.addQuadCurve(to: u(0.30, 0.27), control: u(0.19, 0.20))
        p.addQuadCurve(to: u(0.41, 0.36), control: u(0.37, 0.37))
        p.addLine(to: u(0.45, 0.17))
        p.addQuadCurve(to: u(0.53, 0.19), control: u(0.50, 0.12))
        p.addQuadCurve(to: u(0.79, 0.52), control: u(0.63, 0.40))
        p.addQuadCurve(to: u(0.97, 0.70), control: u(0.95, 0.56))
        p.addQuadCurve(to: u(0.96, 0.77), control: u(0.99, 0.75))
        p.addLine(to: u(0.05, 0.77))
        p.closeSubpath()
    }

    static func toeCap(_ p: inout Path, _ u: UnitSpace) {
        p.move(to: u(0.80, 0.53))
        p.addQuadCurve(to: u(0.97, 0.70), control: u(0.95, 0.56))
        p.addQuadCurve(to: u(0.96, 0.77), control: u(0.99, 0.75))
        p.addLine(to: u(0.74, 0.77))
        p.addQuadCurve(to: u(0.80, 0.53), control: u(0.71, 0.62))
        p.closeSubpath()
    }

    static func heel(_ p: inout Path, _ u: UnitSpace) {
        p.move(to: u(0.05, 0.74))
        p.addCurve(to: u(0.08, 0.40), control1: u(0.03, 0.60), control2: u(0.05, 0.47))
        p.addQuadCurve(to: u(0.25, 0.52), control: u(0.21, 0.40))
        p.addQuadCurve(to: u(0.23, 0.77), control: u(0.27, 0.66))
        p.addLine(to: u(0.05, 0.77))
        p.closeSubpath()
    }

    static func collar(_ p: inout Path, _ u: UnitSpace) {
        p.move(to: u(0.10, 0.31))
        p.addQuadCurve(to: u(0.30, 0.29), control: u(0.19, 0.23))
        p.addQuadCurve(to: u(0.40, 0.36), control: u(0.36, 0.37))
    }

    static func laces(_ p: inout Path, _ u: UnitSpace) {
        for index in 0..<5 {
            let t = CGFloat(index) / 4
            let x = 0.515 + t * 0.215
            let y = 0.285 + t * 0.235
            p.move(to: u(x - 0.03, y + 0.04))
            p.addLine(to: u(x + 0.03, y - 0.035))
        }
    }

    static func stitch(_ p: inout Path, _ u: UnitSpace) {
        p.move(to: u(0.06, 0.68))
        p.addQuadCurve(to: u(0.94, 0.72), control: u(0.60, 0.66))
    }

    static func panel(_ p: inout Path, _ u: UnitSpace) {
        p.move(to: u(0.22, 0.77))
        p.addQuadCurve(to: u(0.40, 0.56), control: u(0.24, 0.58))
        p.addQuadCurve(to: u(0.72, 0.60), control: u(0.58, 0.54))
        p.addQuadCurve(to: u(0.78, 0.77), control: u(0.80, 0.64))
        p.closeSubpath()
    }
}

// MARK: - Tote (box 1 : 1)

enum TotePaths {
    static func add(_ part: ArtworkPart, to p: inout Path, _ u: UnitSpace) {
        switch part {
        case .toteHandleBack:
            p.move(to: u(0.34, 0.36))
            p.addCurve(to: u(0.66, 0.36), control1: u(0.34, 0.04), control2: u(0.66, 0.04))
        case .toteHandleFront:
            p.move(to: u(0.29, 0.40))
            p.addCurve(to: u(0.71, 0.40), control1: u(0.27, 0.02), control2: u(0.73, 0.02))
        case .toteBody:
            p.move(to: u(0.16, 0.34))
            p.addLine(to: u(0.84, 0.34))
            p.addLine(to: u(0.94, 0.91))
            p.addQuadCurve(to: u(0.88, 0.98), control: u(0.945, 0.98))
            p.addLine(to: u(0.12, 0.98))
            p.addQuadCurve(to: u(0.06, 0.91), control: u(0.055, 0.98))
            p.closeSubpath()
        case .toteBand:
            p.move(to: u(0.16, 0.34))
            p.addLine(to: u(0.84, 0.34))
            p.addLine(to: u(0.855, 0.43))
            p.addLine(to: u(0.145, 0.43))
            p.closeSubpath()
        case .toteClasp:
            p.addRoundedRect(in: CGRect(origin: u(0.455, 0.40), size: CGSize(width: u.rect.width * 0.09, height: u.rect.height * 0.08)),
                             cornerSize: CGSize(width: u.rect.width * 0.02, height: u.rect.width * 0.02))
        case .toteSeams:
            p.move(to: u(0.25, 0.44))
            p.addLine(to: u(0.20, 0.96))
            p.move(to: u(0.75, 0.44))
            p.addLine(to: u(0.80, 0.96))
            p.move(to: u(0.09, 0.90))
            p.addLine(to: u(0.91, 0.90))
        default: break
        }
    }
}

// MARK: - Dress (box 0.62 : 1)

enum DressPaths {
    static func add(_ part: ArtworkPart, to p: inout Path, _ u: UnitSpace) {
        switch part {
        case .dressHanger: hanger(&p, u)
        case .dressStraps:
            p.move(to: u(0.37, 0.10))
            p.addLine(to: u(0.38, 0.20))
            p.move(to: u(0.63, 0.10))
            p.addLine(to: u(0.62, 0.20))
        case .dressBodice:
            p.move(to: u(0.34, 0.18))
            p.addQuadCurve(to: u(0.50, 0.24), control: u(0.42, 0.26))
            p.addQuadCurve(to: u(0.66, 0.18), control: u(0.58, 0.26))
            p.addQuadCurve(to: u(0.62, 0.45), control: u(0.69, 0.32))
            p.addLine(to: u(0.38, 0.45))
            p.addQuadCurve(to: u(0.34, 0.18), control: u(0.31, 0.32))
            p.closeSubpath()
        case .dressBelt:
            p.addRect(CGRect(origin: u(0.37, 0.43), size: CGSize(width: u.rect.width * 0.26, height: u.rect.height * 0.035)))
        case .dressSkirt:
            p.move(to: u(0.38, 0.46))
            p.addLine(to: u(0.62, 0.46))
            p.addQuadCurve(to: u(0.92, 0.95), control: u(0.77, 0.64))
            p.addQuadCurve(to: u(0.08, 0.95), control: u(0.50, 1.02))
            p.addQuadCurve(to: u(0.38, 0.46), control: u(0.23, 0.64))
            p.closeSubpath()
        case .dressPleats:
            for index in 1...6 {
                let t = CGFloat(index) / 7
                p.move(to: u(0.38 + t * 0.24, 0.48))
                p.addLine(to: u(0.10 + t * 0.80, 0.96))
            }
        default: break
        }
    }

    static func hanger(_ p: inout Path, _ u: UnitSpace) {
        p.move(to: u(0.50, 0.07))
        p.addLine(to: u(0.50, 0.04))
        p.addQuadCurve(to: u(0.545, 0.005), control: u(0.55, 0.04))
        p.move(to: u(0.50, 0.07))
        p.addLine(to: u(0.28, 0.13))
        p.addLine(to: u(0.72, 0.13))
        p.closeSubpath()
    }
}

// MARK: - Jacket (box 1 : 1)

enum JacketPaths {
    static func add(_ part: ArtworkPart, to p: inout Path, _ u: UnitSpace) {
        switch part {
        case .jacketSleeves:
            p.move(to: u(0.28, 0.13))
            p.addLine(to: u(0.12, 0.28))
            p.addLine(to: u(0.05, 0.86))
            p.addLine(to: u(0.17, 0.88))
            p.addLine(to: u(0.25, 0.44))
            p.closeSubpath()
            p.move(to: u(0.72, 0.13))
            p.addLine(to: u(0.88, 0.28))
            p.addLine(to: u(0.95, 0.86))
            p.addLine(to: u(0.83, 0.88))
            p.addLine(to: u(0.75, 0.44))
            p.closeSubpath()
        case .jacketBody:
            p.move(to: u(0.28, 0.12))
            p.addLine(to: u(0.40, 0.07))
            p.addQuadCurve(to: u(0.60, 0.07), control: u(0.50, 0.13))
            p.addLine(to: u(0.72, 0.12))
            p.addLine(to: u(0.77, 0.94))
            p.addLine(to: u(0.23, 0.94))
            p.closeSubpath()
        case .jacketLapels:
            p.move(to: u(0.40, 0.07))
            p.addLine(to: u(0.50, 0.34))
            p.addLine(to: u(0.35, 0.24))
            p.closeSubpath()
            p.move(to: u(0.60, 0.07))
            p.addLine(to: u(0.50, 0.34))
            p.addLine(to: u(0.65, 0.24))
            p.closeSubpath()
        case .jacketZip:
            p.move(to: u(0.50, 0.30))
            p.addLine(to: u(0.50, 0.94))
        case .jacketPockets:
            let size = CGSize(width: u.rect.width * 0.14, height: u.rect.height * 0.035)
            let corner = CGSize(width: u.rect.width * 0.01, height: u.rect.width * 0.01)
            p.addRoundedRect(in: CGRect(origin: u(0.29, 0.60), size: size), cornerSize: corner)
            p.addRoundedRect(in: CGRect(origin: u(0.57, 0.60), size: size), cornerSize: corner)
        case .jacketHem:
            p.move(to: u(0.232, 0.89))
            p.addLine(to: u(0.768, 0.89))
            p.addLine(to: u(0.77, 0.94))
            p.addLine(to: u(0.23, 0.94))
            p.closeSubpath()
        default: break
        }
    }
}

// MARK: - Sunglasses (box 2.6 : 1)

enum GlassesPaths {
    static func add(_ part: ArtworkPart, to p: inout Path, _ u: UnitSpace) {
        switch part {
        case .glassesLenses, .glassesFrame:
            lens(&p, u, x: 0.04)
            lens(&p, u, x: 0.56)
        case .glassesBridge:
            p.move(to: u(0.44, 0.36))
            p.addQuadCurve(to: u(0.56, 0.36), control: u(0.50, 0.18))
            p.move(to: u(0.04, 0.30))
            p.addLine(to: u(0.0, 0.26))
            p.move(to: u(0.96, 0.30))
            p.addLine(to: u(1.0, 0.26))
        case .glassesGlint:
            p.move(to: u(0.10, 0.62))
            p.addLine(to: u(0.22, 0.30))
            p.addLine(to: u(0.28, 0.30))
            p.addLine(to: u(0.16, 0.62))
            p.closeSubpath()
            p.move(to: u(0.62, 0.62))
            p.addLine(to: u(0.74, 0.30))
            p.addLine(to: u(0.80, 0.30))
            p.addLine(to: u(0.68, 0.62))
            p.closeSubpath()
        default: break
        }
    }

    static func lens(_ p: inout Path, _ u: UnitSpace, x: CGFloat) {
        p.move(to: u(x, 0.34))
        p.addQuadCurve(to: u(x + 0.40, 0.30), control: u(x + 0.20, 0.20))
        p.addQuadCurve(to: u(x + 0.34, 0.86), control: u(x + 0.44, 0.78))
        p.addQuadCurve(to: u(x + 0.04, 0.80), control: u(x + 0.16, 0.96))
        p.addQuadCurve(to: u(x, 0.34), control: u(x - 0.03, 0.62))
        p.closeSubpath()
    }
}

// MARK: - Bottle (box 0.6 : 1)

enum BottlePaths {
    static func add(_ part: ArtworkPart, to p: inout Path, _ u: UnitSpace) {
        let w = u.rect.width
        let h = u.rect.height
        switch part {
        case .bottleCap:
            p.addRoundedRect(in: CGRect(origin: u(0.32, 0.02), size: CGSize(width: w * 0.36, height: h * 0.18)),
                             cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
        case .bottleNeck:
            p.addRect(CGRect(origin: u(0.40, 0.19), size: CGSize(width: w * 0.20, height: h * 0.08)))
        case .bottleGlass:
            p.addRoundedRect(in: CGRect(origin: u(0.06, 0.26), size: CGSize(width: w * 0.88, height: h * 0.72)),
                             cornerSize: CGSize(width: w * 0.16, height: w * 0.16))
        case .bottleLiquid:
            p.addRoundedRect(in: CGRect(origin: u(0.12, 0.40), size: CGSize(width: w * 0.76, height: h * 0.52)),
                             cornerSize: CGSize(width: w * 0.12, height: w * 0.12))
        case .bottleLabel:
            p.addRect(CGRect(origin: u(0.22, 0.56), size: CGSize(width: w * 0.56, height: h * 0.16)))
        case .bottleGlint:
            p.addRoundedRect(in: CGRect(origin: u(0.14, 0.32), size: CGSize(width: w * 0.07, height: h * 0.56)),
                             cornerSize: CGSize(width: w * 0.035, height: w * 0.035))
        default: break
        }
    }
}
