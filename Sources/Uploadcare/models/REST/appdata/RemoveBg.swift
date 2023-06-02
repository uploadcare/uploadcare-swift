//
//  RemoveBg.swift
//  
//
//  Created by Sergei Armodin on 15.09.2022.
//  Copyright © 2022 Uploadcare, Inc. All rights reserved.
//

import Foundation

public struct RemoveBg: Codable, Equatable {
	/// An application version.
	public let version: String

	/// Date and time when an application data was created.
	public let datetimeCreated: Date

	/// Date and time when an application data was updated.
	public let datetimeUpdated: Date

	/// Dictionary with a result of an application execution result.
	public let data: RemoveBgData

	enum CodingKeys: String, CodingKey {
		case version
		case datetimeCreated = "datetime_created"
		case datetimeUpdated = "datetime_updated"
		case data
	}

	init(version: String, datetimeCreated: Date, datetimeUpdated: Date, data: RemoveBg.RemoveBgData) {
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
		let data = try container.decode(RemoveBgData.self, forKey: .data)

		self.init(version: version, datetimeCreated: datetimeCreated, datetimeUpdated: datetimeUpdated, data: data)
	}
}

extension RemoveBg {
	public struct RemoveBgData: Codable, Equatable {
		internal init(foregroundType: String) {
			self.foregroundType = foregroundType
		}

		public let foregroundType: String

		enum CodingKeys: String, CodingKey {
			case foregroundType = "foreground_type"
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)

			let foregroundType = try container.decodeIfPresent(String.self, forKey: .foregroundType) ?? ""

			self.init(foregroundType: foregroundType)
		}
	}
}
