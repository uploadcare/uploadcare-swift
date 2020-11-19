//
//  RandomTransformator.swift
//  Demo
//
//  Created by Sergey Armodin on 28.10.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation

struct RandomTransformator {
	static var sharp: [String] {
		let strength = (0...20).randomElement() ?? 0
		return ["sharp", "\(strength)"]
	}
	static var blur: [String] {
		let strength = (1...1000).randomElement() ?? 0
		return ["blur", "\(strength)"]
	}
	
	static var imageFilter: [String] {
		let name = [
		  "adaris",
		  "briaril",
		  "calarel",
		  "carris",
		  "cynarel",
		  "cyren",
		  "elmet",
		  "elonni",
		  "enzana",
		  "erydark",
		  "fenralan",
		  "ferand",
		  "galen",
		  "gavin",
		  "gethriel",
		  "iorill",
		  "iothari",
		  "iselva",
		  "jadis",
		  "lavra",
		  "misiara",
		  "namala",
		  "nerion",
		  "nethari",
		  "pamaya",
		  "sarnar",
		  "sedis",
		  "sewen",
		  "sorahel",
		  "sorlen",
		  "tarian",
		  "thellassan",
		  "varriel",
		  "varven",
		  "vevera",
		  "virkas",
		  "yedis",
		  "yllara",
		  "zatvel",
		  "zevcen"
		].randomElement() ?? "zevcen"
		
		let amount = (-100...200).randomElement() ?? 100
		return ["filter", "\(name)", "\(amount)"]
	}
	
	static var crop: [String] {
		let width = (100...1000).randomElement()!
		let height = (100...1000).randomElement()!
		
		return ["scale_crop", "\(width)x\(height)", "smart"]
	}
	
	static func getRandomTransformation(imageURL: URL) -> URL {
		let effects = [crop, imageFilter, blur, sharp]
		
		let randomNumber = (2..<effects.count).randomElement()!
		var newURL = imageURL
		
		for i in (0...randomNumber) {
			let effect = effects[i]
			
			newURL = newURL.appendingPathComponent("-")
			for el in effect {
				newURL = newURL.appendingPathComponent(el)
			}
		}
		return newURL
	}
}
