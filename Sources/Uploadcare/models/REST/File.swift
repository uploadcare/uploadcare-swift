//
//  File.swift
//  
//
//  Created by Sergey Armodin on 03.02.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation


/// File info model that is used for REST API.
public struct File: Codable, Equatable {
	
	/// File size in bytes.
	public var size: Int
	
	/// File UUID.
	public var uuid: String
	
	/// Original file name taken from uploaded file.
	public var originalFilename: String
	
	/// File MIME-type.
	public var mimeType: String
	
	/// Is file an image.
	public var isImage: Bool
	
	/// Is file ready to be used after upload.
	public var isReady: Bool
	
	/// Date and time when a file was removed, if any.
	public var datetimeRemoved: Date?
	
	/// Date and time of the last store request, if any.
	public var datetimeStored: Date?
	
	/// Date and time when a file was uploaded.
	public var datetimeUploaded: Date
	
	/// Publicly available file CDN URL. Available if a file is not deleted.
	public var originalFileUrl: String?
	
	/// API resource URL for a particular file.
	public var url: String
	
	/// File upload source. This field contains information about from where file was uploaded, for example: facebook, gdrive, gphotos, etc.
	public var source: String?
	
	/// Dictionary of other files that has been created using this file as source. Used for video, document and etc. conversion.
	public var variations: [String: String]?

	/// Arbitrary metadata associated with a file.
	/// Metadata is key-value data. You can specify up to 50 keys, with key names up to 64 characters long and values up to 512 characters long.
	public var metadata: [String: String]?

	/// Information about file content.
	public var contentInfo: ContentInfo?

	/// Application names and data associated with these applications.
	public let appData: AppData?

	/// The field contains a set of processing operations applied to the file when the group was created. This set is applied by default when the file is reffered via a group CDN URL and `/nth/N/` operator.
	public let defaultEffects: String?


	enum CodingKeys: String, CodingKey {
		case size
		case uuid
		case originalFilename = "original_filename"
		case mimeType = "mime_type"
		case isImage = "is_image"
		case isReady = "is_ready"
		case datetimeRemoved = "datetime_removed"
		case datetimeStored = "datetime_stored"
		case datetimeUploaded = "datetime_uploaded"
		case originalFileUrl = "original_file_url"
		case url
		case source
		case variations
		case metadata
		case contentInfo = "content_info"
		case appData = "appdata"
		case defaultEffects = "default_effects"
	}
	
	
	public init(
		size: Int,
		uuid: String,
		originalFilename: String,
		mimeType: String,
		isImage: Bool,
		isReady: Bool,
		datetimeRemoved: Date?,
		datetimeStored: Date?,
		datetimeUploaded: Date,
		originalFileUrl: String?,
		url: String,
		source: String?,
		variations: [String: String]?,
		contentInfo: ContentInfo?,
		metadata: [String: String]?,
		appData: AppData?,
		defaultEffects: String?
	) {
		self.size = size
		self.uuid = uuid
		self.originalFilename = originalFilename
		self.mimeType = mimeType
		self.isImage = isImage
		self.isReady = isReady
		self.datetimeRemoved = datetimeRemoved
		self.datetimeStored = datetimeStored
		self.datetimeUploaded = datetimeUploaded
		self.originalFileUrl = originalFileUrl
		self.url = url
		self.source = source
		self.variations = variations
		self.contentInfo = contentInfo
		self.metadata = metadata
		self.appData = appData
		self.defaultEffects = defaultEffects
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let size = try container.decodeIfPresent(Int.self, forKey: .size) ?? 0
		let uuid = try container.decodeIfPresent(String.self, forKey: .uuid) ?? ""
		let originalFilename = try container.decodeIfPresent(String.self, forKey: .originalFilename) ?? ""
		let mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType) ?? ""
		let isImage = try container.decodeIfPresent(Bool.self, forKey: .isImage) ?? false
		let isReady = try container.decodeIfPresent(Bool.self, forKey: .isReady) ?? false
		

		var datetimeRemoved: Date? = nil
		var datetimeStored: Date? = nil
		var datetimeUploaded = Date(timeIntervalSince1970: 0)
		
		let dateFormatter = DateFormatter()
		dateFormatter.locale = Locale(identifier: "en_US_POSIX")
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
		
		let datetimeRemovedString = try container.decodeIfPresent(String.self, forKey: .datetimeRemoved)
		let datetimeStoredString = try container.decodeIfPresent(String.self, forKey: .datetimeStored)
		let datetimeUploadedString = try container.decodeIfPresent(String.self, forKey: .datetimeUploaded)
		
		if let val = datetimeRemovedString {
			datetimeRemoved = dateFormatter.date(from: val)
		}
		if let val = datetimeStoredString {
			datetimeStored = dateFormatter.date(from: val)
		}
		if let val = datetimeUploadedString {
			datetimeUploaded = dateFormatter.date(from: val) ?? Date(timeIntervalSince1970: 0)
		}
		
		let originalFileUrl = try container.decodeIfPresent(String.self, forKey: .originalFileUrl)
		let url = try container.decodeIfPresent(String.self, forKey: .url) ?? ""
		let source = try container.decodeIfPresent(String.self, forKey: .source)
		let variations = try container.decodeIfPresent([String: String].self, forKey: .variations)
		let contentInfo = try container.decodeIfPresent(ContentInfo.self, forKey: .contentInfo)
		let metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata)
		let appData = try container.decodeIfPresent(AppData.self, forKey: .appData)
		let defaultEffects = try container.decodeIfPresent(String.self, forKey: .defaultEffects)

		self.init(
			size: size,
			uuid: uuid,
			originalFilename: originalFilename,
			mimeType: mimeType,
			isImage: isImage,
			isReady: isReady,
			datetimeRemoved: datetimeRemoved,
			datetimeStored: datetimeStored,
			datetimeUploaded: datetimeUploaded,
			originalFileUrl: originalFileUrl,
			url: url,
			source: source,
			variations: variations,
			contentInfo: contentInfo,
			metadata: metadata,
			appData: appData,
			defaultEffects: defaultEffects
		)
	}
}


extension File: CustomDebugStringConvertible {
	public var debugDescription: String {
		return """
		\(type(of: self)):
			size: \(size),
			uuid: \(uuid),
			originalFilename: \(originalFilename),
			mimeType: \(mimeType),
			isImage: \(isImage),
			isReady: \(isReady),
			datetimeRemoved: \(String(describing: datetimeRemoved)),
			datetimeStored: \(String(describing: datetimeStored)),
			datetimeUploaded: \(datetimeUploaded),
			originalFileUrl: \(String(describing: originalFileUrl)),
			url: \(url),
			source: \(String(describing: source)),
			variations: \(String(describing: variations)),
			contentInfo: \(String(describing: contentInfo)),
			metadata: \(String(describing: metadata)),
			appData: \(String(describing: appData)),
			defaultEffects: \(String(describing: defaultEffects))
		"""
	}
}
