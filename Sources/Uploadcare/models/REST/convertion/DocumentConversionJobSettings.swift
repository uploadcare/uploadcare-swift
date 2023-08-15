//
//  DocumentConversionJobSettings.swift
//  
//
//  Created by Sergey Armodin on 26.08.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation

public class DocumentConversionJobSettings {
	/// File for conversion.
	public let file: File
	
	/// Target format.
	public var format: DocumentTargetFormat = .pdf
	
	/// String value for path.
	public var stringValue: String {
		return "/\(file.uuid)/document/-/format/\(format.rawValue)/"
	}
	
	public init(forFile file: File, format: DocumentTargetFormat = .pdf) {
		self.file = file
		self.format = format
	}
	
	public func format(_ newValue: DocumentTargetFormat) -> Self {
		self.format = newValue
		return self
	}
}
