//
//  UploadFromURLTask.swift
//  
//
//  Created by Sergey Armodin on 25.01.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation


/// Storing behavior enum.
public enum StoringBehavior: String {
	case doNotStore = "0"
	case store = "1"
	case auto = "auto"
}


/**
 Struct that defines params for uploading a file from url.

 Example:
 ```swift
 var task = UploadFromURLTask(sourceUrl: URL(string: "https://example.com/file.png")!)
 task.filename = "newName.png"
 task.store = .store
 ```
*/
public class UploadFromURLTask {
	
	/// Defines your source file URL, which should be a public HTTP or HTTPS link.
	public let sourceUrl: URL
	
	/// Sets the file storing behavior.
	public var store: StoringBehavior = .auto
	
	/// Sets the name for a file uploaded from URL. If not defined, the filename is obtained from either response headers or a source URL.
	public var filename: String?
	
	/// Runs the duplicate check and provides the immediate-download behavior.
	public var checkURLDuplicates: Bool?
	
	/// Provides the save/update URL behavior. The parameter can be used if you believe a source_url will be used more than once. If you don’t explicitly define save_URL_duplicates, it is by default set to the value of check_URL_duplicates.
	public var saveURLDuplicates: Bool?

	/// Arbitrary metadata associated with a file.
	/// Metadata is key-value data. You can specify up to 50 keys, with key names up to 64 characters long and values up to 512 characters long.
	public var metadata: [String: String]?
	
	// MARK: - Init
	public init(
		sourceUrl: URL,
		store: StoringBehavior? = .auto,
		filename: String? = nil,
		checkURLDuplicates: Bool? = nil,
		saveURLDuplicates: Bool? = nil,
		metadata: [String: String]? = nil
	) {
		self.sourceUrl = sourceUrl
		self.store = store ?? .auto
		self.filename = filename
		self.checkURLDuplicates = checkURLDuplicates
		self.saveURLDuplicates = saveURLDuplicates
		self.metadata = metadata
	}
	
	/// Sets the file storing behavior.
	public func store(_ val: StoringBehavior?) -> Self {
		store = val ?? .auto
		return self
	}
	
	/// Sets the name for a file uploaded from URL. If not defined, the filename is obtained from either response headers or a source URL.
	public func filename(_ val: String?) -> Self {
		filename = val
		return self
	}
	
	/// Runs the duplicate check and provides the immediate-download behavior.
	public func checkURLDuplicates(_ val: Bool?) -> Self {
		checkURLDuplicates = val
		return self
	}
	
	/// Provides the save/update URL behavior. The parameter can be used if you believe a ``sourceUrl`` will be used more than once. If you don’t explicitly define ``saveURLDuplicates``, it is by default set to the value of ``checkURLDuplicates``.
	public func saveURLDuplicates(_ val: Bool?) -> Self {
		saveURLDuplicates = val
		return self
	}

	/// Set metadata for uploaded file.
	/// - Parameters:
	///   - val: Metadata value.
	///   - key: Metadata key.
	/// - Returns: UploadFromURLTask.
	public func setMetadata(_ val: String?, forKey key: String) -> Self {
		if metadata == nil { metadata = [:] }
		if let value = val {
			metadata?[key] = value
		} else {
			metadata?.removeValue(forKey: key)
		}
		return self
	}
}
