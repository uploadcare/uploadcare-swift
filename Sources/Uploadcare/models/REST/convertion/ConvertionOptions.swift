//
//  DocumentTargetFormat.swift
//  
//
//  Created by Sergei Armodin on 03.08.2020.
//

import Foundation

public enum DocumentTargetFormat: String {
	case doc
	case docx
	case xls
	case xlsx
	case odt
	case ods
	case rtf
	case txt
	case pdf // default
	case jpg
	case png
}

public struct VideoSize {
	let width: Int?
	let height: Int?
	
	public var stringValue: String {
		var widthString = ""
		if let w = width {
			widthString = "\(w)"
		}
		var heightString = ""
		if let h = height {
			heightString = "\(h)"
		}
		return "\(widthString)x\(heightString)"
	}
}

public enum VideoResizeMode: String {
	case preserveRatio = "preserve_ratio" // default
	case changeRatio = "change_ratio"
	case scaleCrop = "scale_crop"
	case addPadding = "add_padding"
}

public enum VideoQuality: String {
	case normal // default
	case better
	case best
	case lighter
	case lightest
}

public enum VideoFormat: String {
	case mp4 // default
	case webm
	case ogg
}

public struct VideoCut {
	public let startTime: String
	public let length: String
}
