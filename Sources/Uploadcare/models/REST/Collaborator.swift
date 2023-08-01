//
//  Collaborator.swift
//  
//
//  Created by Sergey Armodin on 10.03.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation


/// Project collaborator.
public struct Collaborator: Codable {
	
	/// Collaborator email.
	public var email: String
	
	/// Collaborator name.
	public var name: String
	
	
	enum CodingKeys: String, CodingKey {
		case email
		case name
	}
	
	public init(email: String, name: String) {
		self.email = email
		self.name = name
	}
}


extension Collaborator {
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
		let name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
		
		self.init(
			email: email,
			name: name
		)
	}
}
