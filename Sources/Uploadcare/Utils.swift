//
//  Utils.swift
//  
//
//  Created by Sergey Armodin on 20.01.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation

#if os(Linux)
let NSEC_PER_SEC: UInt64 = 1000000000
#endif

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
	formatter.locale = Locale(identifier: "en_US")
	formatter.timeZone = TimeZone(identifier: "GMT")
	formatter.dateFormat = "E, dd MMM yyyy HH:mm:ss"
	return formatter.string(from: date) + " GMT"
}

/// Get mime type from Data
/// - Parameter data: data
func detectMimeType(for data: Data) -> String {
	var bytes = [UInt8].init(repeating: 0, count: data.count)
	data.copyBytes(to: &bytes, count: data.count)

	if data.count > 2, bytes[0...2] == [0xFF, 0xD8, 0xFF] {
		return "image/jpeg"
	}

	if data.count > 3, bytes[0...3] == [0x89, 0x50, 0x4E, 0x47] {
		return "image/png"
	}

	if data.count > 2, bytes[0...2] == [0x47, 0x49, 0x46] {
		return "image/gif"
	}

	if data.count > 11, bytes[8...11] == [0x57, 0x45, 0x42, 0x50] {
		return "image/webp"
	}

	if data.count > 9, (bytes[0...3] == [0x49, 0x49, 0x2A, 0x00] || bytes[0...3] == [0x4D, 0x4D, 0x00, 0x2A]) && bytes[8...9] == [0x43, 0x52] {
		return "image/x-canon-cr2"
	}

	if data.count > 3, bytes[0...3] == [0x49, 0x49, 0x2A, 0x00] || bytes[0...3] == [0x4D, 0x4D, 0x00, 0x2A] {
		return "image/tiff"
	}

	if data.count > 1, bytes[0...1] == [0x42, 0x4D] {
		return "image/bmp"
	}

	if data.count > 57, bytes[0...3] == [0x50, 0x4B, 0x03, 0x04] && bytes[30...57] == [
		0x6D, 0x69, 0x6D, 0x65, 0x74, 0x79, 0x70, 0x65, 0x61, 0x70, 0x70, 0x6C,
		0x69, 0x63, 0x61, 0x74, 0x69, 0x6F, 0x6E, 0x2F, 0x65, 0x70, 0x75, 0x62,
		0x2B, 0x7A, 0x69, 0x70
	] {
		return "application/epub+zip"
	}

	if data.count > 3, bytes[0...1] == [0x50, 0x4B] && (bytes[2] == 0x3 || bytes[2] == 0x5 || bytes[2] == 0x7) && (bytes[3] == 0x4 || bytes[3] == 0x6 || bytes[3] == 0x8) {
		return "application/zip"
	}

	if data.count > 261, bytes[257...261] == [0x75, 0x73, 0x74, 0x61, 0x72] {
		return "application/x-tar"
	}

	if data.count > 6, bytes[0...5] == [0x52, 0x61, 0x72, 0x21, 0x1A, 0x07] && (bytes[6] == 0x0 || bytes[6] == 0x1) {
		return "application/x-rar-compressed"
	}

	if data.count > 2, bytes[0...2] == [0x1F, 0x8B, 0x08] {
		return "application/gzip"
	}

	if data.count > 2, bytes[0...2] == [0x42, 0x5A, 0x68] {
		return "application/x-bzip2"
	}

	if data.count > 5, bytes[0...5] == [0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C] {
		return "application/x-7z-compressed"
	}

	if data.count > 1, bytes[0...1] == [0x78, 0x01] {
		return "application/x-apple-diskimage"
	}

	if data.count > 27, (bytes[0...2] == [0x00, 0x00, 0x00] && (bytes[3] == 0x18 || bytes[3] == 0x20) && bytes[4...7] == [0x66, 0x74, 0x79, 0x70]) ||
		(bytes[0...3] == [0x33, 0x67, 0x70, 0x35]) ||
  (bytes[0...11] == [0x00, 0x00, 0x00, 0x1C, 0x66, 0x74, 0x79, 0x70, 0x6D, 0x70, 0x34, 0x32] &&
	bytes[16...27] == [0x6D, 0x70, 0x34, 0x31, 0x6D, 0x70, 0x34, 0x32, 0x69, 0x73, 0x6F, 0x6D]) ||
  (bytes[0...11] == [0x00, 0x00, 0x00, 0x1C, 0x66, 0x74, 0x79, 0x70, 0x69, 0x73, 0x6F, 0x6D]) ||
		(bytes[0...11] == [0x00, 0x00, 0x00, 0x1C, 0x66, 0x74, 0x79, 0x70, 0x6D, 0x70, 0x34, 0x32, 0x00, 0x00, 0x00, 0x00]) {
		return "video/mp4"
	}

	if data.count > 10, bytes[0...10] == [0x00, 0x00, 0x00, 0x1C, 0x66, 0x74, 0x79, 0x70, 0x4D, 0x34, 0x56] {
		return "video/x-m4v"
	}

	if data.count > 7, bytes[0...7] == [0x00, 0x00, 0x00, 0x14, 0x66, 0x74, 0x79, 0x70] {
		return "video/quicktime"
	}

	if data.count > 3, bytes[0...3] == [0x52, 0x49, 0x46, 0x46] && bytes[8...10] == [0x41, 0x56, 0x49] {
		return "video/x-msvideo"
	}

	if data.count > 9, bytes[0...9] == [0x30, 0x26, 0xB2, 0x75, 0x8E, 0x66, 0xCF, 0x11, 0xA6, 0xD9] {
		return "video/x-ms-wmv"
	}

	if data.count > 2, bytes[0...2] == [0x49, 0x44, 0x33] || bytes[0...1] == [0xFF, 0xFB] {
		return "audio/mpeg"
	}

	if data.count > 10, bytes[0...3] == [0x4D, 0x34, 0x41, 0x20] || bytes[4...10] == [0x66, 0x74, 0x79, 0x70, 0x4D, 0x34, 0x41] {
		return "audio/m4a"
	}

	if data.count > 35, bytes[28...35] == [0x4F, 0x70, 0x75, 0x73, 0x48, 0x65, 0x61, 0x64] {
		return "audio/opus"
	}

	if data.count > 3, bytes[0...3] == [0x4F, 0x67, 0x67, 0x53] {
		return "audio/ogg"
	}

	if data.count > 3, bytes[0...3] == [0x66, 0x4C, 0x61, 0x43] {
		return "audio/x-flac"
	}

	if data.count > 3, bytes[0...3] == [0x52, 0x49, 0x46, 0x46] && bytes[8...11] == [0x57, 0x41, 0x56, 0x45] {
		return "audio/x-wav"
	}

	if data.count > 3, bytes[0...3] == [0x25, 0x50, 0x44, 0x46] {
		return "application/pdf"
	}

	if data.count > 1, bytes[0...1] == [0x4D, 0x5A] {
		return "application/x-msdownload"
	}

	if data.count > 4, bytes[0...4] == [0x7B, 0x5C, 0x72, 0x74, 0x66] {
		return "application/rtf"
	}

	if data.count > 4, bytes[0...4] == [0x00, 0x01, 0x00, 0x00, 0x00] {
		return "application/font-sfnt"
	}

	if data.count > 4, bytes[0...4] == [0x4F, 0x54, 0x54, 0x4F, 0x00] {
		return "application/font-sfnt"
	}

	if data.count > 7, bytes[0...7] == [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1] {
		return "application/x-msi"
	}

	if data.count > 0, bytes[0] == 0x46 {
		return "text/plain"
	}

	return "application/octet-stream"
}

/// Get Swift version
func getSwiftVersion() -> String {
	var swiftVersion = "5.0"
	#if swift(>=7.0)
		swiftVersion = "7.0"
	#elseif swift(>=6.3)
		swiftVersion = "6.3"
	#elseif swift(>=6.2)
		swiftVersion = "6.2"
	#elseif swift(>=6.1)
		swiftVersion = "6.1"
	#elseif swift(>=6.0)
		swiftVersion = "6.0"
	#elseif swift(>=5.9)
		swiftVersion = "5.9"
	#elseif swift(>=5.8)
		swiftVersion = "5.8"
	#elseif swift(>=5.7)
		swiftVersion = "5.7"
	#elseif swift(>=5.6)
		swiftVersion = "5.6"
	#elseif swift(>=5.5)
		swiftVersion = "5.5"
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
