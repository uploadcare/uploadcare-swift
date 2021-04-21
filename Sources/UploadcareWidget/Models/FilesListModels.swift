//
//  FilesListModels.swift
//  
//
//  Created by Sergey Armodin on 21.04.2021.
//  Copyright © 2021 Uploadcare, Inc. All rights reserved.
//

import Foundation

struct Path: Codable {
	let chunks: [Chunk]
	let obj_type: String?
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

enum ThingAction: String, Codable {
	case select_file
	case open_path
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
