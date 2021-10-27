//
//  ImageLoader.swift
//  
//
//  Created by Sergey Armodin on 13.06.2021.
//  Copyright © 2021 Uploadcare, Inc. All rights reserved.
//

import Combine
import UIKit

@available(iOS 13.0.0, OSX 10.15.0, *)
class ImageLoader: ObservableObject {
	// MARK: - Public properties
	@Published var image: UIImage?

	// MARK: - Private properties
	private(set) var isLoading = false
	private let url: URL
	private var cache: ImageCache?
	private var task: AnyCancellable?
	private static let queue = DispatchQueue(label: "UploadcareWidget.ImageLoader")

	// MARK: - Init
	init(url: URL, cache: ImageCache? = nil) {
		self.url = url
		self.cache = cache
	}

	deinit { cancel() }
}

// MARK: - Public methods
@available(iOS 13.0.0, OSX 10.15.0, *)
extension ImageLoader {
	func load() {
		guard !isLoading else { return }

		if let image = cache?[url] {
			self.image = image
			return
		}

		task = URLSession.shared.dataTaskPublisher(for: url)
			.map { UIImage(data: $0.data) }
			.replaceError(with: nil)
			.handleEvents(receiveSubscription: { [weak self] _ in self?.onStart() },
						  receiveOutput: { [weak self] in self?.cache($0) },
						  receiveCompletion: { [weak self] _ in self?.onFinish() },
						  receiveCancel: { [weak self] in self?.onFinish() })
			.subscribe(on: Self.queue)
			.receive(on: DispatchQueue.main)
			.sink { [weak self] in self?.image = $0 }
	}

	func cancel() {
		task?.cancel()
	}
}

// MARK: - Private methods
@available(iOS 13.0.0, OSX 10.15.0, *)
private extension ImageLoader {
	func onStart() {
		isLoading = true
	}

	func onFinish() {
		isLoading = false
	}

	func cache(_ image: UIImage?) {
		image.map { cache?[url] = $0 }
	}
}
