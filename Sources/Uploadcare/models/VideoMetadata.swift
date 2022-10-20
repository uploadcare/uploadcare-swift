//
//  VideoMetadata.swift
//  
//
//  Created by Sergey Armodin on 15.06.2022.
//  Copyright © 2022 Uploadcare, Inc. All rights reserved.
//

import Foundation

/// Video stream metadata.
public struct VideoMetadata: Codable {
	/// Video stream image height.
	public var height: Int

	/// Video stream image width.
	public var width: Int

	/// Video stream frame rate.
	public var frameRate: Int

	/// Video stream bitrate.
	public var bitrate: Int?

	/// Video stream codec.
	public var codec: String?


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
		bitrate: Int?,
		codec: String?
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
		let bitrate = try container.decodeIfPresent(Int.self, forKey: .bitrate)
		let codec = try container.decodeIfPresent(String.self, forKey: .codec)

		self.init(
			height: height,
			width: width,
			frameRate: frameRate,
			bitrate: bitrate,
			codec: codec
		)
	}
}


extension VideoMetadata: CustomDebugStringConvertible {
	public var debugDescription: String {
		return """
			\(type(of: self)):
					height: \(height)
					width: \(width)
					frameRate: \(frameRate)
					bitrate: \(bitrate as Any)
					codec: \(codec as Any)
		"""
	}
}
