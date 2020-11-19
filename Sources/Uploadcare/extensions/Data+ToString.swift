//
//  Data+ToString.swift
//  
//
//  Created by Sergey Armodin on 12.02.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation


extension Data {
	func toString() -> String? {
		return String(data: self, encoding: .utf8)
	}
}
