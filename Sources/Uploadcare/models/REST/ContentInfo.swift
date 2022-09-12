//
//  ContentInfo.swift
//  
//
//  Created by Sergei Armodin on 13.09.2022.
//  Copyright © 2022 Uploadcare, Inc. All rights reserved.
//

import Foundation

public struct ContentInfo: Codable {
	/// MIME type.
	public let mime: Mime?
	
	/// Image metadata.
	public let image: ImageInfo?

	/// Video metadata.
	public let video: VideoInfo?
}
