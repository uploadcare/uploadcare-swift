//
//  GroupsListView.swift
//  Demo
//
//  Created by Sergey Armodin on 24.06.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import SwiftUI

struct GroupsListView: View {
	@ObservedObject var viewModel: GroupsListViewModel
	
    var body: some View {
		Section {
			List(viewModel.groups) { group in
				GroupRowView(groupData: group)
					.onAppear {
						if group.group.id == viewModel.groups.last?.group.id {
							Task { try await viewModel.loadMoreIfNeed() }
						}
					}
			}
		}
		.onAppear {
			Task {
				try await viewModel.loadData()
			}
        }
		.navigationBarTitle(
			Text("List of groups")
		)
	}
}
