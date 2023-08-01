//
//  Error.swift
//  
//
//  Created by Sergey Armodin on 12.01.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation

// Struct to represent an error that upload API might return.
public struct UploadError: Error {
	/// Usually backend network response status.
	public var status: Int

	/// Error message.
	public var detail: String


	/// Default error.
	public static func defaultError() -> UploadError {
		return UploadError(status: 0, detail: "Unknown error")
	}

	/// Default error with status code.
	public static func defaultError(withStatus status: Int) -> UploadError {
		return UploadError(status: status, detail: "Unknown error")
	}

	/// Cast from Error.
	/// - Parameter error: Error.
	static func fromError(_ error: Error) -> UploadError {
		if case let RequestManagerError.invalidUploadAPIResponse(requestError) = error {
			return requestError
		}
		return Self.defaultError()
	}
}


extension UploadError: CustomDebugStringConvertible {
	public var debugDescription: String {
		return """
		\(type(of: self)):
			status: \(status),
			message: \(detail)
		"""
	}
}

