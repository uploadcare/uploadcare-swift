// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Uploadcare",
	platforms: [
		.macOS(.v10_13),
		.iOS(.v11),
		.tvOS(.v11),
		.watchOS(.v5)
    ],
    products: [
        .library(name: "Uploadcare", targets: ["Uploadcare"]),
		.library(name: "UploadcareWidget", targets: ["UploadcareWidget"])
    ],
    dependencies: [
		.package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.4")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Uploadcare",
            dependencies: ["Alamofire"]
		),
		.target(
			name: "UploadcareWidget",
			dependencies: ["Uploadcare"]
		),
        .testTarget(
            name: "UploadcareTests",
            dependencies: ["Uploadcare"]
		)
    ]
)
