//
//  Error.swift
//  
//
//  Created by Sergey Armodin on 12.01.2020.
//

import Foundation


public struct Error {
	/// Usually backend network respon se status
	public var status: Int
	
	/// Error message
	public var message: String
	
	/// Default error
	public static func defaultError() -> Error {
		return Error(status: 0, message: "Unknown error")
	}
}
