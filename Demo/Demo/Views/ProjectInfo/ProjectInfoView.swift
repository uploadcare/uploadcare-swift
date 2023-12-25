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
						ForEach(viewModel.collaborators) { collaborator in
							CollaboratorView(viewData: collaborator)
						}
					}
				}
			}
			.opacity(self.isLoading ? 0 : 1)
				
			VStack {
				ActivityIndicator(isAnimating: .constant(true), style: .large)
				Text("Loading...")
			}
			.opacity(self.isLoading ? 1 : 0)

			.navigationBarTitle(Text(viewModel.name))
		}.onAppear {
			Task {
				try await viewModel.loadData()
				withAnimation { isLoading.toggle() }
			}
		}
	}
}

struct ProjectInfo_Previews: PreviewProvider {
	static var previews: some View {
		#if DEBUG
		NavigationView {
			ProjectInfoView(
				viewModel: ProjectInfoViewModel(
					projectData: ProjectInfoViewModel.testProject
				)
			)
		}
		.previewDevice(PreviewDevice(rawValue: "iPhone X"))
		#endif
    }
}
