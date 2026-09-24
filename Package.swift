// swift-tools-version: 5.9
//
//  Package.swift
//  KitoProduct
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "KitoProduct",
    platforms: [.iOS(.v17)],
    products: [.library(name: "KitoProduct", targets: ["KitoProduct"])],
    dependencies: [
        .package(url: "https://github.com/WykSofts-Inc/KitoCore.git", from: "1.1.0"),
        .package(url: "https://github.com/WykSofts-Inc/KitoCart.git", from: "1.1.1"),
        .package(url: "https://github.com/WykSofts-Inc/KitoImageLoader.git", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: "KitoProduct",
            dependencies: [
                .product(name: "KitoCore", package: "KitoCore"),
                .product(name: "KitoCart", package: "KitoCart"),
                .product(name: "KitoImageLoader", package: "KitoImageLoader"),
            ]
        ),
        .testTarget(name: "KitoProductTests", dependencies: ["KitoProduct"]),
    ]
)
