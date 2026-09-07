// swift-tools-version:5.9
// CC0-1.0. Companion Light Mobile — iOS. CAT-017: core builds on Linux so the compiler can sit inside the model loop.
import PackageDescription

let package = Package(
    name: "CompanionLight",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "CompanionCore", targets: ["CompanionCore"])],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),   // CryptoKit API on Linux (`import Crypto`)
        // VERIFY: .package(url: "https://github.com/ml-explore/mlx-swift-examples", branch: "main"),
    ],
    targets: [
        .systemLibrary(name: "CSQLite", path: "Sources/CSQLite", providers: [.apt(["libsqlite3-dev"]), .brew(["sqlite"])]),
        .target(name: "CompanionCore",
                dependencies: ["CSQLite", .product(name: "Crypto", package: "swift-crypto")]),
        .target(name: "CompanionApp", dependencies: ["CompanionCore"]),
        .testTarget(name: "CompanionCoreTests", dependencies: ["CompanionCore"]),
    ]
)
