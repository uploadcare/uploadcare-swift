//
//  AppData.swift
//
//
//  Created by Sergei Armodin on 14.09.2022.
//  Copyright © 2022 Uploadcare, Inc. All rights reserved.
//

import Foundation

/// Application names and data associated with these applications.
public struct AppData: Codable, Equatable {
	internal init(awsRekognitionDetectLabels: AWSRekognitionDetectLabels? = nil, clamavVirusScan: UCClamavVirusScan? = nil, removeBg: RemoveBg? = nil) {
		self.awsRekognitionDetectLabels = awsRekognitionDetectLabels
		self.clamavVirusScan = clamavVirusScan
		self.removeBg = removeBg
	}

	public var awsRekognitionDetectLabels: AWSRekognitionDetectLabels?
	public var clamavVirusScan: UCClamavVirusScan?
	public var removeBg: RemoveBg?

	enum CodingKeys: String, CodingKey {
		case awsRekognitionDetectLabels = "aws_rekognition_detect_labels"
		case clamavVirusScan = "uc_clamav_virus_scan"
		case removeBg = "remove_bg"
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let rekognitionDetectLabels = try container.decodeIfPresent(AWSRekognitionDetectLabels.self, forKey: .awsRekognitionDetectLabels)
		let clamavVirusScan = try container.decodeIfPresent(UCClamavVirusScan.self, forKey: .clamavVirusScan)
		let removeBg = try container.decodeIfPresent(RemoveBg.self, forKey: .removeBg)

		self.init(awsRekognitionDetectLabels: rekognitionDetectLabels, clamavVirusScan: clamavVirusScan, removeBg: removeBg)
	}
}
