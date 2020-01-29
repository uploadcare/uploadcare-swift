//
//  Utils.swift
//  DemoApp
//
//  Created by Sergey Armodin on 30.01.2020.
//  Copyright © 2020 Sergei Armodin. All rights reserved.
//

import Foundation


/// Delay function using GCD.
///
/// - Parameters:
///   - delay: delay in seconds
///   - closure: block to execute after delay
func delay(_ delay: Double, closure: @escaping ()->()) {
	DispatchQueue.main.asyncAfter(
		deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}
