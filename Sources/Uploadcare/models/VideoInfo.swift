//
//  VideoInfo.swift
//  
//
//  Created by Sergey Armodin on 14.01.2020.
//

import Foundation


/// Audio stream metadata.
public struct AudioMetadata: Codable {
	/// Audio bitrate.
	public var bitrate: Int?
	
	/// Audio stream codec.
	public var codec: String?
	
	/// Audio stream sample rate.
	public var sampleRate: Int?
	
	/// Audio stream number of channels.
	public var channels: String?
	
	
	enum CodingKeys: String, CodingKey {
		case bitrate
		case codec
		case sampleRate = "sample_rate"
		case channels
	}
}

/// Video stream metadata.
public struct VideoMetadata: Codable {
	/// Video stream image height.
	public var height: Int
	
	/// Video stream image width.
	public var width: Int
	
	/// Video stream frame rate.
	public var frameRate: Int
	
	/// Video stream bitrate.
	public var bitrate: Int
	
	/// Video stream codec.
	public var codec: String
	
	
	enum CodingKeys: String, CodingKey {
		case height
		case width
		case frameRate = "frame_rate"
		case bitrate
		case codec
	}
	
	init(
		height: Int,
		width: Int,
		frameRate: Int,
		bitrate: Int,
		codec: String
	) {
		self.height = height
		self.width = width
		self.frameRate = frameRate
		self.bitrate = bitrate
		self.codec = codec
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let height = try container.decodeIfPresent(Int.self, forKey: .height) ?? 0
		let width = try container.decodeIfPresent(Int.self, forKey: .width) ?? 0
		let frameRate = try container.decodeIfPresent(Int.self, forKey: .frameRate) ?? 0
		let bitrate = try container.decodeIfPresent(Int.self, forKey: .bitrate) ?? 0
		let codec = try container.decodeIfPresent(String.self, forKey: .codec) ?? ""

		self.init(
			height: height,
			width: width,
			frameRate: frameRate,
			bitrate: bitrate,
			codec: codec
		)
	}
}


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
