//
//  AsyncImage.swift
//  
//
//  Created by Sergey Armodin on 14.06.2021.
//  Copyright © 2021 Uploadcare, Inc. All rights reserved.
//

import SwiftUI

#if os(iOS)
@available(iOS 14.0.0, *)
struct AsyncImageOld<Placeholder: View>: View {
	@StateObject private var loader: ImageLoader
	private let placeholder: Placeholder
	private let image: (UIImage) -> Image

	init(
		url: URL,
		@ViewBuilder placeholder: () -> Placeholder,
		@ViewBuilder image: @escaping (UIImage) -> Image = Image.init(uiImage:)
	) {
		self.placeholder = placeholder()
		self.image = image
		_loader = StateObject(wrappedValue: ImageLoader(
			url: url,
			cache: Environment(\.imageCache).wrappedValue)
		)
	}

	var body: some View {
		content
			.onAppear(perform: loader.load)
	}

	private var content: some View {
		Group {
			if loader.image != nil {
				image(loader.image!)
			} else {
				placeholder
			}
		}
	}
}

struct ImageCacheKey: EnvironmentKey {
	static let defaultValue: ImageCache = ImageCache()
}

@available(iOS 13.0.0, *)
extension EnvironmentValues {
	var imageCache: ImageCache {
		get { self[ImageCacheKey.self] }
		set { self[ImageCacheKey.self] = newValue }
	}
}
#endif
