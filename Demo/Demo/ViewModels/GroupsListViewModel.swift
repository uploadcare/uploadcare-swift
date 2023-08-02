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
	func loadData() async throws {
		guard let list else { return }
		let query = GroupsListQuery()
			.limit(5)
			.ordering(.datetimeCreatedDESC)

		let newData = try await list.get(withQuery: query)
		DispatchQueue.main.async { [weak self] in
			self?.groups.removeAll()
			newData.results.forEach {
				self?.groups.append(GroupViewData(group: $0))
			}
		}
	}

	func loadMoreIfNeed() async throws {
		guard let list else { return }
		let newData = try await list.nextPage()
		DispatchQueue.main.async { [weak self] in
			newData.results.forEach({ self?.groups.append(GroupViewData(group: $0)) })
		}
	}
}
