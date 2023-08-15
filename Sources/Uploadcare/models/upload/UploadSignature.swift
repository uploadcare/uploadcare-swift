//
//  UploadSignature.swift
//  
//
//  Created by Sergey Armodin on 05.05.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation

public struct UploadSignature {
	/// Signature string.
	let signature: String
	
	/// Signature expire timestamp.
	let expire: Int
    
	public init(signature: String, expire: Int) {
		self.signature = signature
		self.expire = expire
	}
}
