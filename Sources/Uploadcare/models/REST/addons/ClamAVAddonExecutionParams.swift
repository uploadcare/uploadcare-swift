//
//  ClamAVAddonExecutionParams.swift
//  
//
//  Created by Sergei Armodin on 16.09.2022.
//

import Foundation

/// ClamAV Add-On specific parameters.
public struct ClamAVAddonExecutionParams: Codable {

	/// Purge infected file.
	public let purgeInfected: Bool


	enum CodingKeys: String, CodingKey {
		case purgeInfected = "purge_infected"
	}


	public init(purgeInfected: Bool) {
		self.purgeInfected = purgeInfected
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let purgeInfected = try container.decode(Bool.self, forKey: .purgeInfected)
		self.init(purgeInfected: purgeInfected)
	}

}

internal struct ClamAVAddonExecutionRequestBody: Codable {
	let target: String
	let params: ClamAVAddonExecutionParams?
}
