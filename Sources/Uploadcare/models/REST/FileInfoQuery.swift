//
//  FileInfoQuery.swift
//  
//
//  Created by Sergei Armodin on 14.09.2022.
//  Copyright © 2022 Uploadcare, Inc. All rights reserved.
//

import Foundation

/// Defines params for file info request query.
///
/// Example:
/// ```swift
/// let fileInfoQuery = FileInfoQuery().include(.appdata)
/// ```
public class FileInfoQuery {

	/// Additional fields of the file object.
	public enum AdditionalFields: String {
		case appdata
	}


	// MARK: - Public properties

	/// Include additional fields to the file object, such as: appdata.
	public var include: AdditionalFields?

	/// String value for adding query params to url.
	public var stringValue: String {
		var array = [String]()

		if let includeValue = include {
			array.append("include=\(includeValue.rawValue)")
		}

		return array.joined(separator: "&")
	}


	// MARK: - Init
	public init(include: AdditionalFields? = nil) {
		self.include = include
	}


	// MARK: - Public methods

	/// Include additional fields to the file object, such as: appdata.
	/// - Parameter val: Additional field value.
	public func include(_ val: AdditionalFields?) -> Self {
		include = val
		return self
	}
}
