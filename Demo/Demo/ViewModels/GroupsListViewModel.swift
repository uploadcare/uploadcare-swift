//
//  GroupsListViewModel.swift
//  Demo
//
//  Created by Sergey Armodin on 28.10.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import Uploadcare

class GroupsListViewModel: ObservableObject {
	// MARK: - Public properties
	@Published var groups: [GroupViewData] = []
	
	// MARK: - Private properties
	private var list: GroupsList?
	private var uploadcare: Uploadcare?
	
	// MARK: - Init
	init(groups: [GroupViewData] = [], uploadcare: Uploadcare? = nil) {
		self.groups = groups
		self.uploadcare = uploadcare
		self.list = uploadcare?.listOfGroups()
	}
}

// MARK: - Public methods
extension GroupsListViewModel {
	func loadData() {
		let query = GroupsListQuery()
			.limit(5)
			.ordering(.datetimeCreatedDESC)
		
		self.list?.get(withQuery: query) { [weak self] result in
			switch result {
			case .failure(let error):
				DLog(error)
			case .success(let list):
				self?.groups.removeAll()
				list.results.forEach { self?.groups.append(GroupViewData(group: $0)) }
			}
		}
	}
	
	func loadMoreIfNeed() {
		self.list?.nextPage { [weak self] result in
			switch result {
			case .failure(let error):
				DLog(error)
			case .success(let list):
				list.results.forEach({ self?.groups.append(GroupViewData(group: $0)) })
			}
		}
	}
}
