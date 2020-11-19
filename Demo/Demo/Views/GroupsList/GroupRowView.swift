//
//  GroupRowView.swift
//  Demo
//
//  Created by Sergey Armodin on 24.06.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import SwiftUI
import Uploadcare

struct GroupRowView: View {
    var groupData: GroupViewData
	
    var body: some View {
		NavigationLink(destination: GroupView(viewData: groupData)) {
			VStack(alignment: .leading) {
				HStack(alignment: .firstTextBaseline) {
					Text("ID:")
						.font(.caption)
					Text(groupData.group.id)
						.font(.caption)
				}
				HStack(alignment: .firstTextBaseline) {
					Text("files:")
						.font(.caption)
					Text("\(groupData.group.filesCount)")
						.font(.caption)
				}
			}
		}
    }
}

struct GroupRowView_Previews: PreviewProvider {
    static var previews: some View {
        GroupRowView(groupData: testGroupViewData)
			.previewLayout(.sizeThatFits)
    }
}

#if DEBUG
let jsonData = """
	{
		"id": "ec207006-882b-4184-8318-5b57ca2135d8~2",
		"datetime_created": "2020-05-05T18:52:14.481914Z",
		"datetime_stored": null,
		"files_count": 2,
		"cdn_url": "https://ucarecdn.com/ec207006-882b-4184-8318-5b57ca2135d8~2/",
		"url": "https://api.uploadcare.com/groups/ec207006-882b-4184-8318-5b57ca2135d8~2/"
	}
""".data(using: .utf8)!
let testGroup = try! JSONDecoder().decode(Group.self, from: jsonData)
let testGroupViewData = GroupViewData(group: testGroup)
#endif
