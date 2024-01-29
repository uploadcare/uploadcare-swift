//
//  Uploader.swift
//
//
//  Created by Sergei Armodin on 27.12.2023.
//

import SwiftUI
import Uploadcare


@available(iOS 13.0, *)
public struct UploaderView: View {
	@State private var pickerType: PickerType
	var onSelected: (([URL]) -> Void)?

	// MARK: - Init
	public init(pickerType: PickerType = .none, uploadcare: Uploadcare) {
		self.pickerType = pickerType
	}

	public var body: some View {
		switch pickerType {
		case .none:
			Text("none")
		case .photos:
			ImagePicker(sourceType: .photoLibrary) { imageUrl in
				onSelected?([imageUrl])
//				withAnimation(.easeIn) {
//					self.isUploading = true
//				}

//				self.uploader.uploadQueue.append(imageUrl)
//
//				Task {
//					do {
//						let fileID = try await self.uploader.uploadFile(fromURL: imageUrl)
//
//						await MainActor.run {
//							self.uploader.fileIds = [fileID]
//						}
//					} catch {
//						DLog("Could not upload file: \(String(describing: error))")
//					}
//					self.uploader.uploadQueue.removeAll(where: { $0 == imageUrl })
//				}
			}
		case .files:
			DocumentPicker { urls in
//				withAnimation(.easeIn) {
//					self.uploader.isUploading = true
//				}
//
//				Task {
//					do {
//						self.uploader.fileIds.removeAll()
//						for url in urls {
//							let fileID = try await self.uploader.uploadFile(fromURL: url)
//							self.uploader.fileIds.append(fileID)
//							self.uploader.uploadQueue.removeAll(where: { $0 == url })
//						}
//					} catch {
//						DLog("Could not upload file: \(String(describing: error))")
//					}
//				}
			}
		}
	}
}

@available(iOS 13.0, *)
public class Uploader: ObservableObject {
	public enum UploaderError: Error {
		case couldNotReadDataFromURL
	}

	// MARK: - Public properties
	@Published public var uploadQueue = [URL]()
	@Published public var uploadProgress: Double = 0
	@Published public var fileIds = [String]()
	@Published public var pickerType: PickerType = .none

	private var photosPicker: UploaderView
	private var nonePicker: UploaderView
	private var docsPicker: UploaderView

	@Published public var isUploading = false

	public var picker: UploaderView {
		switch pickerType {
		case .photos: return photosPicker
		case .none: return nonePicker
		case .files: return docsPicker
		}
	}

	// MARK: - Private properties
	private let uploadcare: Uploadcare

	// MARK: - Init
	public init(uploadcare: Uploadcare) {
		self.uploadcare = uploadcare
		self.photosPicker = UploaderView(pickerType: .photos, uploadcare: uploadcare)
		self.nonePicker = UploaderView(pickerType: .none, uploadcare: uploadcare)
		self.docsPicker = UploaderView(pickerType: .files, uploadcare: uploadcare)

		self.photosPicker.onSelected = { urls in
			guard let imageUrl = urls.first else { return }
			withAnimation(.easeIn) {
				self.isUploading = true
			}

			self.uploadQueue.append(imageUrl)

			Task {
				do {
					let fileID = try await self.uploadFile(fromURL: imageUrl)

					await MainActor.run {
						self.fileIds = [fileID]
						self.uploadQueue.removeAll(where: { $0 == imageUrl })

						withAnimation(.easeOut) {
							self.isUploading = false
//							delay(0.5) {
//								self.messageText = "Upload finished"
//								delay(3) {
//									self.messageText = ""
//								}
//							}
						}
					}
				} catch {
					DLog("Could not upload file: \(String(describing: error))")
				}
			}
		}
		self.docsPicker.onSelected = { urls in
			withAnimation(.easeIn) {
				self.isUploading = true
			}
		}
	}

	internal func uploadFile(fromURL url: URL) async throws -> String {
		guard let data = try? Data(contentsOf: url) else {
			throw UploaderError.couldNotReadDataFromURL
		}
		let filename = url.lastPathComponent
		let file = try await uploadcare.uploadFile(data, withName: filename, store: .auto) { [weak self] progress in
			DispatchQueue.main.async { [weak self] in
				self?.uploadProgress = progress
			}
		}
		return file.fileId
	}


//	public var imagePicker: some View {
//		ImagePicker(sourceType: .photoLibrary) { imageUrl in
//			withAnimation(.easeIn) {
//				self.isUploading = true
//			}
//
//			self.uploadQueue.append(imageUrl)
//
//			Task {
//				do {
//					let fileID = try await self.uploadFile(fromURL: imageUrl)
//
//					await MainActor.run {
//						self.fileIds = [fileID]
//					}
//				} catch {
//					DLog("Could not upload file: \(String(describing: error))")
//				}
//				self.uploadQueue.removeAll(where: { $0 == imageUrl })
//			}
//		}
//	}

//	public var documentsPicker: some View {
//		DocumentPicker { urls in
//			withAnimation(.easeIn) {
////				self.isUploading = true
//			}
//
//			Task {
//				do {
//					self.fileIds.removeAll()
//					for url in urls {
//						let fileID = try await self.uploadFile(fromURL: url)
//						self.fileIds.append(fileID)
//						self.uploadQueue.removeAll(where: { $0 == url })
//					}
//				} catch {
//					DLog("Could not upload file: \(String(describing: error))")
//				}
//			}
//		}
//	}
}
