//
//  RemoveBGAddonExecutionParams.swift
//  
//
//  Created by Sergei Armodin on 16.09.2022.
//

import Foundation

/// remove.bg Add-On specific parameters.
public struct RemoveBGAddonExecutionParams: Codable {
	/// Classification type level.
	///
	/// .none = No classification (foreground_type won't bet set in the application data)
	/// .one = Use coarse classification classes: [person, product, animal, car, other]
	/// .two = Use more specific classification classes: [person, product, animal, car, car_interior, car_part, transportation, graphics, other]
	/// .latest = Always use the latest classification classes available
	public enum TypeLevel: String, Codable {
		case none
		case one = "1"
		case two = "2"
		case latest
	}

	/// Foreground type.
	public enum ForegroundType: String, Codable {
		case auto, person, product, car
	}

	public enum Channels: String, Codable {
		case rgba, alpha
	}

	/// Whether to crop off all empty regions.
	public var crop: Bool?

	/// Adds a margin around the cropped subject, e.g 30px or 30%.
	public var cropMargin: String?

	/// Scales the subject relative to the total image size.
	public var scale: String?

	/// Whether to add an artificial shadow to the result.
	public var addShadow: Bool?

	/// Classification type level.
	public var typeLevel: TypeLevel?

	/// Foreground type.
	public var foregroundType: ForegroundType?

	/// Whether to have semi-transparent regions in the result.
	public var semitransparency: Bool?

	/// Request either the finalized image ('rgba', default) or an alpha mask ('alpha').
	public var channels: Channels?

	/// Region of interest: Only contents of this rectangular region can be detected as foreground. Everything outside is considered background and will be removed. The rectangle is defined as two x/y coordinates in the format "x1 y1 x2 y2". The coordinates can be in absolute pixels (suffix 'px') or relative to the width/height of the image (suffix '%'). By default, the whole image is the region of interest ("0% 0% 100% 100%").
	public var roi: String?

	/// Positions the subject within the image canvas. Can be "original" (default unless "scale" is given), "center" (default when "scale" is given) or a value from "0%" to "100%" (both horizontal and vertical) or two values (horizontal, vertical).
	public var position: String?


	enum CodingKeys: String, CodingKey {
		case crop
		case cropMargin = "crop_margin"
		case scale
		case addShadow = "add_shadow"
		case typeLevel = "type_level"
		case foregroundType = "type"
		case semitransparency
		case channels, roi, position
	}

	public init(crop: Bool? = nil, cropMargin: String? = nil, scale: String? = nil, addShadow: Bool? = nil, typeLevel: RemoveBGAddonExecutionParams.TypeLevel? = nil, foregroundType: RemoveBGAddonExecutionParams.ForegroundType? = nil, semitransparency: Bool? = nil, channels: RemoveBGAddonExecutionParams.Channels? = nil, roi: String? = nil, position: String? = nil) {
		self.crop = crop
		self.cropMargin = cropMargin
		self.scale = scale
		self.addShadow = addShadow
		self.typeLevel = typeLevel
		self.foregroundType = foregroundType
		self.semitransparency = semitransparency
		self.channels = channels
		self.roi = roi
		self.position = position
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		self.crop = try container.decodeIfPresent(Bool.self, forKey: .crop)
		self.cropMargin = try container.decodeIfPresent(String.self, forKey: .cropMargin)
		self.scale = try container.decodeIfPresent(String.self, forKey: .scale)
		self.addShadow = try container.decodeIfPresent(Bool.self, forKey: .addShadow)
		self.typeLevel = try container.decodeIfPresent(TypeLevel.self, forKey: .typeLevel)
		self.foregroundType = try container.decodeIfPresent(ForegroundType.self, forKey: .foregroundType)
		self.semitransparency = try container.decodeIfPresent(Bool.self, forKey: .semitransparency)
		self.channels = try container.decodeIfPresent(Channels.self, forKey: .channels)
		self.roi = try container.decodeIfPresent(String.self, forKey: .roi)
		self.position = try container.decodeIfPresent(String.self, forKey: .position)
	}
}

internal struct RemoveBGAddonExecutionRequestBody: Codable {
	let target: String
	let params: RemoveBGAddonExecutionParams?
}
