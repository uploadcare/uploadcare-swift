//
//  VideoConversionJobSettings.swift
//  
//
//  Created by Sergey Armodin on 26.08.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation

public class VideoConversionJobSettings {
	/// File for conversion.
	public let file: File
	
	/// Resizes a video to the specified dimensions.
	public var size: VideoSize?
	
	/// Resize mode.
	public var resizeMode: VideoResizeMode = .preserveRatio
	
	/// Sets the level of video quality.
	public var quality: VideoQuality = .normal
	
	/// Converts a file to one of the HTML5 video formats.
	public var format: VideoFormat = .mp4
	
	/// Cuts out a video fragment. See documentation: https://uploadcare.com/docs/transformations/video_encoding/#operation-cut
	public var cut: VideoCut?
	
	/// Creates N thumbnails for your video, where N is a non-zero integer ranging from 1 to 50; defaults to 1.
	public var thumbs: Int = 1
	
	/// String value for path.
	public var stringValue: String {
		var string = "/\(file.uuid)/video/"
		
		if let newSize = size {
			string += "-/size/\(newSize.stringValue)/\(resizeMode.rawValue)/"
		}
		
		string += "-/quality/\(quality.rawValue)/"
		string += "-/format/\(format.rawValue)/"
		
		if let newCut = cut {
			string += "-/cut/\(newCut.startTime)/\(newCut.length)/"
		}
		
		string += "-/thumbs~\(thumbs)/"
		
		return string
	}
	
	public init(forFile file: File, size: VideoSize? = nil, resizeMode: VideoResizeMode = .preserveRatio, quality: VideoQuality = .normal, format: VideoFormat = .mp4, cut: VideoCut? = nil, thumbs: Int = 1) {
		self.file = file
		self.size = size
		self.resizeMode = resizeMode
		self.quality = quality
		self.format = format
		self.cut = cut
		
		if thumbs <= 0 {
			self.thumbs = 1
		} else if thumbs > 50 {
			self.thumbs = 50
		} else {
			self.thumbs = thumbs
		}
	}
	
	public func size(_ newValue: VideoSize?) -> Self {
		self.size = newValue
		return self
	}
	
	public func resizeMode(_ newValue: VideoResizeMode) -> Self {
		self.resizeMode = newValue
		return self
	}
	
	public func quality(_ newValue: VideoQuality) -> Self {
		self.quality = newValue
		return self
	}
	
	public func format(_ newValue: VideoFormat) -> Self {
		self.format = newValue
		return self
	}
	
	public func cut(_ newValue: VideoCut?) -> Self {
		self.cut = newValue
		return self
	}
	
	public func thumbs(_ newValue: Int) -> Self {
		if newValue <= 0 {
			self.thumbs = 1
		} else if newValue > 50 {
			self.thumbs = 50
		} else {
			self.thumbs = newValue
		}
		return self
	}
}
