//
//  FilesLIstViewModel.swift
//  
//
//  Created by Sergei Armodin on 26.01.2021.
//

import Foundation
import SwiftUI
import Combine

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
	
	// MARK: - Init
	init(source: SocialSource, cookie: String, chunkPath: String) {
		self.source = source
		self.cookie = cookie
		self.chunkPath = chunkPath
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
	let things: [ChunkThing]
}

// MARK: - Public methods
@available(iOS 13.0.0, OSX 10.15.0, *)
extension FilesLIstViewModel {
	func modelWithChunkPath(_ chunk: String) -> FilesLIstViewModel {
		return FilesLIstViewModel(source: source, cookie: cookie, chunkPath: self.chunkPath + "/" + chunk)
	}

	func getSourceChunk(_ onComplete: @escaping ()->Void) {
		currentChunk = nil
		var urlComponents = URLComponents()
		urlComponents.scheme = "https"
		urlComponents.host = Config.cookieDomain
		urlComponents.path = "/\(source.source.rawValue)/source/\(chunkPath)"
		
		guard let url = urlComponents.url else { return }
		
		var urlRequest = URLRequest(url: url)
		urlRequest.setValue("auth=\(cookie)", forHTTPHeaderField: "Cookie")
		
		performRequest(urlRequest) { (result) in
			switch result {
			case .failure(let error):
				print(error.localizedDescription)
				onComplete()
			case .success(let data):
				DispatchQueue.main.async {
					do {
						self.currentChunk = try JSONDecoder().decode(ChunkResponse.self, from: data)
					} catch let error {
						print(error.localizedDescription)
					}
					onComplete()
				}
			}
		}
	}
	
	func logout() {
		source.deleteCookie()
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

				print("error: \(error)")
				if let data = data {
					print(String(data: data, encoding: .utf8))
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
