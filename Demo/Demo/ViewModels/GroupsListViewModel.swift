//
//  GroupsListViewModel.swift
//  Demo
//
//  Created by Sergey Armodin on 28.10.2020.
//  Copyright © 2020 Sergei Armodin. All rights reserved.
//

import Foundation
import Combine
import Uploadcare

class GroupsListViewModel: ObservableObject {
	@Published var groups: [GroupViewData] = []
	private var list: GroupsList?
	var uploadcare: Uploadcare? {
		didSet {
			self.list = uploadcare?.listOfGroups()
		}
	}
	
	// MARK: - Init
	init(groups: [GroupViewData] = [], uploadcare: Uploadcare? = nil) {
		self.groups = groups
		self.uploadcare = uploadcare
	}
	
}

// MARK: - Public methods
extension GroupsListViewModel {
	func loadData() {
		load { [weak self] (list, error) in
			if let error = error {
				return DLog(error)
			}
			self?.groups.removeAll()
			list?.results.forEach { self?.groups.append(GroupViewData(group: $0)) }
		}
	}
	
	func loadMoreIfNeed() {
		loadNext { [weak self] (list, error) in
			if let error = error {
				return DLog(error)
			}
			self?.list?.results.forEach({ self?.groups.append(GroupViewData(group: $0)) })
		}
	}
}

// MARK: - Private methods
private extension GroupsListViewModel {
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
