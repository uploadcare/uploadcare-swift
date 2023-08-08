//
//  GroupsListQuery.swift
//  
//
//  Created by Sergey Armodin on 05.02.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation


/**
Defines params for groups list query

 Example:
 ```swift
 // Might be used with init method with values:
 let query = GroupsListQuery(limit: 100, from: Date(timeIntervalSince1970: 1580895369), ordering: .datetimeCreatedDESC)

 // Might be used with chaining
 let query1 = GroupsListQuery()
     .limit(100)
     .from(Date(timeIntervalSince1970: 1580895369))
     .ordering(.datetimeCreatedDESC)
 ```
*/
public class GroupsListQuery {
	
	/// Max value for limit
	internal static let maxLimitValue: Int = 10000
	
	public enum Ordering: String {
		case datetimeCreatedASC = "datetime_created"
		case datetimeCreatedDESC = "-datetime_created"
		
		internal var stringValue: String {
			return "ordering=\(self.rawValue)"
		}
	}
	
	// MARK: - Public properties
	
	/// A preferred amount of groups in a list for a single response. Defaults to 100, while the maximum is 1000.
	public var limit: Int?
	
	/// A starting point for filtering group lists.
	public var from: Date?
	
	/// Specifies the way groups are sorted in a returned list by creation time. datetime_created for ascending order, -datetime_created for descending order.
	public var ordering: Ordering?
	
	
	// MARK: - Public properties
	
	/// String value for adding query params to url
	public var stringValue: String {
		var array = [String]()
		
		if let limitValue = limit {
			array.append("limit=\(limitValue)")
		}
		
		if let fromValue = from {
			let formatter = DateFormatter()
			formatter.timeZone = TimeZone(identifier: "GMT")
			// MUST be a datetime value with T used as a separator. Example: from=2015-01-02T10:00:00
			formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
			let dateString = formatter.string(from: fromValue)
			
			array.append("from=\(dateString)")
		}
		
		if let orderingValue = ordering {
			array.append(orderingValue.stringValue)
		}
		
		return array.joined(separator: "&")
	}
	
	
	// MARK: - Init
	public init(limit: Int? = nil, from: Date? = nil, ordering: Ordering? = nil) {
		if let limitValue = limit {
			if limitValue >= 0 {
				self.limit = limitValue > Self.maxLimitValue ? Self.maxLimitValue : limitValue
			} else {
				self.limit = 0
			}
		}
		
		self.from = from
		self.ordering = ordering
	}
	
	
	// MARK: - Public methods
	
	/// Sets limit param to query
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
	
	/// Sets from param to query
	/// - Parameter val: value
	public func from(_ val: Date?) -> Self {
		from = val
		return self
	}
	
	/// Sets ordering param to query
	/// - Parameter val: value
	public func ordering(_ val: Ordering) -> Self {
		ordering = val
		return self
	}
}
