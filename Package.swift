// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CSVErrorScanner",
    platforms: [
       .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CSVErrorScanner",
            targets: ["CSVErrorScanner"]),
    ],
    dependencies: [
        .package(url: "https://github.com/JohnSundell/CollectionConcurrencyKit.git", from: "0.1.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CSVErrorScanner",
            dependencies: [
                .product(name: "CollectionConcurrencyKit", package: "CollectionConcurrencyKit"),
            ]
        ),
        .testTarget(
            name: "CSVErrorScannerTests",
            dependencies: ["CSVErrorScanner"]),
    ]
)
