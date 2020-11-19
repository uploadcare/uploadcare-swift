//
//  UploadFromURLResponse.swift
//  
//
//  Created by Sergey Armodin on 20.01.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation


public struct UploadFromURLResponse: Codable {
	
	public enum UploadFromURLResponseType: String, Codable {
		case token
		case fileInfo = "file_info"
	}
	
	/// Type of response
	public var type: UploadFromURLResponseType
	
	/// A token to identify a file for the upload status request.
	public var token: String?
	
	/// File info (if type == .fileInfo)
	public var fileInfo: UploadedFile?
	
	
	enum CodingKeys: String, CodingKey {
		case type
		case token
	}
	
	
	init(type: UploadFromURLResponseType, token: String?, fileInfo: UploadedFile?) {
		self.type = type
		self.token = token
		self.fileInfo = fileInfo
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let type = try container.decodeIfPresent(UploadFromURLResponseType.self, forKey: .type) ?? UploadFromURLResponseType.token
		let token = try container.decodeIfPresent(String.self, forKey: .token)
		
		let fileInfo = try? UploadedFile(from: decoder)
		
		self.init(type: type, token: token, fileInfo: fileInfo)
	}
	
}
