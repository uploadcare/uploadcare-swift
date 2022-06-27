//
//  VideoInfo.swift
//  
//
//  Created by Sergey Armodin on 14.01.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation

/// Video metadata.
public struct VideoInfo: Codable {
	
	/// Video duration in milliseconds.
	public var duration: Int
	
	/// Video format(MP4 for example).
	public var format: String
	
	/// Video bitrate.
	public var bitrate: Int
	
	/// Audio stream metadata.
	public var audio: AudioMetadata?
	
	/// Video stream metadata.
	public var video: VideoMetadata
	
	
	enum CodingKeys: String, CodingKey {
		case duration
		case format
		case bitrate
		case audio
		case video
	}
	
	
	init(
		duration: Int,
		format: String,
		bitrate: Int,
		audio: AudioMetadata?,
		video: VideoMetadata
	) {
		self.duration = duration
		self.format = format
		self.bitrate = bitrate
		self.audio = audio
		self.video = video
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let duration = try container.decodeIfPresent(Int.self, forKey: .duration) ?? 0
		let format = try container.decodeIfPresent(String.self, forKey: .format) ?? ""
		let bitrate = try container.decodeIfPresent(Int.self, forKey: .bitrate) ?? 0
		let audio = try container.decodeIfPresent(AudioMetadata.self, forKey: .audio)
		let video = try container.decodeIfPresent(VideoMetadata.self, forKey: .video) ?? VideoMetadata(height: 0, width: 0, frameRate: 0, bitrate: 0, codec: "")

		self.init(
			duration: duration,
			format: format,
			bitrate: bitrate,
			audio: audio,
			video: video
		)
	}
	
}


extension VideoInfo: CustomDebugStringConvertible {
	public var debugDescription: String {
		return """
		\(type(of: self)):
				duration: \(duration)
				format: \(format)
				bitrate: \(bitrate)
				audio: \(String(describing: audio))
				video: \(video)
		"""
	}
}
