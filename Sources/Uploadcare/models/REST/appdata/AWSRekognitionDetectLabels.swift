//
//  UCClamavVirusScan.swift
//
//
//  Created by Sergei Armodin on 15.09.2022.
//  Copyright © 2022 Uploadcare, Inc. All rights reserved.
//

import Foundation

public struct AWSRekognitionDetectLabels: Codable, Equatable {
	/// An application version.
	public let version: String

	/// Date and time when an application data was created.
	public let datetimeCreated: Date

	/// Date and time when an application data was updated.
	public let datetimeUpdated: Date

	/// Dictionary with a result of an application execution result.
	public let data: AWSRecognitionData

	enum CodingKeys: String, CodingKey {
		case version
		case datetimeCreated = "datetime_created"
		case datetimeUpdated = "datetime_updated"
		case data
	}

	internal init(version: String, datetimeCreated: Date, datetimeUpdated: Date, data: AWSRekognitionDetectLabels.AWSRecognitionData) {
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
		let data = try container.decode(AWSRecognitionData.self, forKey: .data)

		self.init(version: version, datetimeCreated: datetimeCreated, datetimeUpdated: datetimeUpdated, data: data)
	}
}

extension AWSRekognitionDetectLabels {
	public struct BoundingBox: Codable, Equatable {
		public let height: Double, left: Double, top: Double, width: Double

		enum CodingKeys: String, CodingKey {
			case height = "Height"
			case left = "Left"
			case top = "Top"
			case width = "Width"
		}

		internal init(height: Double, left: Double, top: Double, width: Double) {
			self.height = height
			self.left = left
			self.top = top
			self.width = width
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)

			let height = try container.decodeIfPresent(Double.self, forKey: .height) ?? 0
			let left = try container.decodeIfPresent(Double.self, forKey: .left) ?? 0
			let top = try container.decodeIfPresent(Double.self, forKey: .top) ?? 0
			let width = try container.decodeIfPresent(Double.self, forKey: .width) ?? 0

			self.init(height: height, left: left, top: top, width: width)
		}
	}

	public struct Instance: Codable, Equatable {
		public let boundingBox: BoundingBox
		public let confidence: Double

		enum CodingKeys: String, CodingKey {
			case boundingBox = "BoundingBox"
			case confidence = "Confidence"
		}

		internal init(boundingBox: AWSRekognitionDetectLabels.BoundingBox, confidence: Double) {
			self.boundingBox = boundingBox
			self.confidence = confidence
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)

			let boundingBox = try container.decode(BoundingBox.self, forKey: .boundingBox)
			let confidence = try container.decodeIfPresent(Double.self, forKey: .confidence) ?? 0

			self.init(boundingBox: boundingBox, confidence: confidence)
		}
	}

	public struct Parent: Codable, Equatable {
		public let name: String

		enum CodingKeys: String, CodingKey {
			case name = "Name"
		}

		internal init(name: String) {
			self.name = name
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			let name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
			self.init(name: name)
		}
	}

	public struct Label: Codable, Equatable {
		public let confidence: Double
		public let instances: [Instance]
		public let name: String
		public let parents: [Parent]

		enum CodingKeys: String, CodingKey {
			case confidence = "Confidence"
			case instances = "Instances"
			case name = "Name"
			case parents = "Parents"
		}

		internal init(confidence: Double, instances: [AWSRekognitionDetectLabels.Instance], name: String, parents: [AWSRekognitionDetectLabels.Parent]) {
			self.confidence = confidence
			self.instances = instances
			self.name = name
			self.parents = parents
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)

			let confidence = try container.decode(Double.self, forKey: .confidence)
			let instances = try container.decode([Instance].self, forKey: .instances)
			let name = try container.decode(String.self, forKey: .name)
			let parents = try container.decode([Parent].self, forKey: .parents)

			self.init(confidence: confidence, instances: instances, name: name, parents: parents)
		}
	}

	public struct AWSRecognitionData: Codable, Equatable {
		public let labelModelVersion: String
		public let labels: [Label]

		enum CodingKeys: String, CodingKey {
			case labelModelVersion = "LabelModelVersion"
			case labels = "Labels"
		}

		internal init(labelModelVersion: String, labels: [AWSRekognitionDetectLabels.Label]) {
			self.labelModelVersion = labelModelVersion
			self.labels = labels
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)

			let labelModelVersion = try container.decode(String.self, forKey: .labelModelVersion)
			let labels = try container.decode([Label].self, forKey: .labels)

			self.init(labelModelVersion: labelModelVersion, labels: labels)
		}
	}
}
