// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InvoiceBuilderFeature",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "InvoiceBuilderFeature",
            targets: ["InvoiceBuilderFeature"]
        ),
    ],
    dependencies: [
        // Core dependencies for Invoice Builder functionality
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.0"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-identified-collections.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "InvoiceBuilderFeature",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
            ]
        ),
        .testTarget(
            name: "InvoiceBuilderFeatureTests",
            dependencies: [
                "InvoiceBuilderFeature",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
    ]
)
