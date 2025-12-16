// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var pDependencies = [PackageDescription.Package.Dependency]()
var tDependencies = [PackageDescription.Target.Dependency]()

pDependencies += [
    .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ... "5.0.0"),
    .package(url: "https://github.com/zhtut/nio-locked-value.git", from: "0.1.0"),
    .package(url: "https://github.com/zhtut/async-network.git", from: "0.4.2"),
//    .package(path: "../../async-network"),
    .package(url: "https://github.com/zhtut/combine-websocket.git", from: "0.3.0"),
//    .package(path: "../../combine-websocket"),
    .package(url: "https://github.com/zhtut/common-utils.git", from: "0.1.3"),
//    .package(path: "../../common-utils"),
    .package(url: "https://github.com/zhtut/default-codable.git", from: "1.0.4"),
//    .package(path: "../../default-codable"),
    .package(url: "https://github.com/zhtut/logging-kit.git", from: "0.1.5"),
//    .package(path: "../../logging-kit"),
]

tDependencies += [
    .product(name: "Crypto", package: "swift-crypto"),
    .product(name: "NIOLockedValue", package: "nio-locked-value"),
    .product(name: "AsyncNetwork", package: "async-network"),
    .product(name: "CombineWebSocket", package: "combine-websocket"),
    .product(name: "CommonUtils", package: "common-utils"),
    .product(name: "DefaultCodable", package: "default-codable"),
    .product(name: "LoggingKit", package: "logging-kit"),
]

let package = Package(
    name: "binance-api",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BinanceApi",
            targets: ["BinanceApi"]),
    ],
    dependencies: pDependencies,
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "BinanceApi", dependencies: tDependencies),
        .testTarget(
            name: "BinanceApiTests",
            dependencies: ["BinanceApi"]
        ),
    ]
)
