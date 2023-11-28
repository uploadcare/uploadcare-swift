//
//  UploadedFilesGroup.swift
//  
//
//  Created by Sergey Armodin on 13.02.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation


/// Uploaded files group details.
public class UploadedFilesGroup: Codable {
	
	/// Date and time when a group was created.
	public var datetimeCreated: Date
	
	/// Date and time when files in a group were stored.
	@available(*, deprecated, message: "To store or remove files from a group, query the list of files in it, split the list into chunks of 100 files per chunk and then perform batch file storing or batch file removal for all the chunks.")
	public var datetimeStored: Date?
	
	/// Number of files in a group.
	public var filesCount: Int
	
	/// Public CDN URL for a group.
	public var cdnUrl: String
	
	/// List of files in a group. Deleted files are represented as null to always preserve a number of files in a group in line with a group ID. This property is not available for group lists.
	public var files: [UploadedFile]?
	
	/// API resource URL for a group.
	public var url: String
	
	/// Group identifier.
	public var id: String
	
	/// UploadAPI
	private weak var uploadAPI: UploadAPI?
	
	
	enum CodingKeys: String, CodingKey {
		case datetimeCreated = "datetime_created"
		case datetimeStored = "datetime_stored"
		case filesCount = "files_count"
		case cdnUrl = "cdn_url"
		case files
		case url
		case id
	}
		
	init(
		datetimeCreated: Date,
		datetimeStored: Date?,
		filesCount: Int,
		cdnUrl: String,
		files: [UploadedFile]?,
		url: String,
		id: String
	) {
		self.datetimeCreated = datetimeCreated
		self.datetimeStored = datetimeStored
		self.filesCount = filesCount
		self.cdnUrl = cdnUrl
		self.files = files
		self.url = url
		self.id = id
	}
	
	required public convenience init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		var datetimeCreated = Date(timeIntervalSince1970: 0)
		var datetimeStored: Date? = nil
		
		let dateFormatter = DateFormatter()
		dateFormatter.locale = Locale(identifier: "en_US_POSIX")
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
		
		let datetimeCreatedString = try container.decodeIfPresent(String.self, forKey: .datetimeCreated)
		let datetimeStoredString = try container.decodeIfPresent(String.self, forKey: .datetimeStored)
		
		if let val = datetimeCreatedString, let date = dateFormatter.date(from: val) {
			datetimeCreated = date
		}
		if let val = datetimeStoredString {
			datetimeStored = dateFormatter.date(from: val)
		}
		
		let filesCount = try container.decodeIfPresent(Int.self, forKey: .filesCount) ?? 1
		let cdnUrl = try container.decodeIfPresent(String.self, forKey: .cdnUrl) ?? ""
		let files = try container.decodeIfPresent([UploadedFile].self, forKey: .files)
		let url = try container.decodeIfPresent(String.self, forKey: .url) ?? ""
		let id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
		
		self.init(
			datetimeCreated: datetimeCreated,
			datetimeStored: datetimeStored,
			filesCount: filesCount,
			cdnUrl: cdnUrl,
			files: files,
			url: url,
			id: id
		)
	}
	
	// MARK: - Public methods

	/// Init with files.
	/// - Parameters:
	///   - files: Files that should be grouped.
	///   - uploadAPI: Upload API object.
	public init(withFiles files: [UploadedFile], uploadAPI: UploadAPI) {
		self.datetimeCreated = Date()
		self.filesCount = files.count
		self.cdnUrl = ""
		self.files = files
		self.url = ""
		self.id = ""
		
		self.uploadAPI = uploadAPI
	}

	/// Create group of files.
	///
	/// Example:
	/// ```swift
	/// let files: [UploadedFile] = [file1, file2]
	/// let group = uploadcare.group(ofFiles: files)!
	///
	/// group.create { result in
	///     switch result {
	///     case .failure(let error):
	///         print(error.detail)
	///     case .success(let response):
	///         print(response)
	///     }
	/// }
	/// ```
	///
	/// - Parameter completionHandler: Completion handler.
	#if !os(Linux)
	public func create(_ completionHandler: @escaping (Result<UploadedFilesGroup, UploadError>) -> Void) {
		uploadAPI?.createFilesGroup(files: self.files ?? [], { [weak self] result in
			switch result {
			case .failure(let error):
				completionHandler(.failure(error))
			case .success(let createdGroup):
				guard let self = self else {
					completionHandler(.failure(UploadError.defaultError()))
					return
				}

				self.datetimeCreated = createdGroup.datetimeCreated
				self.filesCount = createdGroup.filesCount
				self.cdnUrl = createdGroup.cdnUrl
				self.files = createdGroup.files
				self.url = createdGroup.url
				self.id = createdGroup.id

				completionHandler(.success(self))
			}
		})
	}
	#endif

	/// Create group of files.
	///
	/// Example:
	/// ```swift
	/// let files: [UploadedFile] = [file1, file2]
	/// let group = try await uploadcare.group(ofFiles: files)!.create()
	/// print(group)
	/// ```
	///
	/// - Returns: Files group.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func create() async throws -> UploadedFilesGroup {
		guard let uploadAPI = uploadAPI else {
			throw UploadError(status: 0, detail: "Upload API object missing.")
		}

		let createdGroup = try await uploadAPI.createFilesGroup(files: files ?? [])

		datetimeCreated = createdGroup.datetimeCreated
		filesCount = createdGroup.filesCount
		cdnUrl = createdGroup.cdnUrl
		files = createdGroup.files
		url = createdGroup.url
		id = createdGroup.id

		return self
	}
}


extension UploadedFilesGroup: CustomDebugStringConvertible {
	public var debugDescription: String {
		return """
		\(type(of: self)):
			datetimeCreated: \(datetimeCreated)
			datetimeStored: \(String(describing: datetimeStored))
			filesCount: \(filesCount)
			cdnUrl: \(cdnUrl)
			files: \(String(describing: files))
			url: \(url)
			id: \(id)
		"""
	}
}
