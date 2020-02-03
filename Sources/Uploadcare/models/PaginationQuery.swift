//
//  PaginationQuery.swift
//  
//
//  Created by Sergey Armodin on 03.02.2020.
//

import Foundation


public struct PaginationQuery {
	
	/// Max value for limit
	internal static let maxLimitValue: Int = 10000
	
	public enum Ordering {
		case dateTimeUploadedASC(from: Date)
		case dateTimeUploadedDESC
		case sizeASC(from: Int)
		case sizeDESC
		
		public var stringValue: String {
			switch self {
			case .dateTimeUploadedASC(let date):
				let formatter = DateFormatter()
				formatter.timeZone = TimeZone(identifier: "GMT")
				// date format should be YYYY-MM-DDTHH:MM:SS, where T is used as a separator
				formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
				let dateString = formatter.string(from: date)
				
				return "ordering=datetime_uploaded&from=\(dateString)"
			case .dateTimeUploadedDESC:
				return "-datetime_uploaded"
			case .sizeASC(let size):
				return "ordering=size&from=\(size)"
			case .sizeDESC:
				return "ordering=-size"
			}
		}
	}
	
	/// true to only include removed files in the response, false to include existing files. Defaults to false.
	public var removed: Bool?
	
	/// true to only include files that were stored, false to include temporary ones. The default is unset: both stored and not stored files are returned.
	public var stored: Bool?
	
	/// A preferred amount of files in a list for a single response. Defaults to 100, while the maximum is 1000.
	public var limit: Int?
	
	/// Specifies the way files are sorted in a returned list. The default ordering option is .dateTimeUploadedASC.
	public var ordering: Ordering?
	
	
	public init(removed: Bool?, stored: Bool?, limit: Int?, ordering: Ordering?) {
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
}
