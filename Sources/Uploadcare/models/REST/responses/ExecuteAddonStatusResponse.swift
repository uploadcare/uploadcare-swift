//
//  ExecuteAddonStatusResponse.swift
//
//
//  Created by Sergei Armodin on 15.09.2022.
//  Copyright © 2022 Uploadcare, Inc. All rights reserved.
//

import Foundation

public enum AddonExecutionStatus: String {
	case inProgress = "in_progress"
	case error, done, unknown
}

/// Response that API will return for Exectute Add-On request.
internal struct ExecuteAddonStatusResponse: Codable {
	/// Defines the status of an Add-On execution. In most cases, once the status changes to done, Application Data of the file that had been specified as a target, will contain the result of the execution.
	var status: String

	enum CodingKeys: String, CodingKey {
		case status
	}


	init(status: String) {
		self.status = status
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let status = try container.decode(String.self, forKey: .status)
		self.init(status: status)
	}

}
