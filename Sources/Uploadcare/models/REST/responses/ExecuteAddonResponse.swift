//
//  ExecuteAddonResponse.swift
//  
//
//  Created by Sergei Armodin on 15.09.2022.
//  Copyright © 2022 Uploadcare, Inc. All rights reserved.
//

import Foundation

/// Response that API will return for Exectute Add-On request.
public struct ExecuteAddonResponse: Codable {

	/// Request ID.
	public let requestID: String


	enum CodingKeys: String, CodingKey {
		case requestID = "request_id"
	}


	init(requestID: String) {
		self.requestID = requestID
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let requestID = try container.decode(String.self, forKey: .requestID)
		self.init(requestID: requestID)
	}

}
