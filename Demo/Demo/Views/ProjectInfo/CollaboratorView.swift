//
//  CollaboratorView.swift
//  Demo
//
//  Created by Sergey Armodin on 26.03.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import SwiftUI

struct CollaboratorView: View {
    let viewData: CollaboratorViewData
	
	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(viewData.name)
				.font(.headline)
			Text(viewData.email)
				.font(.subheadline)
		}
    }
}

#Preview {
	CollaboratorView(viewData: CollaboratorViewData(name: "user 1", email: "user1@example.com"))
}
