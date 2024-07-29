// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CSVErrorRepair",
    platforms: [
       .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CSVErrorRepair",
            targets: ["CSVErrorRepair"]),
    ],
    dependencies: [
        .package(url: "https://github.com/JohnSundell/CollectionConcurrencyKit.git", from: "0.1.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CSVErrorRepair",
            dependencies: [
                .product(name: "CollectionConcurrencyKit", package: "CollectionConcurrencyKit"),
            ]
        ),
        .testTarget(
            name: "CSVErrorRepairTests",
            dependencies: ["CSVErrorRepair"]),
    ]
)
