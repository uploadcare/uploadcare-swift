//
//  Utils.swift
//  
//
//  Created by Sergey Armodin on 20.01.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation

/// Debug log function with printing filename, method and line number
///
/// - Parameters:
///   - messages: arguments
///   - fullPath: filepath
///   - line: line number
///   - functionName: function/method name
func DLog(_ messages: Any..., fullPath: String = #file, line: Int = #line, functionName: String = #function) {
	#if DEBUG
	let file = URL(fileURLWithPath: fullPath)
	for message in messages {
		let string = "\(file.pathComponents.last!):\(line) -> \(functionName): \(message)"
		print(string)
	}
	#endif
}

/// Time format for headers should be in format "Fri, 30 Sep 2016 11:10:54 GMT"
internal func GMTDate() -> String {
	let date = Date()
	let formatter = DateFormatter()
	formatter.timeZone = TimeZone(identifier: "GMT")
	formatter.dateFormat = "E, dd MMM yyyy HH:mm:ss"
	return formatter.string(from: date) + " GMT"
}

/// Get mime type from Data
/// - Parameter data: data
func detectMimeType(for data: Data) -> String {
	var b: UInt8 = 0
	data.copyBytes(to: &b, count: 1)

	switch b {
	case 0xFF:
		return "image/jpeg"
	case 0x89:
		return "image/png"
	case 0x47:
		return "image/gif"
	case 0x4D, 0x49:
		return "image/tiff"
	case 0x25:
		return "application/pdf"
	case 0xD0:
		return "application/vnd"
	case 0x46:
		return "text/plain"
	default:
		return "application/octet-stream"
	}
}

/// Get Swift version
func getSwiftVersion() -> String {
	var swiftVersion = "5.0"
	#if swift(>=7.0)
		swiftVersion = "7.0"
	#elseif swift(>=6.0)
		swiftVersion = "6.0"
	#elseif swift(>=5.4)
		swiftVersion = "5.4"
	#elseif swift(>=5.3)
		swiftVersion = "5.3"
	#elseif swift(>=5.2)
		swiftVersion = "5.2"
	#elseif swift(>=5.1)
		swiftVersion = "5.1"
	#endif
	return swiftVersion
}
