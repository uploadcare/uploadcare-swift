//
//  ContentView.swift
//  Demo
//
//  Created by Sergey Armodin on 26.03.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import SwiftUI

struct MainView: View {
	@EnvironmentObject var api: APIStore
	@ObservedObject private var filesListStore: FilesListStore = FilesListStore(files: [])
	
    var body: some View {
		NavigationView {
            ZStack {
                List {
					NavigationLink(destination: FilesListView(filesListStore: self.filesListStore)) {
                        Text("List of files")
                    }
					NavigationLink(destination: GroupsListView(viewModel: GroupsListViewModel(uploadcare: api.uploadcare))) {
                        Text("List of file groups")
                    }
					NavigationLink(destination: ProjectInfoView(viewModel: ProjectInfoViewModel(uploadcare: api.uploadcare))) {
                        Text("Project info")
                    }
                }.listStyle(GroupedListStyle())
                .navigationBarTitle(Text("Uploadcare demo"), displayMode: .automatic)
            }
		}
		
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
		MainView()
			.environmentObject(APIStore())
			.previewDevice(PreviewDevice(rawValue: "iPhone X"))
    }
}
