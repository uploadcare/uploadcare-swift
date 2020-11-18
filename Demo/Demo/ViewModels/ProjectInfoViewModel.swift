//
//  ProjectInfoViewModel.swift
//  Demo
//
//  Created by Sergey Armodin on 18.11.2020.
//  Copyright © 2020 Sergei Armodin. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import Uploadcare

class ProjectInfoViewModel: ObservableObject {
	// MARK: - Public properties
	var publicKey: String { projectData?.pubKey ?? "" }
	var collaborators: [Collaborator] { projectData?.collaborators ?? [] }
	var name: String { projectData?.name ?? "Loading" }
	
	// MARK: - Private properties
	private var uploadcare: Uploadcare?
	@Published private var projectData: Project?
	
	// MARK: - Init
	init(projectData: Project? = nil, uploadcare: Uploadcare? = nil) {
		self.projectData = projectData
		self.uploadcare = uploadcare
	}
}

extension ProjectInfoViewModel {
	func loadData(onComplete: @escaping ()->Void) {
		guard let api = uploadcare else {
			onComplete()
			return
		}
		
		api.getProjectInfo({ (project, error) in
			if let error = error {
				return DLog(error)
			}
			self.projectData = project
			onComplete()
		})
	}
}
