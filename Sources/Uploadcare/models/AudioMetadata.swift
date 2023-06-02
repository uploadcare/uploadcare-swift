//
//  AudioMetadata.swift
//  
//
//  Created by Sergey Armodin on 15.06.2022.
//  Copyright © 2022 Uploadcare, Inc. All rights reserved.
//

import Foundation

/// Audio stream metadata.
public struct AudioMetadata: Codable, Equatable {
	/// Audio bitrate.
	public var bitrate: Int?

	/// Audio stream codec.
	public var codec: String?

	/// Audio stream sample rate.
	public var sampleRate: Int?

	/// Audio stream number of channels.
	public var channels: Int?


	enum CodingKeys: String, CodingKey {
		case bitrate
		case codec
		case sampleRate = "sample_rate"
		case channels
	}
}


extension AudioMetadata: CustomDebugStringConvertible {
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
