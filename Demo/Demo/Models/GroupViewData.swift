//
//  GroupViewData.swift
//  Demo
//
//  Created by Sergey Armodin on 24.06.2020.
//  Copyright © 2020 Sergei Armodin. All rights reserved.
//

import Foundation
import Uploadcare

struct GroupViewData: Identifiable {
	internal init(id: UUID = UUID(), group: Group) {
		self.id = id
		self.group = group
	}
	
	var id = UUID()
	var group: Group
}
