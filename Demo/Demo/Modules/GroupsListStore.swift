//
//  GroupsListStore.swift
//  Demo
//
//  Created by Sergey Armodin on 28.10.2020.
//  Copyright © 2020 Sergei Armodin. All rights reserved.
//

import Foundation
import Combine
import Uploadcare

class GroupsListStore: ObservableObject {
	@Published var groups: [GroupViewData] = []
	private var list: GroupsList?
	var uploadcare: Uploadcare? {
		didSet {
			self.list = uploadcare?.listOfGroups()
		}
	}
	
	// MARK: - Init
	init(groups: [GroupViewData]) {
		self.groups = groups
	}
	
	// MARK: - Public methods
	func load(_ completionHandler: @escaping (GroupsList?, RESTAPIError?) -> Void) {
		let query = GroupsListQuery()
			.limit(5)
			.ordering(.datetimeCreatedDESC)
		
		self.list?.get(withQuery: query, completionHandler)
	}
	
	func loadNext(_ completionHandler: @escaping (GroupsList?, RESTAPIError?) -> Void) {
		self.list?.nextPage(completionHandler)
	}
}
