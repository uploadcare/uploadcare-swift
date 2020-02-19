//
//  UploadFromURLTask.swift
//  
//
//  Created by Sergey Armodin on 25.01.2020.
//

import Foundation


/// Storing behavior enum
public enum StoringBehavior: String {
	case doNotstore = "0"
	case store = "1"
	case auto = "auto"
}


/**
	Struct that defines params for uploading a file from url.

	**Example:**
	```
	var task = UploadFromURLTask(sourceUrl: URL(string: "https://example.com/file.png")!)
	task.filename = "newname.png"
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
	
	/// signature is a string sent along with your upload request. It requires your Uploadcare project secret key and hence should be crafted on your back end. See Signed uploads for details.
	public var signature: String?
	
	/// expire sets the time until your signature is valid. It is timestamp. See Signed uploads for details.
	public var expire: TimeInterval?
	
	
	// MARK: - Init
	public init(
		sourceUrl: URL,
		store: StoringBehavior? = .auto,
		filename: String? = nil,
		checkURLDuplicates: Bool? = nil,
		saveURLDuplicates: Bool? = nil,
		signature: String? = nil,
		expire: TimeInterval? = nil
	) {
		self.sourceUrl = sourceUrl
		self.store = store ?? .auto
		self.filename = filename
		self.checkURLDuplicates = checkURLDuplicates
		self.saveURLDuplicates = saveURLDuplicates
		self.signature = signature
		self.expire = expire
	}
	
	public func store(_ val: StoringBehavior?) -> Self {
		store = val ?? .auto
		return self
	}
	
	public func filename(_ val: String?) -> Self {
		filename = val
		return self
	}
	
	public func checkURLDuplicates(_ val: Bool?) -> Self {
		checkURLDuplicates = val
		return self
	}
	
	public func saveURLDuplicates(_ val: Bool?) -> Self {
		saveURLDuplicates = val
		return self
	}
}
