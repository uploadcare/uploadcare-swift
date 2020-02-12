//
//  Data+ToString.swift
//  
//
//  Created by Sergei Armodin on 12.02.2020.
//

import Foundation


extension Data {
	func toString() -> String? {
		return String(data: self, encoding: .utf8)
	}
}
