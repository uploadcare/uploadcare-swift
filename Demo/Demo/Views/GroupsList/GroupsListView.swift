//
//  GroupsListView.swift
//  Demo
//
//  Created by Sergey Armodin on 24.06.2020.
//  Copyright © 2020 Sergei Armodin. All rights reserved.
//

import SwiftUI
import Uploadcare

class GroupsListStore: ObservableObject {
	@Published var groups: [GroupViewData] = []
	private var list: GroupsList?
	var uploadcare: Uploadcare? {
		didSet {
			self.list = uploadcare?.listOfGroups()
		}
	}
	
	init(groups: [GroupViewData]) {
        self.groups = groups
    }
	
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


struct GroupsListView: View {
	@EnvironmentObject var api: APIStore
	@ObservedObject private var groupsListStore: GroupsListStore = GroupsListStore(groups: [])
	
    var body: some View {
		ZStack {
			List {
				Section {
					ForEach(self.groupsListStore.groups) { group in
						GroupRowView(groupData: group)
						.onAppear {
							if group.group.id == self.groupsListStore.groups.last?.group.id {
								self.loadMoreIfNeed()
							}
						}
					}
				}
			}
		}.onAppear {
            self.loadData()
        }
	}
	
	func loadData() {
		groupsListStore.uploadcare = self.api.uploadcare
		groupsListStore.load { (list, error) in
			if let error = error {
				return print(error)
			}
			self.groupsListStore.groups.removeAll()
			list?.results.forEach({ self.groupsListStore.groups.append(GroupViewData(group: $0)) })
		}
	}
	
	func loadMoreIfNeed() {
		groupsListStore.loadNext { (list, error) in
			if let error = error {
				return print(error)
			}
			list?.results.forEach({ self.groupsListStore.groups.append(GroupViewData(group: $0)) })
		}
	}
}

struct GroupsListView_Previews: PreviewProvider {
    static var previews: some View {
        GroupsListView()
    }
}
