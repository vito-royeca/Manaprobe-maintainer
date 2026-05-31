// swift-tools-version:6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Manaprobe-maintainer",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .executable(
            name: "manaprobe-maintainer",
            targets: ["Manaprobe-maintainer"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/tid-kijyun/Kanna", from: "6.1.0"),
        .package(url: "https://github.com/codewinsdotcom/PostgresClientKit", from: "1.5.0"),
        .package(url: "https://github.com/swiftpackages/DotEnv.git", from: "3.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "Manaprobe-maintainer",
            dependencies: [
                .product(name: "DotEnv", package: "DotEnv"),
                "Kanna",
                "PostgresClientKit",
            ],
            resources: [ .process("keyrune-updates.plist") ]
        ),
        .testTarget(
            name: "Manaprobe-maintainerTests",
            dependencies: [
                "Manaprobe-maintainer",
                .product(name: "DotEnv", package: "DotEnv"),
                "Kanna",
                "PostgresClientKit",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
