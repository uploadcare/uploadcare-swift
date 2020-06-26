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
			HStack(alignment: .center) {
				Text("ID:")
				Text("\(viewData.group.id)")
			}.font(.caption)
			
			HStack(alignment: .center) {
				Text("Files:")
				Text("\(viewData.group.filesCount)")
			}.font(.caption)
			
			HStack(alignment: .center) {
				Text("Created:")
				Text("\(viewData.group.datetimeCreated)")
			}.font(.caption)
			
			if viewData.group.datetimeStored != nil {
				HStack(alignment: .center) {
					Text("Stored:")
					Text("\(viewData.group.datetimeStored!)")
				}.font(.caption)
			}
			
			HStack(alignment: .center) {
				Text("CDN URL:")
				Text("\(viewData.group.cdnUrl)")
			}.font(.caption)
			
			HStack(alignment: .center) {
				Text("URL:")
				Text("\(viewData.group.url)")
			}.font(.caption)
		}
        
    }
}

struct GroupView_Previews: PreviewProvider {
    static var previews: some View {
        GroupView(viewData: testGroupViewData)
    }
}
