//
//  Utils.swift
//  Demo
//
//  Created by Sergei Armodin on 21.12.2023.
//  Copyright © 2023 Uploadcare, Inc. All rights reserved.
//

import Foundation

func DLog(
	_ messages: Any...,
	fullPath: String = #file,
	line: Int = #line,
	functionName: String = #function
) {
	let file = URL(fileURLWithPath: fullPath)
	for message in messages {
		#if DEBUG
		let string = "\(file.pathComponents.last!):\(line) -> \(functionName): \(message)"
		print(string)
		#endif
	}
}


/// Delay function using GCD.
///
/// - Parameters:
///   - delay: delay in seconds
///   - closure: block to execute after delay
func delay(_ delay: Double, closure: @escaping ()->()) {
	DispatchQueue.main.asyncAfter(
		deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}
