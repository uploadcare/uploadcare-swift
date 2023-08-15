//
//  PaginationQuery.swift
//  
//
//  Created by Sergey Armodin on 03.02.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation

/**
 Defines params for files list query

 Example:
 ```swift
 // Might be used with init method with values:
 let query1 = PaginationQuery(removed: true, stored: false, limit: 10, ordering: .sizeDESC)

 // Might be used with chaining API:
 let query2 = PaginationQuery()
     .removed(false)
     .stored(true)
     .limit(10)
 ```
*/
public class PaginationQuery {
	
	/// Max value for limit.
	internal static let maxLimitValue: Int = 10000
	
	public enum Ordering {
		case dateTimeUploadedASC(from: Date?)
		case dateTimeUploadedDESC
		
		internal var stringValue: String {
			switch self {
			case .dateTimeUploadedASC(let from):
				var fromString = ""

				if let date = from {
					let formatter = DateFormatter()
					formatter.timeZone = TimeZone(identifier: "GMT")
					// date format should be YYYY-MM-DDTHH:MM:SS, where T is used as a separator
					formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
					let dateString = formatter.string(from: date)
					fromString = "&from=\(dateString)"
				}
				
				return "ordering=datetime_uploaded" + fromString
			case .dateTimeUploadedDESC:
				return "ordering=-datetime_uploaded"
			}
		}
	}
	
	
	// MARK: - Public properties
	
	/// `true` to only include removed files in the response, false to include existing files. Defaults to `false`.
	public var removed: Bool?
	/// `true` to only include files that were stored, false to include temporary ones. The default is unset: both stored and not stored files are returned.
	public var stored: Bool?
	/// A preferred amount of files in a list for a single response. Defaults to 100, while the maximum is 1000.
	public var limit: Int?
	/// Specifies the way files are sorted in a returned list. The default ordering option is `.dateTimeUploadedASC`.
	public var ordering: Ordering?
	
	
	/// String value for adding query params to url.
	public var stringValue: String {
		var array = [String]()
		
		if let removedValue = removed {
			array.append("removed=\(removedValue)")
		}
		
		if let storedValue = stored {
			array.append("stored=\(storedValue)")
		}
		
		if let limitValue = limit {
			array.append("limit=\(limitValue)")
		}
		
		if let orderingValue = ordering {
			array.append(orderingValue.stringValue)
		}
		
		return array.joined(separator: "&")
	}
	
	
	// MARK: - Init
	public init(removed: Bool? = nil, stored: Bool? = nil, limit: Int? = nil, ordering: Ordering? = nil) {
		self.removed = removed
		self.stored = stored
		
		if let limitValue = limit {
			if limitValue >= 0 {
				self.limit = limitValue > Self.maxLimitValue ? Self.maxLimitValue : limitValue
			} else {
				self.limit = 0
			}
		}
		
		self.ordering = ordering
	}
	
	
	// MARK: - Public methods
	
	/// Sets removed param to query.
	/// - Parameter val: value
	public func removed(_ val: Bool?) -> Self {
		removed = val
		return self
	}
	
	/// Sets stored param to query.
	/// - Parameter val: value
	public func stored(_ val: Bool?) -> Self {
		stored = val
		return self
	}
	
	/// Sets limit param to query.
	/// - Parameter val: value
	public func limit(_ val: Int?) -> Self {
		if let limitValue = val {
			if limitValue >= 0 {
				limit = limitValue > Self.maxLimitValue ? Self.maxLimitValue : limitValue
			} else {
				limit = 0
			}
		}
		return self
	}
	
	/// Sets ordering param to query.
	/// - Parameter val: value
	public func ordering(_ val: Ordering) -> Self {
		ordering = val
		return self
	}
}
