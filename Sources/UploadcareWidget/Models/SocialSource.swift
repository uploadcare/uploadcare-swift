//
//  SocialSource.swift
//  Demo
//
//  Created by Sergey Armodin on 25.01.2021.
//  Copyright © 2021 Uploadcare, Inc. All rights reserved.
//
#if os(iOS)
import Foundation

public class SocialSource: Identifiable {
	public enum Source: String, CaseIterable {
		case facebook
		case instagram
		case vk
		case dropbox
		case gdrive
		case gphotos
		case evernote
		case box
		case onedrive
		case flickr
		case huddle
	}
	
	public var id = UUID()
	public let source: Source
	
	var title: String {
		switch self.source {
		case .facebook:
			return "Facebook"
		case .instagram:
			return "Instagram"
		case .vk:
			return "VK"
		case .dropbox:
			return "Dropbox"
		case .gdrive:
			return "Google Drive"
		case .gphotos:
			return "Google Photos"
		case .evernote:
			return "Evernote"
		case .box:
			return "Box"
		case .onedrive:
			return "OneDrive"
		case .flickr:
			return "Flickr"
		case .huddle:
			return "Huddle"
		}
	}

	struct Chunk: Identifiable, Hashable {
		let id = UUID()
		let key: String
		let value: String
	}

	var chunks: [Chunk] {
		switch source {
		case .facebook:
			return [
				Chunk(key: "My Albums", value: "me")
			]
		case .instagram:
			return [
				Chunk(key: "My Photos", value: "my")
			]
		case .vk:
			return [
				Chunk(key: "My Albums", value: "my"),
				Chunk(key: "Profile Pictures", value: "page"),
				Chunk(key: "Photos with Me", value: "with_me"),
				Chunk(key: "Saved Photos", value: "saved"),
				Chunk(key: "My Friends", value: "friends"),
				Chunk(key: "My Documents", value: "docs")
			]
		case .dropbox:
			return [
				Chunk(key: "Files", value: "root"),
				Chunk(key: "Team files", value: "team")
			]
		case .gdrive:
			return [
				Chunk(key: "My Files", value: "root"),
				Chunk(key: "Shared with Me", value: "shared"),
				Chunk(key: "Starred", value: "starred"),
				Chunk(key: "Team drives", value: "team_drives")
			]
		case .gphotos:
			return [
				Chunk(key: "Photos", value: "root"),
				Chunk(key: "Albums", value: "albums")
			]
		case .evernote:
			return [
				Chunk(key: "All Notes", value: "all_notes"),
				Chunk(key: "Notebooks", value: "notebooks"),
				Chunk(key: "Tags", value: "tags")
			]
		case .box:
			return [
				Chunk(key: "My Files", value: "root")
			]
		case .onedrive:
			return [
				Chunk(key: "My drives", value: "root_v2"),
				Chunk(key: "Shared with me", value: "shared_v2"),
				Chunk(key: "SharePoint", value: "sharepoint"),
				Chunk(key: "My groups", value: "groups")
			]
		case .flickr:
			return [
				Chunk(key: "Photo Stream", value: "photostream"),
				Chunk(key: "Albums", value: "albums"),
				Chunk(key: "Favorites", value: "favorites"),
				Chunk(key: "Follows", value: "follows")
			]
		case .huddle:
			return [
				Chunk(key: "My Files", value: "root")
			]
		}
	}
	
	var cookiePath: String {
		return "/\(source.rawValue)/"
	}
	
	var url: URL {
		return URL(string: Config.baseUrl + "/window3/" + source.rawValue)!
	}
	
	public init(id: UUID = UUID(), source: SocialSource.Source) {
		self.id = id
		self.source = source
	}
}

public extension SocialSource {
	func saveCookie(_ value: HTTPCookie) {
		UserDefaults.standard.setValue(value.value, forKey: "cookie_\(source.rawValue)")
	}
	func getCookie() -> String? {
		return UserDefaults.standard.value(forKey: "cookie_\(source.rawValue)") as? String
	}
	func deleteCookie() {
		UserDefaults.standard.removeObject(forKey: "cookie_\(source.rawValue)")
	}
}
#endif
