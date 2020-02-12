//
//  Error.swift
//  
//
//  Created by Sergey Armodin on 12.01.2020.
//

import Foundation


public struct UploadError {
	/// Usually backend network respon se status
	public var status: Int
	
	/// Error message
	public var message: String
	
	/// Default error
	public static func defaultError() -> UploadError {
		return UploadError(status: 0, message: "Unknown error")
	}
}


extension UploadError: CustomDebugStringConvertible {
	public var debugDescription: String {
		return """
		\(type(of: self)):
			status: \(status),
			message: \(message)
		"""
	}
}

