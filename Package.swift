// swift-tools-version: 6.3.3

import PackageDescription

let package = Package(
    name: "swift-memory-heap-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(
            name: "Memory Heap Primitives",
            targets: ["Memory Heap Primitives"]
        ),
        .library(
            name: "Memory Heap Primitives Test Support",
            targets: ["Memory Heap Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-memory-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-memory-allocation-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-byte-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-index-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-affine-primitives.git", branch: "main"),
    ],
    targets: [
        // Hosts the Memory.Heap leaf, its Memory.Region seam, AND — post dependency-inversion — its
        // Memory.Allocatable / Memory.Growable conformances plus the heap-backed Allocator / Arena /
        // Pool construction conveniences (moved down from swift-memory-allocation-primitives, which
        // must not name a concrete leaf). The edge now points heap → allocation.
        .target(
            name: "Memory Heap Primitives",
            dependencies: [
                .product(name: "Memory Primitive", package: "swift-memory-primitives"),
                .product(name: "Memory Address Primitives", package: "swift-memory-primitives"),
                .product(name: "Memory Alignment Primitives", package: "swift-memory-primitives"),
                .product(name: "Memory Region Primitives", package: "swift-memory-primitives"),
                .product(name: "Memory Primitives Standard Library Integration", package: "swift-memory-primitives"),
                .product(name: "Memory Allocator Primitive", package: "swift-memory-allocation-primitives"),
                .product(name: "Memory Allocator Protocol Primitives", package: "swift-memory-allocation-primitives"),
                .product(name: "Memory Allocator Arena Primitives", package: "swift-memory-allocation-primitives"),
                .product(name: "Memory Allocator Pool Primitives", package: "swift-memory-allocation-primitives"),
                .product(name: "Byte Primitive", package: "swift-byte-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Affine Discrete Primitives", package: "swift-affine-primitives"),
                .product(name: "Affine Primitives Standard Library Integration", package: "swift-affine-primitives"),
            ]
        ),
        .target(
            name: "Memory Heap Primitives Test Support",
            dependencies: [
                "Memory Heap Primitives",
                .product(name: "Memory Primitives Test Support", package: "swift-memory-primitives"),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Memory Heap Primitives Tests",
            dependencies: [
                "Memory Heap Primitives",
                "Memory Heap Primitives Test Support",
                .product(name: "Memory Allocation Primitives", package: "swift-memory-allocation-primitives"),
                .product(name: "Memory Allocation Primitives Test Support", package: "swift-memory-allocation-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem
}
