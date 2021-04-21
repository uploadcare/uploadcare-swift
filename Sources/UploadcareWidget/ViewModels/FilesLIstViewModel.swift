//
//  FilesLIstViewModel.swift
//  
//
//  Created by Sergei Armodin on 26.01.2021.
//  Copyright © 2021 Uploadcare, Inc. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import WebKit

@available(iOS 13.0.0, OSX 10.15.0, *)
class FilesLIstViewModel: ObservableObject {
	enum FilesListViewModelError: Error {
		case noData
		case decodingError
		case requestCancelled
		case wrongStatus(status: Int, message: String)
	}
	
	// MARK: - Public properties
	var source: SocialSource
	@Published var currentChunk: ChunkResponse?
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
@available(iOS 13.0.0, OSX 10.15.0, *)
extension FilesLIstViewModel {
	func modelWithChunkPath(_ chunk: String) -> FilesLIstViewModel {
		return FilesLIstViewModel(
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

	func getSourceChunk(_ onComplete: @escaping ()->Void) {
		currentChunk = nil
		var urlComponents = URLComponents()
		urlComponents.scheme = "https"
		urlComponents.host = Config.cookieDomain
		urlComponents.path = "/\(source.source.rawValue)/source/\(chunkPath)"
		
		guard let url = urlComponents.url else { return }
		
		var urlRequest = URLRequest(url: url)

		urlRequest.setValue("auth=\(self.cookie)", forHTTPHeaderField: "Cookie")

		self.performRequest(urlRequest) { (result) in
			switch result {
			case .failure(let error):
				DLog(error.localizedDescription)
				onComplete()
			case .success(let data):
				DispatchQueue.main.async {
					do {
						self.currentChunk = try JSONDecoder().decode(ChunkResponse.self, from: data)
					} catch let error {
						DLog(error.localizedDescription)
						DLog(data.toString() ?? "")
					}
					onComplete()
				}
			}
		}
	}

	func loadMore(path: String, _ onComplete: @escaping ()->Void) {
		var urlComponents = URLComponents()
		urlComponents.scheme = "https"
		urlComponents.host = Config.cookieDomain
		urlComponents.path = "/\(source.source.rawValue)/source/\(chunkPath)/\(path)"

		guard let url = urlComponents.url else { return }

		var urlRequest = URLRequest(url: url)

		urlRequest.setValue("auth=\(self.cookie)", forHTTPHeaderField: "Cookie")

		self.performRequest(urlRequest) { (result) in
			switch result {
			case .failure(let error):
				DLog(error.localizedDescription)
				onComplete()
			case .success(let data):
				DispatchQueue.main.async {
					do {
						let newChunk = try JSONDecoder().decode(ChunkResponse.self, from: data)
						self.currentChunk?.next_page = newChunk.next_page
						newChunk.things.forEach({ self.currentChunk?.things.append($0) })
					} catch let error {
						DLog(error.localizedDescription)
						DLog(data.toString() ?? "")
					}
					onComplete()
				}
			}
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
@available(iOS 13.0.0, OSX 10.15.0, *)
private extension FilesLIstViewModel {
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
