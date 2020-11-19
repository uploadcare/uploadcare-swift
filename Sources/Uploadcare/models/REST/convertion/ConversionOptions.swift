//
//  DocumentTargetFormat.swift
//  
//
//  Created by Sergey Armodin on 03.08.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation

/// Conversion job status
public enum ConversionStatus {
	case pending
	case processing
	case finished
	case failed(error: String)
	case cancelled
	case unknown
}

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
	/// New size width
	let width: Int?
	
	/// New size height
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
	
	public init(width: Int?, height: Int?) {
		self.width = width
		self.height = height
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

/// Cuts out a video fragment.
/// See documentation: https://uploadcare.com/docs/transformations/video_encoding/#operation-cut
public struct VideoCut {
	///  defines the starting point of a fragment to cut based on your input file timeline.
	public let startTime: String
	
	/// defines the duration of that fragment.
	public let length: String
	
	public init(startTime: String, length: String) {
		self.startTime = startTime
		self.length = length
	}
}
