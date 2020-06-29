//
//  CollaboratorView.swift
//  Demo
//
//  Created by Sergey Armodin on 26.03.2020.
//  Copyright © 2020 Sergei Armodin. All rights reserved.
//

import SwiftUI
import Uploadcare


struct CollaboratorView: View {
    let collaborator: Collaborator
	
	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(collaborator.name)
				.font(.headline)
			Text(collaborator.email)
				.font(.subheadline)
		}
    }
}

struct CollaboratorView_Previews: PreviewProvider {
    static var previews: some View {
		Group {
			CollaboratorView(
				collaborator: Collaborator(email: "user1@gmail.com", name: "User 1")
			).previewDevice(PreviewDevice(rawValue: "iPhone X"))
		}
    }
}
