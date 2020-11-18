//
//  ProjectInfo.swift
//  Demo
//
//  Created by Sergey Armodin on 26.03.2020.
//  Copyright © 2020 Sergei Armodin. All rights reserved.
//

import SwiftUI
import Uploadcare

struct ProjectInfoView: View {
	// MARK: - Public properties
	@ObservedObject var viewModel: ProjectInfoViewModel
	
	// MARK: - Private properties
	@State private var isLoading: Bool = true
    
	var body: some View {
		ZStack {
			List() {
				Section(header: Text("Keys")) {
					HStack {
						Text("Public key: ")
							.bold()
						Text(viewModel.publicKey)
					}
				}
				if viewModel.collaborators.isEmpty == false {
					Section(header: Text("Collaborators")) {
						ForEach(0 ..< (viewModel.collaborators).count) { [self] index in
							CollaboratorView(collaborator: viewModel.collaborators[index])
						}
					}
				}
			}
			.opacity(self.isLoading ? 0 : 1)
				
			VStack {
				ActivityIndicator(isAnimating: .constant(true), style: .large)
				Text("Loading...")
			}.opacity(self.isLoading ? 1 : 0)

			.navigationBarTitle(Text(viewModel.name))
		}.onAppear { [self] in
			viewModel.loadData {
				withAnimation { self.isLoading.toggle() }
			}
			
		}
	}
}

struct ProjectInfo_Previews: PreviewProvider {
	static var previews: some View {
		NavigationView {
			ProjectInfoView(
				viewModel: ProjectInfoViewModel(projectData: testProject)
			)
		}.previewDevice(PreviewDevice(rawValue: "iPhone X"))
    }
}

#if DEBUG
let testProject = Project(
	name: "Test project",
	pubKey: "demopublickey",
	collaborators: [
		Collaborator(email: "user1@gmail.com", name: "User 1"),
		Collaborator(email: "user2@gmail.com", name: "User 2")
	]
)
#endif
