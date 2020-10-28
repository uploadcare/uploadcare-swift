//
//  FilesListStore.swift
//  Demo
//
//  Created by Sergey Armodin on 28.10.2020.
//  Copyright © 2020 Sergei Armodin. All rights reserved.
//

import Foundation
import Combine
import Uploadcare

class FilesListStore: ObservableObject {
	// MARK: - Public properties
	@Published var files: [FileViewData] = []
	var uploadcare: Uploadcare? {
		didSet {
			self.list = uploadcare?.listOfFiles()
		}
	}
	
	// MARK: - Private properties
	private var list: FilesList?
	
	// MARK: - Init
	init(files: [FileViewData]) {
		self.files = files
	}
	
	// MARK: - Public methods
	func load(_ completionHandler: @escaping (FilesList?, RESTAPIError?) -> Void) {
		let query = PaginationQuery()
			.limit(5)
			.ordering(.dateTimeUploadedDESC)
		
		self.list?.get(withQuery: query, completionHandler)
	}
	
	func loadNext(_ completionHandler: @escaping (FilesList?, RESTAPIError?) -> Void) {
		self.list?.nextPage(completionHandler)
	}
}
