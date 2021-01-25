//
//  SocialSource.swift
//  Demo
//
//  Created by Sergey Armodin on 25.01.2021.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation

public class SocialSource: Identifiable {
	public enum Source: String, CaseIterable {
		case facebook
		case instagram
		case vk
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
}
