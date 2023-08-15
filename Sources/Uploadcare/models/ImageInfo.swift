//
//  ImageInfo.swift
//  
//
//  Created by Sergey Armodin on 13.01.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation


/// Image color mode.
public enum ColorMode: String, Codable {
	case RGB
	case RGBA
	case RGBa
	case RGBX
	case L
	case LA
	case La
	case P
	case PA
	case CMYK
	case YCbCr
	case HSV
	case LAB
}


public struct ImageInfo: Codable, Equatable {
	/// Image height in pixels.
	public var height: Int
	
	/// Image width in pixels.
	public var width: Int
	
	/// Geo-location of image from EXIF.
	public var geoLocation: GeoLocation?
	
	/// Image date and time from EXIF.
	public var datetimeOriginal: String?
	
	/// Image format.
	public var format: String
	
	/// Image color mode.
	public var colorMode: ColorMode
	
	/// Image DPI for two dimensions.
	public var dpi: [Int]?
	
	/// Image orientation from EXIF.
	public var orientation: Int?
	
	/// Default: "Is image if sequence image(GIF for example)."
	public var sequence: Bool?
	
	
	enum CodingKeys: String, CodingKey {
		case height
		case width
		case geoLocation = "geo_location"
		case datetimeOriginal = "datetime_original"
		case format
		case colorMode = "color_mode"
		case dpi
		case orientation
		case sequence
	}
	
	
	public init(
		height: Int,
		width: Int,
		geoLocation: GeoLocation?,
		datetimeOriginal: String?,
		format: String,
		colorMode: ColorMode,
		dpi: [Int]?,
		orientation: Int?,
		sequence: Bool?
	) {
		self.height = height
		self.width = width
		self.geoLocation = geoLocation
		self.datetimeOriginal = datetimeOriginal
		self.format = format
		self.colorMode = colorMode
		self.dpi = dpi
		self.orientation = orientation
		self.sequence = sequence
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let height = try container.decodeIfPresent(Int.self, forKey: .height) ?? 0
		let width = try container.decodeIfPresent(Int.self, forKey: .width) ?? 0
		let geoLocation = try container.decodeIfPresent(GeoLocation.self, forKey: .geoLocation)
		let datetimeOriginal = try container.decodeIfPresent(String.self, forKey: .datetimeOriginal)
		let format = try container.decodeIfPresent(String.self, forKey: .format) ?? ""
		let colorMode = try container.decodeIfPresent(ColorMode.self, forKey: .colorMode) ?? .RGB
		let dpi = try container.decodeIfPresent([Int].self, forKey: .dpi)
		let orientation = try container.decodeIfPresent(Int.self, forKey: .orientation)
		let sequence = try container.decodeIfPresent(Bool.self, forKey: .sequence)
		
		self.init(
			height: height,
			width: width,
			geoLocation: geoLocation,
			datetimeOriginal: datetimeOriginal,
			format: format,
			colorMode: colorMode,
			dpi: dpi,
			orientation: orientation,
			sequence: sequence
		)
	}
}


extension ImageInfo: CustomDebugStringConvertible {
	public var debugDescription: String {
		return """
		\(type(of: self)):
				height: \(height)
				width: \(width)
				geoLocation: \(String(describing: geoLocation))
				datetimeOriginal: \(String(describing: datetimeOriginal))
				format: \(format)
				colorMode: \(colorMode)
				dpi: \(String(describing: dpi))
				orientation: \(String(describing: orientation))
				sequence: \(String(describing: sequence))
		"""
	}
}
