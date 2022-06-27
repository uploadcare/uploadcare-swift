//
//  GroupsList.swift
//  
//
//  Created by Sergey Armodin on 05.02.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation


/// List of groups API method response
public class GroupsList: Codable {
	
	// MARK: - Public properties
	
	/// URL for next page request
	public var next: String?
	
	/// URL for previous page request
	public var previous: String?
	
	/// Total number of groups
	public var total: Int
	
	/// Number of groups per page
	public var perPage: Int
	
	/// List of groups from current page
	public var results: [Group]
	
	
	// MARK: - Private properties
	private var RESTAPI: Uploadcare?

	
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
		results: [Group]
	) {
		self.next = next
		self.previous = previous
		self.total = total
		self.perPage = perPage
		self.results = results
	}
	
	init(withGroups groups: [Group], api: Uploadcare) {
		self.next = nil
		self.previous = nil
		self.total = groups.count
		self.perPage = groups.count
		self.results = groups
		self.RESTAPI = api
	}

	required public convenience init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let next = try container.decodeIfPresent(String.self, forKey: .next)
		let previous = try container.decodeIfPresent(String.self, forKey: .previous)
		let total = try container.decodeIfPresent(Int.self, forKey: .total) ?? 0
		let perPage = try container.decodeIfPresent(Int.self, forKey: .perPage) ?? 0
		let results = try container.decodeIfPresent([Group].self, forKey: .results) ?? [Group]()

		self.init(
			next: next,
			previous: previous,
			total: total,
			perPage: perPage,
			results: results
		)
	}
	
}


extension GroupsList: CustomDebugStringConvertible {
	public var debugDescription: String {
		return """
		\(type(of: self)):
			next: \(String(describing: next)),
			previous: \(String(describing: previous)),
			total: \(total),
			perPage: \(perPage),
			results: \(results)
		"""
	}
}


// MARK: - Public methods
extension GroupsList {
	/// Get list of files
	/// - Parameters:
	///   - query: query object
	///   - completionHandler: completion hanlder
	public func get(
		withQuery query: GroupsListQuery? = nil,
		_ completionHandler: @escaping (Result<GroupsList, RESTAPIError>) -> Void
	) {
		guard let api = RESTAPI else {
			completionHandler(.failure(RESTAPIError.defaultError()))
			return
		}

		api.listOfGroups(withQuery: query) { [weak self] result in
			guard let self = self else {
				completionHandler(.failure(RESTAPIError.defaultError()))
				return
			}

			switch result {
			case .failure(let error):
				completionHandler(.failure(error))
			case .success(let list):
				self.next = list.next
				self.previous = list.previous
				self.total = list.total
				self.perPage = list.perPage
				self.results = list.results
				completionHandler(.success(list))
			}
		}
	}

	/// Get next page of files list
	/// - Parameter completionHandler: completion handler
	public func nextPage(_ completionHandler: @escaping (Result<GroupsList, RESTAPIError>) -> Void) {
		guard let next = next, let query = URL(string: next)?.query else {
			self.results = []
			completionHandler(.success(self))
			return
		}

		getPage(withQueryString: query, completionHandler)
	}

	/// Get previous page of files list
	/// - Parameter completionHandler: completion handler
	public func previousPage(_ completionHandler: @escaping (Result<GroupsList, RESTAPIError>) -> Void) {
		guard let previous = previous, let query = URL(string: previous)?.query else {
			completionHandler(.failure(RESTAPIError.defaultError()))
			return
		}

		getPage(withQueryString: query, completionHandler)
	}
}


// MARK: - Private methods
private extension GroupsList {
	/// Get page of files list
	/// - Parameters:
	///   - query: query string
	///   - completionHandler: completion handler
	func getPage(
		withQueryString query: String,
		_ completionHandler: @escaping (Result<GroupsList, RESTAPIError>) -> Void
	) {
		guard let api = RESTAPI else {
			completionHandler(.failure(RESTAPIError.defaultError()))
			return
		}
		
		api.listOfGroups(withQueryString: query) { [weak self] result in
			guard let self = self else { return }

			switch result {
			case .failure(let error):
				completionHandler(.failure(error))
			case .success(let groupsList):
				self.next = groupsList.next
				self.previous = groupsList.previous
				self.total = groupsList.total
				self.perPage = groupsList.perPage
				self.results = groupsList.results
				completionHandler(.success(groupsList))
			}
		}
	}
}

// MARK: - Deprecated methods
extension GroupsList {
	/// Get list of files
	/// - Parameters:
	///   - query: query object
	///   - completionHandler: completion hanlder
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func get(
		withQuery query: GroupsListQuery? = nil,
		_ completionHandler: @escaping (GroupsList?, RESTAPIError?) -> Void
	) {
		get(withQuery: query) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let groupsList): completionHandler(groupsList, nil)
			}
		}
	}

	/// Get next page of files list
	/// - Parameter completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func nextPage(_ completionHandler: @escaping (GroupsList?, RESTAPIError?) -> Void) {
		nextPage { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let groupsList): completionHandler(groupsList, nil)
			}
		}
	}

	/// Get previous page of files list
	/// - Parameter completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func previousPage(_ completionHandler: @escaping (GroupsList?, RESTAPIError?) -> Void) {
		previousPage { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let groupsList): completionHandler(groupsList, nil)
			}
		}
	}
}
