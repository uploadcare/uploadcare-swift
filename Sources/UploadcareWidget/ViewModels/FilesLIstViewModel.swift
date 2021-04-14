//
//  FilesLIstViewModel.swift
//  
//
//  Created by Sergei Armodin on 26.01.2021.
//

import Foundation
import SwiftUI
import Combine
import WebKit
import Uploadcare

/// Debug log function with printing filename, method and line number
///
/// - Parameters:
///   - messages: arguments
///   - fullPath: filepath
///   - line: line number
///   - functionName: function/method name
func DLog(_ messages: Any..., fullPath: String = #file, line: Int = #line, functionName: String = #function) {
	#if DEBUG
	let file = URL(fileURLWithPath: fullPath)
	for message in messages {
		let string = "\(file.pathComponents.last!):\(line) -> \(functionName): \(message)"
		print(string)
	}
	#endif
}

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
	var api: APIStore

	// MARK: - Private properties
	private var cookie: String
	
	// MARK: - Init
	init(source: SocialSource, cookie: String, chunkPath: String, api: APIStore) {
		self.source = source
		self.cookie = cookie
		self.chunkPath = chunkPath
		self.api = api
	}
}

enum ThingAction: String, Codable {
	case select_file
	case open_path
}

struct Chunk: Codable {
	let path_chunk: String
	let title: String
	let obj_type: String

	enum CodingKeys: String, CodingKey {
		case path_chunk
		case title
		case obj_type
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		// Int might come for VK
		if let intVal = try? container.decodeIfPresent(Int.self, forKey: .path_chunk) {
			path_chunk = "\(intVal)"
		} else {
			path_chunk = try container.decodeIfPresent(String.self, forKey: .path_chunk) ?? ""
		}
		title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
		obj_type = try container.decodeIfPresent(String.self, forKey: .obj_type) ?? ""
	}
}

struct Path: Codable {
	let chunks: [Chunk]
	let obj_type: String?
}

struct Action: Codable {
	let action: ThingAction
	let path: Path?
	let url: String?
	let obj_type: String
}

struct ChunkThing: Codable, Identifiable {
	let id = UUID()

	var action: Action?
	var thumbnail: String
	var obj_type: String
	var title: String
	var mimetype: String?

	enum CodingKeys: String, CodingKey {
		case action
		case thumbnail
		case obj_type
		case title
		case mimetype
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		action = try container.decodeIfPresent(Action.self, forKey: .action)
		thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail) ?? ""
		obj_type = try container.decodeIfPresent(String.self, forKey: .obj_type) ?? ""
		title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
		mimetype = try container.decodeIfPresent(String.self, forKey: .mimetype)
	}
}

struct ChunkResponse: Codable {
	var next_page: Path?
	var things: [ChunkThing]
}

// MARK: - Public methods
@available(iOS 13.0.0, OSX 10.15.0, *)
extension FilesLIstViewModel {
	func modelWithChunkPath(_ chunk: String) -> FilesLIstViewModel {
		return FilesLIstViewModel(source: source, cookie: cookie, chunkPath: self.chunkPath + "/" + chunk, api: api)
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
					  let fileUrlString = file.url,
					  let publicKey = self.api.uploadcare?.publicKey else { return }

				// Calling upload from URL
				var urlComponents = URLComponents()
				urlComponents.scheme = "https"
				urlComponents.host = "upload.uploadcare.com"
				urlComponents.path = "/from_url/"

				urlComponents.queryItems = [
					URLQueryItem(name: "pub_key", value: publicKey),
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
					case .success(let _):
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
				var errorMessage = ""
//				if let responseData = data, let errorResponse = try? JSONDecoder().decode(FilesListViewModelError.self, from: responseData) {
//					errorMessage = errorResponse.message
//				}
				var error = FilesListViewModelError.wrongStatus(status: response.statusCode, message: errorMessage)

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
