//
//  SocialSource.swift
//  Demo
//
//  Created by Sergey Armodin on 25.01.2021.
//  Copyright © 2021 Uploadcare, Inc. All rights reserved.
//

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
		case skydrive
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
		case .skydrive:
			return "SkyDrive"
		case .onedrive:
			return "OneDrive"
		case .flickr:
			return "Flickr"
		case .huddle:
			return "Huddle"
		}
	}
	
	var chunks: [[String: String]] {
		switch self.source {
		case .facebook:
			return [
				["My Albums": "me"]
			]
		case .instagram:
			return [
				["My Photos": "my"]
			]
		case .vk:
			return [
				["My Albums": "my"],
				["Profile Pictures": "page"],
				["Photos with Me": "with_me"],
				["Saved Photos": "saved"],
				["My Friends": "friends"],
				["My Documents": "docs"],
			]
		case .dropbox:
			return [
				["Files": "root"],
				["Team files": "team"]
			]
		case .gdrive:
			return [
				["My Files": "root"],
				["Shared with Me": "shared"],
				["Starred": "starred"],
				["Team drives": "team_drives"]
			]
		case .gphotos:
			return [
				["Photos": "root"],
				["Albums": "albums"]
			]
		case .evernote:
			return [
				["All Notes": "all_notes"],
				["Notebooks": "notebooks"],
				["Tags": "tags"]
			]
		case .box:
			return [
				["My Files": "root"]
			]
		case .skydrive:
			return [
				["My Files": "root"]
			]
		case .onedrive:
			return [
				["My drives": "root_v2"],
				["Shared with me": "shared_v2"],
				["SharePoint": "sharepoint"],
				["My groups": "groups"]
			]
		case .flickr:
			return [
				["Photo Stream": "photostream"],
				["Albums": "albums"],
				["Favorites": "favorites"],
				["Follows": "follows"]
			]
		case .huddle:
			return [
				["My Files": "root"]
			]
		}
	}
	
	var cookiePath: String {
		return "/\(source.rawValue)/"
	}
	
	var url: URL {
		return URL(string: Config.baseUrl + "/window3/" + source.rawValue)!
	}
	
	internal init(id: UUID = UUID(), source: SocialSource.Source) {
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
