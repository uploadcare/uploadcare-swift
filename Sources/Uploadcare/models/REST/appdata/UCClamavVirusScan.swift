//
//  UCClamavVirusScan.swift
//  
//
//  Created by Sergei Armodin on 15.09.2022.
//  Copyright © 2022 Uploadcare, Inc. All rights reserved.
//

import Foundation

public struct UCClamavVirusScan: Codable, Equatable {
	/// An application version.
	public let version: String

	/// Date and time when an application data was created.
	public let datetimeCreated: Date

	/// Date and time when an application data was updated.
	public let datetimeUpdated: Date

	/// Dictionary with a result of an application execution result.
	public let data: ClamavData

	enum CodingKeys: String, CodingKey {
		case version
		case datetimeCreated = "datetime_created"
		case datetimeUpdated = "datetime_updated"
		case data
	}

	internal init(version: String, datetimeCreated: Date, datetimeUpdated: Date, data: UCClamavVirusScan.ClamavData) {
		self.version = version
		self.datetimeCreated = datetimeCreated
		self.datetimeUpdated = datetimeUpdated
		self.data = data
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		var datetimeCreated = Date(timeIntervalSince1970: 0)
		var datetimeUpdated = Date(timeIntervalSince1970: 0)

		let dateFormatter = DateFormatter()
		dateFormatter.locale = Locale(identifier: "en_US_POSIX")
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

		let datetimeCreatedString = try container.decodeIfPresent(String.self, forKey: .datetimeCreated)
		let datetimeUpdatedString = try container.decodeIfPresent(String.self, forKey: .datetimeUpdated)

		if let val = datetimeCreatedString, let date = dateFormatter.date(from: val) {
			datetimeCreated = date
		}
		if let val = datetimeUpdatedString, let date = dateFormatter.date(from: val) {
			datetimeUpdated = date
		}

		let version = try container.decodeIfPresent(String.self, forKey: .version) ?? ""
		let data = try container.decode(ClamavData.self, forKey: .data)

		self.init(version: version, datetimeCreated: datetimeCreated, datetimeUpdated: datetimeUpdated, data: data)
	}
}


extension UCClamavVirusScan {
	public struct ClamavData: Codable, Equatable {
		public let infected: Bool
		public let infectedWith: String

		enum CodingKeys: String, CodingKey {
			case infected
			case infectedWith = "infected_with"
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)

			let infected = try container.decode(Bool.self, forKey: .infected)
			let infectedWith = try container.decodeIfPresent(String.self, forKey: .infectedWith) ?? ""

			self.init(infected: infected, infectedWith: infectedWith)
		}

		internal init(infected: Bool, infectedWith: String) {
			self.infected = infected
			self.infectedWith = infectedWith
		}
	}
}
