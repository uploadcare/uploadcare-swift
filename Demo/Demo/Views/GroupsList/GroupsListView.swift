//
//  GroupsListView.swift
//  Demo
//
//  Created by Sergey Armodin on 24.06.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import SwiftUI
import Uploadcare

struct GroupsListView: View {
	@ObservedObject var store: GroupsStore
	@ObservedObject var api: APIStore

    var body: some View {
		Section {
			List(store.groups) { group in
				GroupRowView(groupData: group, api: api)
					.onAppear {
						if group.group.id == store.groups.last?.group.id {
							Task { try await store.loadMoreIfNeed() }
						}
					}
			}
		}
		.onAppear {
			Task {
				try await store.loadData()
			}
        }
		.navigationBarTitle(
			Text("List of groups")
		)
	}
}
