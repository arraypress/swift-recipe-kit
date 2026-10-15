// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "RecipeKit",
    // Foundation only, so the generation libraries' future iOS apps can use it.
    platforms: [
        .macOS(.v14), .iOS(.v17),
    ],
    products: [
        .library(name: "RecipeKit", targets: ["RecipeKit"]),
    ],
    targets: [
        // Pure, synchronous rules: nothing here is async, so
        // NonisolatedNonsendingByDefault has nothing to change and stays off.
        .target(name: "RecipeKit"),
        .testTarget(name: "RecipeKitTests", dependencies: ["RecipeKit"]),
    ]
)

// Swift 7's import rule, today: a file must import every module whose members
// it uses, rather than leaning on another file's imports.
for target in package.targets where target.type != .system && target.type != .binary && target.type != .plugin {
    target.swiftSettings = (target.swiftSettings ?? []) + [.enableUpcomingFeature("MemberImportVisibility")]
}
