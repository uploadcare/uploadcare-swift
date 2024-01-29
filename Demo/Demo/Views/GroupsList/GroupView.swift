//
//  GroupView.swift
//  Demo
//
//  Created by Sergey Armodin on 26.06.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import SwiftUI
import Uploadcare

struct GroupView: View {
	var viewData: GroupViewData
	@ObservedObject var api: APIStore

    var body: some View {
		List {
			NavigationLink(destination: GroupFileList(viewData: viewData, api: api)) {
				VStack(alignment: .leading) {
					Text("Files:").bold()
					Text("\(viewData.group.filesCount)")
				}
			}
			
			VStack(alignment: .leading) {
				Text("ID:").bold()
				Text("\(viewData.group.id)")
			}
			
			VStack(alignment: .leading) {
				Text("Created:").bold()
				Text("\(viewData.group.datetimeCreated)")
			}
			
			VStack(alignment: .leading) {
				Text("CDN URL:").bold()
				Text("\(viewData.group.cdnUrl)")
			}
			
			VStack(alignment: .leading) {
				Text("URL:").bold()
				Text("\(viewData.group.url)")
			}
		}
		.navigationBarTitle("Group info")
    }
}

#Preview {
	NavigationView {
		GroupView(viewData: testGroupViewData, api: APIStore())
	}
}
