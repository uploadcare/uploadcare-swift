//
//  CollaboratorViewData.swift
//  Demo
//
//  Created by Sergey Armodin on 18.11.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation

struct CollaboratorViewData: Identifiable, Hashable {
	// MARK: - Public properties
	let id = UUID()
	var name: String
	var email: String
}
