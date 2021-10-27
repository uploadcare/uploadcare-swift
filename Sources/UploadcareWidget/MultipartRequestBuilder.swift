//
//  MultipartRequestBuilder.swift
//  
//
//  Created by Sergey Armodin on 01.04.2021.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation

class MultipartRequestBuilder {
	private var boundary = UUID().uuidString
	private var request: URLRequest

	internal init(boundary: String = UUID().uuidString, request: URLRequest) {
		self.boundary = boundary
		self.request = request
	}

	func addMultiformValue(_ value: String, forName name: String) {
		var data = self.request.httpBody ?? Data()

		data.append("--\(boundary)\r\n".data(using: .utf8) ?? Data())
		data.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8) ?? Data())
		data.append("\(value)\r\n".data(using: .utf8) ?? Data())

		self.request.httpBody = data
	}

	func finalize() -> URLRequest {
		var data = self.request.httpBody ?? Data()
		data.append("--\(boundary)--\r\n".data(using: .utf8) ?? Data())
		self.request.httpBody = data

		// Headers
		self.request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
		self.request.setValue("\(self.request.httpBody?.count ?? 0)", forHTTPHeaderField: "Content-Length")
		return self.request
	}
}
