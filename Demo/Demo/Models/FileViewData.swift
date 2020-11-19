//
//  FileViewData.swift
//  Demo
//
//  Created by Sergey Armodin on 29.03.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation
import Uploadcare

struct FileViewData: Identifiable {
	internal init(id: UUID = UUID(), file: File) {
		self.id = id
		self.file = file
	}
	
	var id = UUID()
	var file: File
}



