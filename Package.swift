// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if os(Linux)
let dependencies: [PackageDescription.Package.Dependency] = [
	.package(url: "https://github.com/swift-server/async-http-client.git", from: "1.18.0")
]
let targetDependencies: [PackageDescription.Target.Dependency] = [
	.product(name: "AsyncHTTPClient", package: "async-http-client")
]
let products: [PackageDescription.Product] = [
    .library(name: "Uploadcare", targets: ["Uploadcare"])
]
#else
let dependencies: [PackageDescription.Package.Dependency] = []
let targetDependencies: [PackageDescription.Target.Dependency] = []
let products: [PackageDescription.Product] = [
    .library(name: "Uploadcare", targets: ["Uploadcare"]),
	.library(name: "UploadcareWidget", targets: ["UploadcareWidget"])
]
#endif

let package = Package(
    name: "Uploadcare",
	platforms: [
		.macOS(.v10_13),
		.iOS(.v11),
		.tvOS(.v11),
		.watchOS(.v5)
    ],
    products: products,
    dependencies: dependencies,
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Uploadcare",
            dependencies: targetDependencies
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
