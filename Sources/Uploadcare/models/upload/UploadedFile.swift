//
//  UploadedFileInfo.swift
//  
//
//  Created by Sergey Armodin on 13.01.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation


/// File Info model that is used for Upload API.
public class UploadedFile: Codable {

	// MARK: - Public properties
	
	/// File size in bytes.
	public var size: Int
	
	/// File size in bytes. Same as size.
	public var total: Int

	/// Same as ``size``.
	public var done: Int
	
	/// File UUID.
	public var uuid: String

	/// Same as ``uuid``.
	public var fileId: String
	
	/// Original file name taken from uploaded file.
	public var originalFilename: String
	
	/// Sanitized ``originalFilename``.
	public var filename: String
	
	/// File MIME-type.
	public var mimeType: String
	
	/// Is file an image.
	public var isImage: Bool
	
	/// Is file stored.
	public var isStored: Bool
	
	/// Is file ready to be used after upload.
	public var isReady: Bool
	
	/// Image metadata.
	public var imageInfo: ImageInfo?
	
	/// Video metadata.
	public var videoInfo: VideoInfo?

	/// Information about file content.
	public var contentInfo: ContentInfo?

	/// Arbitrary metadata associated with a file.
	/// Metadata is key-value data. You can specify up to 50 keys, with key names up to 64 characters long and values up to 512 characters long.
	public var metadata: [String: String]?
	
	/// Your custom user bucket on which file are stored. Only available of you setup foreign storage bucket for your project.
	public var s3Bucket: String?
	
	/// The field contains a set of processing operations applied to the file when the group was created. This set is applied by default when the file is reffered via a group CDN URL and `/nth/N/` operator.
	public var defaultEffects: String?

	// MARK: - Private properties

	/// REST API.
	private weak var restAPI: Uploadcare?
	
	/// File URL.
	private var fileUrl: URL?
	
	// File data.
	private var data: Data?
	
	
	enum CodingKeys: String, CodingKey {
		case size
		case total
		case done
		case uuid
		case fileId = "file_id"
		case originalFilename = "original_filename"
		case filename
		case mimeType = "mime_type"
		case isImage = "is_image"
		case isStored = "is_stored"
		case isReady = "is_ready"
		case imageInfo = "image_info"
		case videoInfo = "video_info"
		case contentInfo = "content_info"
		case metadata
		case s3Bucket = "s3_bucket"
		case defaultEffects = "default_effects"
	}
	
	
	// MARK: - Init
	init(
		size: Int,
		total: Int,
		done: Int,
		uuid: String,
		fileId: String,
		originalFilename: String,
		filename: String,
		mimeType: String,
		isImage: Bool,
		isStored: Bool,
		isReady: Bool,
		imageInfo: ImageInfo?,
		videoInfo: VideoInfo?,
		contentInfo: ContentInfo?,
		metadata: [String: String]?,
		s3Bucket: String?,
		defaultEffects: String?
	) {
		self.size = size
		self.total = total
		self.done = done
		self.uuid = uuid
		self.fileId = fileId
		self.originalFilename = originalFilename
		self.filename = filename
		self.mimeType = mimeType
		self.isImage = isImage
		self.isStored = isStored
		self.isReady = isReady
		self.imageInfo = imageInfo
		self.videoInfo = videoInfo
		self.contentInfo = contentInfo
		self.metadata = metadata
		self.s3Bucket = s3Bucket
		self.defaultEffects = defaultEffects
	}
	
	required public convenience init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let size = try container.decodeIfPresent(Int.self, forKey: .size) ?? 0
		let total = try container.decodeIfPresent(Int.self, forKey: .total) ?? 0
		let done = try container.decodeIfPresent(Int.self, forKey: .done) ?? 0
		let uuid = try container.decodeIfPresent(String.self, forKey: .uuid) ?? ""
		let fileId = try container.decodeIfPresent(String.self, forKey: .fileId) ?? ""
		let originalFilename = try container.decodeIfPresent(String.self, forKey: .originalFilename) ?? ""
		let filename = try container.decodeIfPresent(String.self, forKey: .filename) ?? ""
		let mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType) ?? ""
		let isImage = try container.decodeIfPresent(Bool.self, forKey: .isImage) ?? false
		let isStored = try container.decodeIfPresent(Bool.self, forKey: .isStored) ?? false
		let isReady = try container.decodeIfPresent(Bool.self, forKey: .isReady) ?? false
		let imageInfo = try container.decodeIfPresent(ImageInfo.self, forKey: .imageInfo)
		let videoInfo = try container.decodeIfPresent(VideoInfo.self, forKey: .videoInfo)
		let contentInfo = try container.decodeIfPresent(ContentInfo.self, forKey: .contentInfo)
		let metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata)
		let s3Bucket = try container.decodeIfPresent(String.self, forKey: .s3Bucket)
		let defaultEffects = try container.decodeIfPresent(String.self, forKey: .defaultEffects)

		self.init(
			size: size,
			total: total,
			done: done,
			uuid: uuid,
			fileId: fileId,
			originalFilename: originalFilename,
			filename: filename,
			mimeType: mimeType,
			isImage: isImage,
			isStored: isStored,
			isReady: isReady,
			imageInfo: imageInfo,
			videoInfo: videoInfo,
			contentInfo: contentInfo,
			metadata: metadata,
			s3Bucket: s3Bucket,
			defaultEffects: defaultEffects
		)
	}
	
	public init(withData data: Data, restAPI: Uploadcare) {
		self.data = data
		self.restAPI = restAPI
		
		self.size = data.count
		self.total = data.count
		self.done = data.count
		self.uuid = ""
		self.fileId = ""
		self.originalFilename = ""
		self.filename = ""
		self.mimeType = detectMimeType(for: data)
		self.isImage = ["image/jpeg", "image/png", "image/gif", "image/tiff"].contains(self.mimeType)
		self.isStored = true
		self.isReady = false
		self.imageInfo = nil
		self.videoInfo = nil
		self.contentInfo = nil
		self.metadata = nil
		self.s3Bucket = ""
		self.defaultEffects = nil
	}
	
	
	// MARK: - Public methods

	/// Upload file.
	///
	/// Example:
	/// ```swift
	/// var fileForUploading = uploadcare.file(withContentsOf: url)!
	///
	/// let onProgress: (Double)->Void = { (progress) in
	///     print("progress: \(progress)")
	/// }
	///
	/// let task = fileForUploading.upload(withName: "my_file.jpg", store: .auto, onProgress, { result in
	///     switch result {
	///         case .failure(let error):
	///             print(error.detail)
	///         case .success(let file):
	///             print(file)
	///     }
	/// })
	///
	/// // pause:
	/// (task as? UploadTaskResumable)?.pause()
	///
	/// // resume:
	/// (task as? UploadTaskResumable)?.resume()
	/// ```
	///
	/// - Parameters:
	///   - name: File name.
	///   - store: A flag indicating if we should store your outputs.
	///   - uploadSignature: Sets the signature for the upload request.
	///   - onProgress: A callback that will be used to report upload progress.
	///   - completionHandler: Completion handler.
	/// - Returns: Upload task. Confirms to UploadTaskable protocol in anycase. Might confirm to UploadTaskResumable protocol (which inherits UploadTaskable)  if multipart upload was used so you can pause and resume upload.
	#if !os(Linux)
	@discardableResult
	public func upload(
		withName name: String,
		store: StoringBehavior? = nil,
		uploadSignature: UploadSignature? = nil,
		_ onProgress: ((Double) -> Void)? = nil,
		_ completionHandler: ((Result<UploadedFile, UploadError>) -> Void)? = nil
	) -> UploadTaskable? {
		guard let fileData = self.data else {
			completionHandler?(.failure(UploadError(status: 0, detail: "Unable to upload file: Data is empty.")))
			return nil
		}
		
		self.originalFilename = name
		self.filename = name

		return restAPI?.uploadFile(fileData, withName: name, store: store ?? .store, metadata: self.metadata, uploadSignature: uploadSignature, { progress in
			onProgress?(progress)
		}, { [weak self] result in
			switch result {
			case .failure(let error):
				completionHandler?(.failure(error))
				return
			case .success(let uploadedFile):
				defer { completionHandler?(.success(uploadedFile)) }

				guard let self = self else { return }

				self.size = uploadedFile.size
				self.total = uploadedFile.total
				self.done = uploadedFile.done
				self.uuid = uploadedFile.uuid
				self.fileId = uploadedFile.fileId
				self.originalFilename = uploadedFile.originalFilename
				self.filename = uploadedFile.filename
				self.mimeType = uploadedFile.mimeType
				self.isImage = uploadedFile.isImage
				self.isStored = uploadedFile.isStored
				self.isReady = uploadedFile.isReady
				self.imageInfo = uploadedFile.imageInfo
				self.videoInfo = uploadedFile.videoInfo
				self.contentInfo = uploadedFile.contentInfo
				self.metadata = uploadedFile.metadata
				self.s3Bucket = uploadedFile.s3Bucket
				self.defaultEffects = uploadedFile.defaultEffects
			}
		})
	}
	#endif

	/// Upload file.
	///
	/// Example:
	/// ```swift
	/// let url = URL(string: "https://source.unsplash.com/featured")!
	/// let data = try! Data(contentsOf: url)
	/// let fileForUploading = uploadcarePublicKeyOnly.file(fromData: data)
	///
	/// let uploadedFile = try await fileForUploading.upload(
	///     withName: "my_file.jpg",
	///     store: .auto
	/// )
	/// ```
	/// - Parameters:
	///   - name: File name.
	///   - store: A flag indicating if we should store your outputs.
	///   - uploadSignature: Sets the signature for the upload request.
	///   - onProgress: A callback that will be used to report upload progress.
	/// - Returns: Uploaded file.
	@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	@discardableResult
	public func upload(
		withName name: String,
		store: StoringBehavior? = nil,
		uploadSignature: UploadSignature? = nil,
		_ onProgress: ((Double) -> Void)? = nil
	) async throws -> UploadedFile {
		guard let fileData = self.data else {
			throw UploadError(status: 0, detail: "Unable to upload file: Data is empty.")
		}

		guard let restAPI = restAPI else {
			throw UploadError(status: 0, detail: "REST API object missing.")
		}

		self.originalFilename = name
		self.filename = name

		let uploadedFile = try await restAPI.uploadFile(fileData, withName: name, store: store ?? .store, metadata: self.metadata, uploadSignature: uploadSignature, onProgress)

		self.size = uploadedFile.size
		self.total = uploadedFile.total
		self.done = uploadedFile.done
		self.uuid = uploadedFile.uuid
		self.fileId = uploadedFile.fileId
		self.originalFilename = uploadedFile.originalFilename
		self.filename = uploadedFile.filename
		self.mimeType = uploadedFile.mimeType
		self.isImage = uploadedFile.isImage
		self.isStored = uploadedFile.isStored
		self.isReady = uploadedFile.isReady
		self.imageInfo = uploadedFile.imageInfo
		self.videoInfo = uploadedFile.videoInfo
		self.contentInfo = uploadedFile.contentInfo
		self.metadata = uploadedFile.metadata
		self.s3Bucket = uploadedFile.s3Bucket
		self.defaultEffects = uploadedFile.defaultEffects

		return self
	}
}


extension UploadedFile: CustomDebugStringConvertible {
	public var debugDescription: String {
		return """
		\(type(of: self)):
			size: \(size)
			total: \(total)
			done: \(done)
			uuid: \(uuid)
			fileId: \(fileId)
			originalFilename: \(originalFilename)
			filename: \(filename)
			mimeType: \(mimeType)
			isImage: \(isImage)
			isStored: \(isStored)
			isReady: \(isReady)
			imageInfo: \(String(describing: imageInfo))
			videoInfo: \(String(describing: videoInfo))
			contentInfo: \(String(describing: contentInfo))
			metadata: \(String(describing: metadata))
			s3Bucket: \(String(describing: s3Bucket))
			defaultEffects: \(String(describing: defaultEffects))
		"""
	}
}
