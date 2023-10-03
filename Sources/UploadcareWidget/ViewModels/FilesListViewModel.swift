//
//  FilesListViewModel.swift
//  
//
//  Created by Sergei Armodin on 26.01.2021.
//  Copyright © 2021 Uploadcare, Inc. All rights reserved.
//
#if os(iOS)
import Foundation
import SwiftUI
import Combine
import WebKit

@available(iOS 13.0.0, macOS 10.15.0, *)
class FilesListViewModel: ObservableObject {
	enum FilesListViewModelError: Error {
		case noData
		case decodingError
		case requestCancelled
		case wrongStatus(status: Int, message: String)
	}
	
	// MARK: - Public properties
	var source: SocialSource
	@Published var currentChunk: ChunkResponse? {
		didSet {
			self.files = (self.currentChunk?.things ?? []).filter({ $0.obj_type != "album" })
			self.folders = (self.currentChunk?.things ?? []).filter({ $0.obj_type == "album" })
		}
	}
	@Published var files: [ChunkThing] = []
	@Published var folders: [ChunkThing] = []
	var chunkPath: String

	// MARK: - Private properties
	private var cookie: String
	private let publicKey: String
	
	// MARK: - Init
	init(source: SocialSource, cookie: String, chunkPath: String, publicKey: String) {
		self.source = source
		self.cookie = cookie
		self.chunkPath = chunkPath
		self.publicKey = publicKey
	}
}

// MARK: - Public methods
@available(iOS 13.0.0, macOS 10.15.0, *)
extension FilesListViewModel {
	func modelWithChunkPath(_ chunk: String) -> FilesListViewModel {
		return FilesListViewModel(
			source: source,
			cookie: cookie,
			chunkPath: self.chunkPath + "/" + chunk,
			publicKey: publicKey
		)
	}

	func uploadFileFromPath(_ path: String) {
		// Request to /done
		var urlComponents = URLComponents()
		urlComponents.scheme = "https"
		urlComponents.host = Config.cookieDomain
		urlComponents.path = "/\(source.source.rawValue)/done"

		guard let url = urlComponents.url else { return }

		var urlRequest = URLRequest(url: url)

		urlRequest.setValue("auth=\(self.cookie)", forHTTPHeaderField: "Cookie")
		urlRequest.httpMethod = "POST"

		let builder = MultipartRequestBuilder(request: urlRequest)
		builder.addMultiformValue(path, forName: "file")
		builder.addMultiformValue(self.chunkPath, forName: "root")
		builder.addMultiformValue("false", forName: "need_image")
		urlRequest = builder.finalize()

		self.performRequest(urlRequest) { (result) in
			switch result {
			case .failure(let error):
				DLog(error.localizedDescription)
			case .success(let data):
				guard let file = try? JSONDecoder().decode(SelectedFile.self, from: data),
					  let fileUrlString = file.url else { return }

				// Calling upload from URL
				var urlComponents = URLComponents()
				urlComponents.scheme = "https"
				urlComponents.host = "upload.uploadcare.com"
				urlComponents.path = "/from_url/"

				urlComponents.queryItems = [
					URLQueryItem(name: "pub_key", value: self.publicKey),
					URLQueryItem(name: "source_url", value: fileUrlString),
					URLQueryItem(name: "source", value: self.source.source.rawValue),
					URLQueryItem(name: "store", value: "1")
				]

				guard let url = urlComponents.url else { return }

				let urlRequest = URLRequest(url: url)
				self.performRequest(urlRequest) { (result) in
					switch result {
					case .success(let data):
						DLog(data.toString() ?? "")
					case .failure(let error):
						DLog(error)
					}
				}
			}
		}
	}

	func getSourceChunk() async throws {
		await MainActor.run {
			self.currentChunk = nil
		}
		var urlComponents = URLComponents()
		urlComponents.scheme = "https"
		urlComponents.host = Config.cookieDomain
		urlComponents.path = "/\(source.source.rawValue)/source/\(chunkPath)"

		guard let url = urlComponents.url else { return }

		var urlRequest = URLRequest(url: url)
		urlRequest.setValue("auth=\(self.cookie)", forHTTPHeaderField: "Cookie")

		do {
			let data = try await performRequest(urlRequest)
			try await MainActor.run {
				self.currentChunk = try JSONDecoder().decode(ChunkResponse.self, from: data)
			}
		} catch {
			DLog(error)
			throw error
		}
	}

	func loadMore(path: String) async throws {
		var urlComponents = URLComponents()
		urlComponents.scheme = "https"
		urlComponents.host = Config.cookieDomain
		urlComponents.path = "/\(source.source.rawValue)/source/\(chunkPath)/\(path)"

		guard let url = urlComponents.url else { return }

		var urlRequest = URLRequest(url: url)
		urlRequest.setValue("auth=\(self.cookie)", forHTTPHeaderField: "Cookie")

		do {
			let data = try await performRequest(urlRequest)
			let newChunk = try JSONDecoder().decode(ChunkResponse.self, from: data)
			await MainActor.run {
				self.currentChunk?.next_page = newChunk.next_page
				newChunk.things.forEach({ self.currentChunk?.things.append($0) })
			}
		} catch {
			DLog(error)
			throw error
		}
	}
	
	func logout() {
		if let cookie = self.source.getCookie() {
			var urlComponents = URLComponents()
			urlComponents.scheme = "https"
			urlComponents.host = Config.cookieDomain
			urlComponents.path = "/\(self.source.source.rawValue)/session"

			guard let url = urlComponents.url else { return }

			var urlRequest = URLRequest(url: url)
			urlRequest.httpMethod = "DELETE"

			WKWebsiteDataStore.default().httpCookieStore.getAllCookies { (cookies) in
				let storedCookie = cookies
					.filter({ $0.domain == url.host })
					.filter({ $0.path == self.source.cookiePath })

				urlRequest.setValue("auth=\(storedCookie.first?.value ?? cookie)", forHTTPHeaderField: "Cookie")

				self.performRequest(urlRequest) { (result) in
					switch result {
					case .failure(let error):
						DLog(error.localizedDescription)
					case .success(_):
						DLog("logged out")
//						DLog(data.toString() ?? "")
					}

					DispatchQueue.main.async {
						let dataStore = WKWebsiteDataStore.default()
						dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
							DLog(records)
							dataStore.removeData(
								ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
								for: records.filter { $0.displayName.contains("uploadcare.com") },
								completionHandler: {
								}
							)
						}
					}
				}
			}
		}
		self.source.deleteCookie()
	}
}

// MARK: - Private methods
@available(iOS 13.0.0, macOS 10.15.0, *)
private extension FilesListViewModel {
	func performRequest(_ urlRequest: URLRequest) async throws -> Data {
		let (data, response) = try await URLSession.shared.data(for: urlRequest)
		guard let response = response as? HTTPURLResponse else {
			throw FilesListViewModelError.noData
		}

		guard (200...299).contains(response.statusCode) else {
			var error = FilesListViewModelError.wrongStatus(status: response.statusCode, message: data.toString() ?? "")

			if response.statusCode == NSURLErrorCancelled {
				error = FilesListViewModelError.requestCancelled
			}

			DLog("error: \(error)")
			DLog(data.toString() ?? "")
			throw error
		}

		return data
	}

	func performRequest(_ urlRequest: URLRequest, _ completionHandler: @escaping (Result<Data, Error>)->Void) {
		let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
			if let error = error {
				completionHandler(.failure(error))
				return
			}
			
			guard let response = response as? HTTPURLResponse else {
				completionHandler(.failure(FilesListViewModelError.noData))
				return
			}
			
			if (200...299).contains(response.statusCode) {
				guard let data = data else {
					completionHandler(.failure(FilesListViewModelError.decodingError))
					return
				}
				completionHandler(.success(data))
			} else {
				var error = FilesListViewModelError.wrongStatus(status: response.statusCode, message: data?.toString() ?? "")

				if response.statusCode == NSURLErrorCancelled {
					error = FilesListViewModelError.requestCancelled
				}

				DLog("error: \(error)")
				if let data = data {
					DLog(data.toString() ?? "")
				}
				completionHandler(.failure(error))
			}
		}
		
		task.resume()
	}
}

extension Data {
	func toString() -> String? {
		return String(data: self, encoding: .utf8)
	}
}
#endif
