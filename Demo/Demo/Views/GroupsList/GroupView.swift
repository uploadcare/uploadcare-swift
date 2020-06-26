//
//  GroupView.swift
//  Demo
//
//  Created by Sergey Armodin on 26.06.2020.
//  Copyright © 2020 Sergei Armodin. All rights reserved.
//

import SwiftUI

struct GroupView: View {
	var viewData: GroupViewData
	
    var body: some View {
		List {
			NavigationLink(destination: GroupFileList(viewData: viewData)) {
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
			
			if viewData.group.datetimeStored != nil {
				VStack(alignment: .leading) {
					Text("Stored:").bold()
					Text("\(viewData.group.datetimeStored!)")
				}
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

struct GroupView_Previews: PreviewProvider {
    static var previews: some View {
		NavigationView {
			GroupView(viewData: testGroupViewData)
		}
    }
}
