//
//  SelectedFile.swift
//  
//
//  Created by Sergey Armodin on 01.04.2021.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation

// Model that comes in response for /done request
struct SelectedFile: Codable {
	var url: String?
	var is_image: Bool?
	var obj_type: String?
}
