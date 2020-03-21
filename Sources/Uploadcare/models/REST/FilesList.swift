//
//  FilesList.swift
//  
//
//  Created by Sergey Armodin on 03.02.2020.
//

import Foundation


public struct FilesList: Codable {
	
	public var next: String?
	public var previous: String?
	public var total: Int
	public var perPage: Int
	public var results: [File]

	
	enum CodingKeys: String, CodingKey {
		case next
		case previous
		case total
		case perPage = "per_page"
		case results
	}
	
	
	init(
		next: String?,
		previous: String?,
		total: Int,
		perPage: Int,
		results: [File]
	) {
		self.next = next
		self.previous = previous
		self.total = total
		self.perPage = perPage
		self.results = results
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let next = try container.decodeIfPresent(String.self, forKey: .next)
		let previous = try container.decodeIfPresent(String.self, forKey: .previous)
		let total = try container.decodeIfPresent(Int.self, forKey: .total) ?? 0
		let perPage = try container.decodeIfPresent(Int.self, forKey: .perPage) ?? 0
		let results = try container.decodeIfPresent([File].self, forKey: .results) ?? [File]()

		self.init(
			next: next,
			previous: previous,
			total: total,
			perPage: perPage,
			results: results
		)
	}
	
}
