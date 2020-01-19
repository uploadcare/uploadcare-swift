//
//  Error.swift
//  
//
//  Created by Sergey Armodin on 12.01.2020.
//

import Foundation


public struct Error {
	public var status: Int
	public var message: String
	
	public static func defaultError() -> Error {
		return Error(status: 0, message: "Unknown error")
	}
}
