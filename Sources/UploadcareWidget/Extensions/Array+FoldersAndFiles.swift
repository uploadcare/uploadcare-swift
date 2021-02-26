//
//  Array+FoldersAndFiles.swift
//  
//
//  Created by Sergey Armodin on 26.02.2021.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation

extension Array where Element == ChunkThing {
	var hasFolders: Bool {
		self.filter({ $0.action?.action == .open_path }).count > 0
	}

	var hasFiles: Bool {
		self.filter({ $0.action?.action == .select_file }).count > 0
	}
}
