// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Pillarbox",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .tvOS(.v16)
    ],
    products: [
        .library(
            name: "PillarboxCircumspect",
            targets: ["PillarboxCircumspect"]
        ),
        .library(
            name: "PillarboxCore",
            targets: ["PillarboxCore"]
        ),
        .library(
            name: "PillarboxPlayer",
            targets: ["PillarboxPlayer"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/CombineCommunity/CombineExt.git", .upToNextMinor(from: "1.8.1")),
        .package(url: "https://github.com/comScore/Comscore-Swift-Package-Manager.git", .upToNextMinor(from: "6.11.0")),
        .package(url: "https://github.com/CommandersAct/iOSV5.git", .upToNextMinor(from: "5.4.4")),
        .package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.0.3")),
        .package(url: "https://github.com/krzysztofzablocki/Difference.git", exact: "1.0.1"),
        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "13.0.0"))
    ],
    targets: [
        .target(
            name: "PillarboxCore",
            path: "Sources/Core"
        ),
        .target(
            name: "PillarboxCircumspect",
            dependencies: [
                .product(name: "Difference", package: "Difference"),
                .product(name: "Nimble", package: "Nimble")
            ],
            path: "Sources/Circumspect"
        ),
        .target(
            name: "PillarboxPlayer",
            dependencies: [
                .target(name: "PillarboxCore"),
                .product(name: "CombineExt", package: "CombineExt"),
                .product(name: "DequeModule", package: "swift-collections")
            ],
            path: "Sources/Player",
            resources: [
                .process("Resources")
            ],
            plugins: [
                .plugin(name: "PackageInfoPlugin")
            ]
        ),
        .target(
            name: "PillarboxStreams",
            path: "Sources/Streams",
            resources: [
                .process("Resources")
            ]
        ),
        .binaryTarget(name: "PackageInfo", path: "Artifacts/PackageInfo.artifactbundle"),
        .plugin(
            name: "PackageInfoPlugin",
            capability: .buildTool(),
            dependencies: [
                .target(name: "PackageInfo")
            ]
        ),
        .testTarget(
            name: "CircumspectTests",
            dependencies: [
                .target(name: "PillarboxCircumspect")
            ]
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: [
                .target(name: "PillarboxCircumspect"),
                .target(name: "PillarboxCore")
            ]
        ),
        .testTarget(
            name: "PlayerTests",
            dependencies: [
                .target(name: "PillarboxCircumspect"),
                .target(name: "PillarboxPlayer"),
                .target(name: "PillarboxStreams"),
                .product(name: "OrderedCollections", package: "swift-collections")
            ]
        )
    ]
)
