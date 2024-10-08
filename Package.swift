// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if os(Linux)
let dependencies: [PackageDescription.Package.Dependency] = [
	.package(url: "https://github.com/swift-server/async-http-client.git", from: "1.18.0"),
	.package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "4.0.0")
]
let targetDependencies: [PackageDescription.Target.Dependency] = [
	.product(name: "AsyncHTTPClient", package: "async-http-client"),
	.product(name: "Crypto", package: "swift-crypto")
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
		.iOS(.v12),
		.tvOS(.v12),
		.watchOS(.v5)
	],
	products: products,
	dependencies: dependencies,
	targets: [
		// Targets are the basic building blocks of a package. A target can define a module or a test suite.
		// Targets can depend on other targets in this package, and on products in packages which this package depends on.
		.target(
			name: "Uploadcare",
			dependencies: targetDependencies,
			resources: [
				.process("PrivacyInfo.xcprivacy")
			]
		),
		.target(
			name: "UploadcareWidget",
			dependencies: ["Uploadcare"],
			resources: [
				.process("PrivacyInfo.xcprivacy")
			]
		),
		.testTarget(
			name: "UploadcareTests",
			dependencies: ["Uploadcare"]
		)
	]
)
