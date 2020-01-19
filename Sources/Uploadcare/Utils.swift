//
//  Utils.swift
//  
//
//  Created by Sergey Armodin on 20.01.2020.
//

import Foundation

/// Debug log function with printing filename, method and line number
///
/// - Parameters:
///   - messages: arguments
///   - fullPath: filepath
///   - line: line number
///   - functionName: function/method name
func DLog(_ messages: Any..., fullPath: String = #file, line: Int = #line, functionName: String = #function) {
	#if DEBUG
	let file = URL(fileURLWithPath: fullPath)
	for message in messages {
		let string = "\(file.pathComponents.last!):\(line) -> \(functionName): \(message)"
		print(string)
	}
	#endif
}
