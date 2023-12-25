//
//  ProjectInfo.swift
//  Demo
//
//  Created by Sergey Armodin on 26.03.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import SwiftUI

struct ProjectInfoView: View {
	// MARK: - Public properties
	@ObservedObject var store: ProjectInfoStore
	
	// MARK: - Private properties
	@State private var isLoading: Bool = true
    
	var body: some View {
		ZStack {
			List() {
				Section(header: Text("Keys")) {
					HStack {
						Text("Public key: ")
							.bold()
						Text(store.publicKey)
					}
				}
				if store.collaborators.isEmpty == false {
					Section(header: Text("Collaborators")) {
						ForEach(store.collaborators) { collaborator in
							CollaboratorView(viewData: collaborator)
						}
					}
				}
			}
			.opacity(self.isLoading ? 0 : 1)
				
			VStack(spacing: 16) {
				ProgressView()
					.progressViewStyle(.circular)
					.scaleEffect(CGSize(width: 1.8, height: 1.8))
				Text("Loading...")
			}
			.opacity(self.isLoading ? 1 : 0)

			.navigationBarTitle(Text(store.name))
		}.onAppear {
			Task {
				try await store.loadData()
				withAnimation { isLoading.toggle() }
			}
		}
	}
}

#Preview {
	NavigationView {
		ProjectInfoView(
			store: ProjectInfoStore(
				projectData: ProjectInfoStore.testProject
			)
		)
	}
}
