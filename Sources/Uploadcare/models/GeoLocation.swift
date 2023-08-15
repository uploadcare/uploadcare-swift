//
//  File.swift
//  
//
//  Created by Sergey Armodin on 14.01.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation


/// Geo-location of image from EXIF.
public struct GeoLocation: Codable, Equatable {
	
	/// Location latitude.
	public var latitude: Double
	
	/// Location longitude.
	public var longitude: Double
	
	
	enum CodingKeys: String, CodingKey {
		case latitude
		case longitude
	}
	
	
	init(latitude: Double, longitude: Double) {
		self.latitude = latitude
		self.longitude = longitude
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let latitude = try container.decodeIfPresent(Double.self, forKey: .latitude) ?? 0
		let longitude = try container.decodeIfPresent(Double.self, forKey: .longitude) ?? 0
		
		self.init(latitude: latitude, longitude: longitude)
	}
	
}
