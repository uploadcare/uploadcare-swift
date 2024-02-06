//
//  Uploader.swift
//
//
//  Created by Sergei Armodin on 27.12.2023.
//

import SwiftUI
import Uploadcare


@available(iOS 13.0, *)
public struct UploaderSourceView: View {
	@State private var pickerType: PickerType
	internal var onSelected: (([URL]) -> Void)?

	// MARK: - Init
	internal init(pickerType: PickerType = .none) {
		self.pickerType = pickerType
	}

	public var body: some View {
		switch pickerType {
		case .none:
			Text("none")
		case .photos:
			ImagePicker(sourceType: .photoLibrary) { imageUrl in
				onSelected?([imageUrl])
			}
		case .files:
			DocumentPicker { urls in
				onSelected?(urls)
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
	public var currentUploadingNumber: Int {
		return min(fileIds.count + 1, uploadQueue.count)
	}
	@Published public var uploadProgress: Double = 0
	@Published public var fileIds = [String]()
	@Published public var pickerType: PickerType = .none

	private var photosPicker: UploaderSourceView
	private var nonePicker: UploaderSourceView
	private var docsPicker: UploaderSourceView

	@Published public var isUploading = false
	public var onUploadFinished: (([String]) -> Void)?

	public var picker: UploaderSourceView {
		switch pickerType {
		case .photos: return photosPicker
		case .none: return nonePicker
		case .files: return docsPicker
		}
	}

	// MARK: - Private properties
	private let uploadcare: Uploadcare
	private var newFileIDs = [String]()

	// MARK: - Init
	public init(uploadcare: Uploadcare) {
		self.uploadcare = uploadcare
		self.photosPicker = UploaderSourceView(pickerType: .photos)
		self.nonePicker = UploaderSourceView(pickerType: .none)
		self.docsPicker = UploaderSourceView(pickerType: .files)

		let onSelected: (([URL]) -> Void) = { [weak self] urls in
			guard let self = self, !urls.isEmpty else { return }

			withAnimation(.easeIn) { [weak self] in
				self?.isUploading = true
			}

			urls.forEach({ self.uploadQueue.append($0) })
			newFileIDs.removeAll()

			Task { [weak self] in
				guard let self = self else { return }
				do {

					for fileURL in urls {
						let fileID = try await self.uploadFile(fromURL: fileURL)
						newFileIDs.append(fileID)
						await MainActor.run { [weak self] in
							self?.fileIds.append(fileID)
						}
					}

					await MainActor.run { [weak self] in
						withAnimation(.easeOut) { [weak self] in
							self?.isUploading = false
						}
						guard let self = self else { return }
						self.onUploadFinished?(self.newFileIDs)
					}
					try await Task.sleep(nanoseconds: NSEC_PER_SEC * 1)
					await MainActor.run {
						self.fileIds = self.fileIds.filter({ self.newFileIDs.contains($0) == false })
						self.uploadQueue = self.uploadQueue.filter({ urls.contains($0) == false })
					}
				} catch {
					DLog("Could not upload file: \(String(describing: error))")
				}
			}
		}
		self.photosPicker.onSelected = onSelected
		self.docsPicker.onSelected = onSelected
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
}
