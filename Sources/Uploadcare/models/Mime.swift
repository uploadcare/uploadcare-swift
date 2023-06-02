//
//  Mime.swift
//  
//
//  Created by Sergei Armodin on 13.09.2022.
//  Copyright © 2022 Uploadcare, Inc. All rights reserved.
//

import Foundation

/// MIME type data.
public struct Mime: Codable, Equatable {
	/// Full MIME type.
	public let mime: String

	/// Type of MIME type.
	public let type: String

	/// Subtype of MIME type.
	public let subtype: String
}
