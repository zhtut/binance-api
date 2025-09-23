// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var pDependencies = [PackageDescription.Package.Dependency]()
var tDependencies = [PackageDescription.Target.Dependency]()

pDependencies += [
    .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ... "5.0.0"),
    .package(url: "https://github.com/zhtut/async-network.git", branch: "main"),
//    .package(path: "../async-networking"),
    .package(url: "https://github.com/zhtut/combine-websocket.git", branch: "main"),
//    .package(path: "../combine-websocket"),
    .package(url: "https://github.com/zhtut/common-utils.git", branch: "main"),
//    .package(path: "../common-utils"),
    .package(url: "https://github.com/zhtut/nio-locked-value.git", branch: "main"),
]

tDependencies += [
    .product(name: "Crypto", package: "swift-crypto"),
    .product(name: "AsyncNetwork", package: "async-network"),
    .product(name: "CombineWebSocket", package: "combine-websocket"),
    .product(name: "CommonUtils", package: "common-utils"),
    .product(name: "NIOLockedValue", package: "nio-locked-value"),
]

#if os(macOS) || os(iOS)
// ios 和 macos不需要这个，系统自带了
#else
let latestVersion: Range<Version> = "0.0.1"..<"99.99.99"
pDependencies += [
    .package(url: "https://github.com/zhtut/CombineX.git", latestVersion),
]
tDependencies += [
    "CombineX",
]
#endif

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
