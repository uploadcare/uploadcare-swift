//
//  ContentView.swift
//  Demo
//
//  Created by Sergey Armodin on 26.03.2020.
//  Copyright © 2020 Sergei Armodin. All rights reserved.
//

import SwiftUI
import Combine
import Uploadcare


final class APIStore: ObservableObject {
	var uploadcare: Uploadcare?
	
	init(uploadcare: Uploadcare? = nil) {
		self.uploadcare = uploadcare
	}
}


struct MainView: View {
	@EnvironmentObject var api: APIStore
	
    var body: some View {
		NavigationView {
            ZStack {
                List {
                    NavigationLink(destination: ProjectInfoView()) {
                        Text("Project Info")
                    }
                    NavigationLink(destination: FilesListView()) {
                        Text("List of files")
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
