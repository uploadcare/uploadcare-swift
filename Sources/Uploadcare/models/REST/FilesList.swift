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
	
	/// URL for next page request.
	public var next: String?
	
	/// URL for previous page request.
	public var previous: String?
	
	/// Total number of files.
	public var total: Int
	
	/// Number of files per page.
	public var perPage: Int
	
	/// List of files from the current page.
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
	///
	/// Example:
	/// ```swift
	/// let query = PaginationQuery()
	///     .stored(true)
	///     .ordering(.dateTimeUploadedDESC)
	///     .limit(5)
	///
	/// let filesList = uploadcare.listOfFiles()
	/// filesList.get(withQuery: query) { result in
	///	    switch result {
	///	    case .failure(let error):
	///         print(error.detail)
	///	    case .success(let list):
	///	        print(list)
	///	    }
	/// }
	/// ```
	///
	/// - Parameters:
	///   - query: Query object.
	///   - completionHandler: Completion handler.
	#if !os(Linux)
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
	#endif

	/// Get list of files.
	///
	/// Example:
	/// ```swift
	/// let query = PaginationQuery()
	///	    .stored(true)
	///	    .ordering(.dateTimeUploadedDESC)
	///	    .limit(5)
	///
	/// let filesList = uploadcare.listOfFiles()
	/// let list = try await filesList.get(withQuery: query)
	/// ```
	///
	/// - Parameter query: Query object.
	/// - Returns: List of files.
	@discardableResult
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
	///
	/// Example:
	/// ```swift
	/// let query = PaginationQuery()
	///	    .stored(true)
	///	    .ordering(.dateTimeUploadedDESC)
	///	    .limit(5)
	///
	/// let filesList = uploadcare.listOfFiles()
	///
	/// filesList.get(withQuery: query) { result in
	///     switch result {
	///     case .failure(let error):
	///	        print(error.detail)
	///	    case .success(let list):
	///         // get next page:
	///         guard list.next != nil else { return }
	///         list.nextPage { result in
	///	            switch result {
	///             case .failure(let error):
	///	                print(error.detail)
	///	            case .success(let list):
	///	                print(list)
	///	            }
	///         }
	///	    }
	///	}
	/// ```
	///
	/// - Parameter completionHandler: Completion handler.
	#if !os(Linux)
	public func nextPage(_ completionHandler: @escaping (Result<FilesList, RESTAPIError>) -> Void) {
		guard let next = next, let query = URL(string: next)?.query else {
			self.results = []
			completionHandler(.success(self))
			return
		}
		
		getPage(withQueryString: query, completionHandler)
	}
	#endif

	/// Get next page of files list.
	///
	/// Example:
	/// ```swift
	/// let query = PaginationQuery()
	///	    .stored(true)
	///	    .ordering(.dateTimeUploadedDESC)
	///	    .limit(5)
	///
	/// let filesList = uploadcare.listOfFiles()
	/// if filesList.next != nil {
	///     try await filesList.nextPage()
	/// }
	/// print(filesList.results)
	/// ```
	///
	/// - Returns: Files list.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	@discardableResult
	public func nextPage() async throws -> FilesList {
		guard let next = next, let query = URL(string: next)?.query else {
			self.results = []
			return self
		}

		return try await getPage(withQueryString: query)
	}
	
	/// Get previous page of files list.
	///
	/// Example:
	/// ```swift
	/// let query = PaginationQuery()
	///	    .stored(true)
	///	    .ordering(.dateTimeUploadedDESC)
	///	    .limit(5)
	///
	/// let filesList = uploadcare.listOfFiles()
	///
	/// filesList.get(withQuery: query) { result in
	///     switch result {
	///     case .failure(let error):
	///	        print(error.detail)
	///	    case .success(let list):
	///         // get previous page:
	///         guard list.previous != nil else { return }
	///         list.previousPage { result in
	///	            switch result {
	///             case .failure(let error):
	///	                print(error.detail)
	///	            case .success(let list):
	///	                print(list)
	///	            }
	///         }
	///	    }
	///	}
	/// ```
	/// - Parameter completionHandler: Completion handler.
	#if !os(Linux)
	public func previousPage(_ completionHandler: @escaping (Result<FilesList, RESTAPIError>) -> Void) {
		guard let previous = previous, let query = URL(string: previous)?.query else {
			self.results = []
			completionHandler(.success(self))
			return
		}
		
		getPage(withQueryString: query, completionHandler)
	}
	#endif

	/// Get previous page of files list.
	///
	/// Example:
	/// ```swift
	/// let query = PaginationQuery()
	///	    .stored(true)
	///	    .ordering(.dateTimeUploadedDESC)
	///	    .limit(5)
	///
	/// let filesList = uploadcare.listOfFiles()
	/// if filesList.previous != nil {
	///     try await filesList.previousPage()
	/// }
	/// print(filesList.results)
	/// ```
	///
	/// - Returns: Files list.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	@discardableResult
	public func previousPage() async throws -> FilesList {
		guard let previous = previous, let query = URL(string: previous)?.query else {
			self.results = []
			return self
		}

		return try await getPage(withQueryString: query)
	}
}


// MARK: - Private methods
private extension FilesList {
	/// Get page of files list.
	/// - Parameters:
	///   - query: Query string.
	///   - completionHandler: completion handler
	#if !os(Linux)
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
	#endif


	/// Get page of files list.
	/// - Parameter query: Query string.
	/// - Returns: List of files.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	func getPage(withQueryString query: String) async throws -> FilesList {
		guard let api = RESTAPI else {
			throw RESTAPIError.defaultError()
		}

		let list: FilesList = try await api.listOfFiles(withQueryString: query)
		self.next = list.next
		self.previous = list.previous
		self.total = list.total
		self.perPage = list.perPage
		self.results = list.results
		return list
	}
}
