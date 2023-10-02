//
//  GroupsList.swift
//  
//
//  Created by Sergey Armodin on 05.02.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation


/// Response for a request to List of groups API method.
public class GroupsList: Codable {
	
	// MARK: - Public properties
	
	/// URL for next page request.
	public var next: String?
	
	/// URL for previous page request.
	public var previous: String?
	
	/// Total number of groups.
	public var total: Int
	
	/// Number of groups per page.
	public var perPage: Int
	
	/// List of groups from current page.
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

// MARK: - Public async methods
extension GroupsList {

	/// Get list of groups.
	///
	/// Example:
	/// ```swift
	/// let query = GroupsListQuery()
	///     .limit(5)
	///     .ordering(.datetimeCreatedDESC)
	///
	/// let groupsList = uploadcare.listOfGroups()
	/// try await groupsList.get(withQuery: query)
	/// print(groupsList.results)
	/// ```
	///
	/// - Parameter query: Query object.
	/// - Returns: List of files.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func get(withQuery query: GroupsListQuery? = nil) async throws -> GroupsList {
		guard let api = RESTAPI else {
			throw RESTAPIError.defaultError()
		}

		let list = try await api.listOfGroups(withQuery: query)
		self.next = list.next
		self.previous = list.previous
		self.total = list.total
		self.perPage = list.perPage
		self.results = list.results
		return list
	}

	/// Get next page of groups list
	///
	/// Example:
	/// ```swift
	/// let query = GroupsListQuery()
	///     .limit(5)
	///     .ordering(.datetimeCreatedDESC)
	///
	/// // get first page:
	/// let groupsList = uploadcare.listOfGroups()
	/// try await groupsList.get(withQuery: query)
	///
	/// // get next page:
	/// if groupsList.next != nil {
	///     try await groupsList.nextPage()
	///     print(groupsList.results)
	/// }
	/// ```
	///
	/// - Returns: Groups list.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func nextPage() async throws -> GroupsList {
		guard let next = next, let query = URL(string: next)?.query else {
			self.results = []
			return self
		}

		return try await getPage(withQueryString: query)
	}

	/// Get previous page of groups list.
	///
	/// Example:
	/// ```swift
	/// let query = GroupsListQuery()
	///     .limit(5)
	///     .ordering(.datetimeCreatedDESC)
	///
	/// // get first page:
	/// let groupsList = uploadcare.listOfGroups()
	/// try await groupsList.get(withQuery: query)
	///
	/// // get previous page:
	/// if groupsList.previous != nil {
	///     try await groupsList.previousPage()
	///     print(groupsList.results)
	/// }
	/// ```
	/// - Returns: Groups list.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func previousPage() async throws -> GroupsList {
		guard let previous = previous, let query = URL(string: previous)?.query else {
			self.results = []
			return self
		}

		return try await getPage(withQueryString: query)
	}

	/// Get page of groups list
	/// - Parameter query: Query string.
	/// - Returns: Groups list.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	private func getPage(withQueryString query: String) async throws -> GroupsList {
		guard let api = RESTAPI else {
			throw RESTAPIError.defaultError()
		}

		let groupsList = try await api.listOfGroups(withQueryString: query)
		self.next = groupsList.next
		self.previous = groupsList.previous
		self.total = groupsList.total
		self.perPage = groupsList.perPage
		self.results = groupsList.results
		return groupsList
	}
}

// MARK: - Public methods with Result callback
#if !os(Linux)
extension GroupsList {

	/// Get list of files.
	///
	/// Example:
	/// ```swift
	/// let query = GroupsListQuery()
	///    .limit(5)
	///	   .ordering(.datetimeCreatedDESC)
	///
	///	let groupsList = uploadcare.listOfGroups()
	///	groupsList.get(withQuery: query) { result in
	///     switch result {
	///	    case .failure(let error):
	///	        print(error.detail)
	///	    case .success(let list):
	///	        print(list)
	///	    }
	///	}
	/// ```
	///
	/// - Parameters:
	///   - query: Query object.
	///   - completionHandler: Completion hanlder.
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

	/// Get next page of groups list.
	///
	/// Example:
	/// ```swift
	/// let query = GroupsListQuery()
	///    .limit(5)
	///	   .ordering(.datetimeCreatedDESC)
	///
	///	let groupsList = uploadcare.listOfGroups()
	///	groupsList.get(withQuery: query) { result in
	///     switch result {
	///	    case .failure(let error):
	///	        print(error.detail)
	///	    case .success(let list):
	///	        // get next page:
	///	        guard groupsList.next != nil else { return }
	///	        groupsList.nextPage { result in
	///	            switch result {
	///             case .failure(let error):
	///                 print(error.detail)
	///             case .success(let list):
	///                 print(list)
	///	            }
	///	        }
	///	    }
	///	}
	/// ```
	///
	/// - Parameter completionHandler: Completion handler.
	public func nextPage(_ completionHandler: @escaping (Result<GroupsList, RESTAPIError>) -> Void) {
		guard let next = next, let query = URL(string: next)?.query else {
			self.results = []
			completionHandler(.success(self))
			return
		}

		getPage(withQueryString: query, completionHandler)
	}

	/// Get previous page of groups list.
	///
	/// Example:
	/// ```swift
	/// let query = GroupsListQuery()
	///    .limit(5)
	///	   .ordering(.datetimeCreatedDESC)
	///
	///	let groupsList = uploadcare.listOfGroups()
	///	groupsList.get(withQuery: query) { result in
	///     switch result {
	///	    case .failure(let error):
	///	        print(error.detail)
	///	    case .success(let list):
	///	        // get previous page:
	///	        guard groupsList.previous != nil else { return }
	///	        groupsList.previousPage { result in
	///	            switch result {
	///             case .failure(let error):
	///                 print(error.detail)
	///             case .success(let list):
	///                 print(list)
	///	            }
	///	        }
	///	    }
	///	}
	/// ```
	///
	/// - Parameter completionHandler: completion handler
	public func previousPage(_ completionHandler: @escaping (Result<GroupsList, RESTAPIError>) -> Void) {
		guard let previous = previous, let query = URL(string: previous)?.query else {
			self.results = []
			completionHandler(.success(self))
			return
		}

		getPage(withQueryString: query, completionHandler)
	}

	/// Get page of groups list.
	/// - Parameters:
	///   - query: Query string.
	///   - completionHandler: Completion handler.
	private func getPage(
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
#endif
