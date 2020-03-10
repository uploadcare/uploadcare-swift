//
//  Project.swift
//  
//
//  Created by Sergey Armodin on 10.03.2020.
//

import Foundation


/// Project
public struct Project: Codable {
	
	/// Project login name.
	public var name: String
	
	/// Project public key.
	public var pubKey: String
	
	/// Collaborators
	public var collaborators: [Collaborator]?
	
	
	enum CodingKeys: String, CodingKey {
		case name
		case pubKey = "pub_key"
		case collaborators
	}
	
}


extension Project {
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
		let pubKey = try container.decodeIfPresent(String.self, forKey: .pubKey) ?? ""
		let collaborators = try container.decodeIfPresent([Collaborator].self, forKey: .collaborators)
		
		self.init(
			name: name,
			pubKey: pubKey,
			collaborators: collaborators
		)
	}
}
