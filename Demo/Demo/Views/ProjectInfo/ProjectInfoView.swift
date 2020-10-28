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
	@EnvironmentObject var api: APIStore
	@State var projectData: Project?
	@State private var isLoading: Bool = true
    
	var body: some View {
		ZStack {
			List() {
				Section {
					HStack {
						Text("Public key: ")
							.bold()
						Text(projectData?.pubKey ?? "")
					}
				}
				if projectData?.collaborators?.isEmpty == false {
					Section(header: Text("Collaborators")) {
						ForEach(0 ..< (projectData?.collaborators ?? []).count) { index in
							CollaboratorView(collaborator: self.projectData!.collaborators![index])
						}
					}
				}
			}
			.opacity(self.isLoading ? 0 : 1)
				
			VStack {
				ActivityIndicator(isAnimating: .constant(true), style: .large)
				Text("Loading...")
			}.opacity(self.isLoading ? 1 : 0)

			.navigationBarTitle(Text(projectData?.name ?? "Loading"))
		}.onAppear {
			self.api.uploadcare?.getProjectInfo({ (project, error) in
				if let error = error {
					return DLog(error)
				}
				self.projectData = project
			})
			
			withAnimation { self.isLoading.toggle() }
		}
	}
}

struct ProjectInfo_Previews: PreviewProvider {
    static var previews: some View {
		NavigationView {
			ProjectInfoView(
				projectData: testProject
			)
		}.previewDevice(PreviewDevice(rawValue: "iPhone X"))
    }
}


#if DEBUG
let testProject = Project(
	name: "Test project",
	pubKey: "public-key",
	collaborators: [
		Collaborator(email: "user1@gmail.com", name: "User 1"),
		Collaborator(email: "user2@gmail.com", name: "User 2")
	]
)
#endif
