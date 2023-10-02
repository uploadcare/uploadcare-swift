//
//  Webhook.swift
//
//
//  Created by Sergey Armodin on 19.07.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation

/// Webhook.
public struct Webhook: Codable {
	public enum Event: String, Codable {
		case fileUploaded = "file.uploaded"
		case fileInfected = "file.infected"
		case fileStored = "file.stored"
		case fileDeleted = "file.deleted"
		case fileInfoUpdated = "file.info_updated"
	}

	public enum Version: String, Codable {
		case v0_5 = "0.5"
		case v0_6 = "0.6"
		case v0_7 = "0.7"
	}

	/// Webhook's ID.
	public var id: Int

	/// Project ID the webhook belongs to.
	public var project: Int

	/// date-time when a webhook was created.
	public var created: Date

	/// date-time when a webhook was updated.
	public var updated: Date

	/// An event you subscribe to.
	public var event: Event

	/// A URL that is triggered by an event, for example, a file upload. A target URL MUST be unique for each `project` — `event type` combination.
	public var targetUrl: String

	/// Marks a subscription as either active or not, defaults to `true`, otherwise `false`.
	public var isActive: Bool

	/// Webhook payload's version.
	public var version: Version?

	/// Optional HMAC/SHA-256 secret that, if set, will be used to calculate signatures for the webhook payloads sent to the target_url.
	///
	/// Calculated signature will be sent to the `target_url` as a value of the `X-Uc-Signature` HTTP header. The header will have the following format: X-Uc-Signature: v1=<HMAC-SHA256-HEX-DIGEST>.
	public var signingSecret: String


	enum CodingKeys: String, CodingKey {
		case id
		case project
		case created
		case updated
		case event
		case targetUrl = "target_url"
		case isActive = "is_active"
		case version
		case signingSecret = "signing_secret"
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
		project = try container.decodeIfPresent(Int.self, forKey: .project) ?? 0

		// Date formatter for parsing
		let dateFormatter = DateFormatter()
		dateFormatter.locale = Locale(identifier: "en_US_POSIX")
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

		var dateCreated = Date(timeIntervalSince1970: 0)
		let dateCreatedString = try container.decodeIfPresent(String.self, forKey: .created)
		if let val = dateCreatedString, let date = dateFormatter.date(from: val) {
			dateCreated = date
		}
		created = dateCreated

		var dateUpdated = Date(timeIntervalSince1970: 0)
		let dateUpdatedString = try container.decodeIfPresent(String.self, forKey: .updated)
		if let val = dateUpdatedString, let date = dateFormatter.date(from: val) {
			dateUpdated = date
		}
		updated = dateUpdated

		event = try container.decodeIfPresent(Event.self, forKey: .event) ?? .fileInfoUpdated
		targetUrl = try container.decodeIfPresent(String.self, forKey: .targetUrl) ?? ""
		isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? false
		
		if let versionString = try container.decodeIfPresent(String.self, forKey: .version) {
			version = Version(rawValue: versionString)
		}
		signingSecret = try container.decodeIfPresent(String.self, forKey: .signingSecret) ?? ""
	}
}
