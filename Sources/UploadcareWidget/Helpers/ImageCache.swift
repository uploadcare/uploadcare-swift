//
//  ImageCache.swift
//  
//
//  Created by Sergey Armodin on 13.06.2021.
//  Copyright © 2021 Uploadcare, Inc. All rights reserved.
//

import UIKit

struct ImageCache {
	private let cache: NSCache<NSURL, UIImage> = {
		let cache = NSCache<NSURL, UIImage>()
		cache.countLimit = 100
		cache.totalCostLimit = 1024 * 1024 * 100
		return cache
	}()

	subscript(_ key: URL) -> UIImage? {
		get { cache.object(forKey: key as NSURL) }
		set {
			newValue == nil
				? cache.removeObject(forKey: key as NSURL)
				: cache.setObject(newValue!, forKey: key as NSURL)
		}
	}
}
