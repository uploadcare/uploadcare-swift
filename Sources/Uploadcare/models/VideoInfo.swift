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
	public var audio: Audio?

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
		audio: Audio?,
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
		let audio = try container.decodeIfPresent(Audio.self, forKey: .audio)
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


extension VideoInfo {
    /// Audio stream metadata.
    public struct Audio: Codable, CustomDebugStringConvertible {
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

        public var debugDescription: String {
            return """
                \(type(of: self)):
                        bitrate: \(String(describing: bitrate))
                        codec: \(String(describing: codec))
                        sampleRate: \(String(describing: sampleRate))
                        channels: \(String(describing: channels))
            """
        }
    }

}
