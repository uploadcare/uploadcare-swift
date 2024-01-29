//
//  Uploader.swift
//
//
//  Created by Sergei Armodin on 27.12.2023.
//

import SwiftUI
import Uploadcare


@available(iOS 13.0, *)
public class Uploader {
	public enum UploaderError: Error {
		case couldNotReadDataFromURL
	}

	// MARK: - Public properties
	@State public var isUploading = false
	@State public var uploadQueue = [URL]()
	@State public var uploadProgress: Double = 0
	@State public var fileIds = [String]()

	// MARK: - Private properties
	private let uploadcare: Uploadcare

	// MARK: - Init
	public init(uploadcare: Uploadcare) {
		self.uploadcare = uploadcare
	}

	private func uploadFile(fromURL url: URL) async throws -> String {
		guard let data = try? Data(contentsOf: url) else {
			throw UploaderError.couldNotReadDataFromURL
		}
		let filename = url.lastPathComponent
		let file = try await uploadcare.uploadFile(data, withName: filename, store: .auto) { [weak self] progress in
			self?.uploadProgress = progress
		}
		return file.fileId
	}

	public var imagePicker: some View {
		ImagePicker(sourceType: .photoLibrary) { imageUrl in
			withAnimation(.easeIn) {
				self.isUploading = true
			}

			self.uploadQueue.append(imageUrl)

			Task {
				do {
					let fileID = try await self.uploadFile(fromURL: imageUrl)

					await MainActor.run {
						self.fileIds = [fileID]
					}
				} catch {
					DLog("Could not upload file: \(String(describing: error))")
				}
				self.uploadQueue.removeAll(where: { $0 == imageUrl })
			}
		}
	}

	public var documentsPicker: some View {
		DocumentPicker { urls in
			withAnimation(.easeIn) {
				self.isUploading = true
			}

			Task {
				do {
					self.fileIds.removeAll()
					for url in urls {
						let fileID = try await self.uploadFile(fromURL: url)
						self.fileIds.append(fileID)
						self.uploadQueue.removeAll(where: { $0 == url })
					}
				} catch {
					DLog("Could not upload file: \(String(describing: error))")
				}
			}
		}
	}
}
