// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "stts",
    platforms: [
       .iOS("12.0")
    ],
    products: [
        // library and target names.
        // If the plugin name contains "_", replace with "-" for the library name.
        .library(name: "stts", targets: ["stts"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "stts",
            dependencies: [],
            resources: [
                // https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)