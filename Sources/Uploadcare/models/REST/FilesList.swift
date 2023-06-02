//
//  FilesList.swift
//  
//
//  Created by Sergey Armodin on 03.02.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation


public class FilesList: Codable {
	
	// MARK: - Public properties
	
	/// URL for next page request
	public var next: String?
	
	/// URL for previous page request
	public var previous: String?
	
	/// Total number of files
	public var total: Int
	
	/// Number of files per page
	public var perPage: Int
	
	/// List of files from current page
	public var results: [File]
	
	
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
		results: [File]
	) {
		self.next = next
		self.previous = previous
		self.total = total
		self.perPage = perPage
		self.results = results
	}
	
	public init(withFiles files: [File], api: Uploadcare) {
		self.next = nil
		self.previous = nil
		self.total = files.count
		self.perPage = files.count
		self.results = files
		self.RESTAPI = api
	}

	required public convenience init(from decoder: Decoder) throws {
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


extension FilesList: CustomDebugStringConvertible {
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
extension FilesList {
	/// Get list of files.
	/// - Parameters:
	///   - query: Query object.
	///   - completionHandler: completion hanlder
	public func get(
		withQuery query: PaginationQuery? = nil,
		_ completionHandler: @escaping (Result<FilesList, RESTAPIError>) -> Void
	) {
		guard let api = RESTAPI else {
			completionHandler(.failure(RESTAPIError.defaultError()))
			return
		}
		
		api.listOfFiles(withQuery: query) { [weak self] result in
			guard let self = self else { return }

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


	/// Get list of files.
	/// - Parameter query: Query object.
	/// - Returns: List of files.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func get(withQuery query: PaginationQuery? = nil) async throws -> FilesList {
		guard let api = RESTAPI else {
			throw RESTAPIError.defaultError()
		}

		let list: FilesList = try await api.listOfFiles(withQuery: query)
		self.next = list.next
		self.previous = list.previous
		self.total = list.total
		self.perPage = list.perPage
		self.results = list.results
		return list
	}
	
	/// Get next page of files list
	/// - Parameter completionHandler: completion handler
	public func nextPage(_ completionHandler: @escaping (Result<FilesList, RESTAPIError>) -> Void) {
		guard let next = next, let query = URL(string: next)?.query else {
			self.results = []
			completionHandler(.success(self))
			return
		}
		
		getPage(withQueryString: query, completionHandler)
	}
	
	/// Get previous page of files list
	/// - Parameter completionHandler: completion handler
	public func previousPage(_ completionHandler: @escaping (Result<FilesList, RESTAPIError>) -> Void) {
		guard let previous = previous, let query = URL(string: previous)?.query else {
			self.results = []
			completionHandler(.success(self))
			return
		}
		
		getPage(withQueryString: query, completionHandler)
	}
}


// MARK: - Private methods
private extension FilesList {
	/// Get page of files list
	/// - Parameters:
	///   - query: query string
	///   - completionHandler: completion handler
	func getPage(
		withQueryString query: String,
		_ completionHandler: @escaping (Result<FilesList, RESTAPIError>) -> Void
	) {
		guard let api = RESTAPI else {
			completionHandler(.failure(RESTAPIError.defaultError()))
			return
		}
		
		api.listOfFiles(withQueryString: query) { [weak self] result in
			guard let self = self else { return }

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
}

// MARK: - Deprecated methods
extension FilesList {
	/// Get list of files
	/// - Parameters:
	///   - query: query object
	///   - completionHandler: completion hanlder
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func get(
		withQuery query: PaginationQuery? = nil,
		_ completionHandler: @escaping (FilesList?, RESTAPIError?) -> Void
	) {
		guard let api = RESTAPI else {
			completionHandler(nil, RESTAPIError.defaultError())
			return
		}

		api.listOfFiles(withQuery: query) { [weak self] result in
			guard let self = self else { return }

			switch result {
			case .failure(let error):
				completionHandler(nil, error)
			case .success(let list):
				self.next = list.next
				self.previous = list.previous
				self.total = list.total
				self.perPage = list.perPage
				self.results = list.results
				completionHandler(list, nil)
			}
		}
	}

	/// Get next page of files list
	/// - Parameter completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func nextPage(_ completionHandler: @escaping (FilesList?, RESTAPIError?) -> Void) {
		guard let next = next, let query = URL(string: next)?.query else {
			self.results = []
			completionHandler(self, nil)
			return
		}

		getPage(withQueryString: query) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let list): completionHandler(list, nil)
			}
		}
	}

	/// Get previous page of files list
	/// - Parameter completionHandler: completion handler
	@available(*, deprecated, message: "Use the same method with Result type in the callback")
	public func previousPage(_ completionHandler: @escaping (FilesList?, RESTAPIError?) -> Void) {
		guard let previous = previous, let query = URL(string: previous)?.query else {
			self.results = []
			completionHandler(self, nil)
			return
		}

		getPage(withQueryString: query) { result in
			switch result {
			case .failure(let error): completionHandler(nil, error)
			case .success(let list): completionHandler(list, nil)
			}
		}
	}
}
