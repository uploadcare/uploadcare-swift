//
//  ProjectInfoViewModel.swift
//  Demo
//
//  Created by Sergey Armodin on 18.11.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import SwiftUI
import Uploadcare

final class ProjectInfoStore: ObservableObject {
	#if DEBUG
	static let testProject = Project(
		name: "Test project",
		pubKey: "demopublickey",
		collaborators: [
			Collaborator(email: "user1@gmail.com", name: "User 1"),
			Collaborator(email: "user2@gmail.com", name: "User 2")
		]
	)
	#endif
	
	// MARK: - Public properties
	var publicKey: String { projectData?.pubKey ?? "..." }
	var collaborators: [CollaboratorViewData] {
		projectData?.collaborators?.compactMap { CollaboratorViewData(name: $0.name, email: $0.email) } ?? []
	}
	var name: String { projectData?.name ?? "Loading..." }

	// MARK: - Private properties
	private var uploadcare: Uploadcare?
	private var projectData: Project?
	
	// MARK: - Init
	init(projectData: Project? = nil, uploadcare: Uploadcare? = nil) {
		self.projectData = projectData
		self.uploadcare = uploadcare
	}
}

// MARK: - Public methods
extension ProjectInfoStore {
	func loadData() async throws {
		guard let api = uploadcare else { return }
		let project = try await api.getProjectInfo()

		await MainActor.run { [weak self] in
			self?.projectData = project
		}
	}
}
