//
//  SelectSourceView.swift
//  
//
//  Created by Sergey Armodin on 18.12.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import SwiftUI
import Uploadcare

struct Config {
	static let baseUrl: String = "https://social.uploadcare.com"
	static let cookieDomain: String = "social.uploadcare.com"
}

@available(iOS 14.0.0, OSX 10.15.0, *)
public struct SelectSourceView: View {	
	private let sources: [SocialSource] = SocialSource.Source.allCases.map { SocialSource(source: $0) }
	private let publicKey: String
	
	@State private var currentSource: SocialSource?
	@State private var isWebViewVisible: Bool = false
	@State private var selection: String? = nil
	@State private var isShowingCameraPicker: Bool = false
	
	@State private var isUploading: Bool = false
	@State private var fileUploadedMessageVisible: Bool = false
	@State private var fileUploadedMessage: String = ""
	
	@EnvironmentObject var api: APIStore
	
	public var body: some View {
		ZStack {
			VStack(alignment: .leading) {
				if let source = $currentSource.wrappedValue {
					NavigationLink(
						destination: FilesListView(viewModel: self.createViewModelForSource(source), isRoot: true),
						tag: source.source.rawValue,
						selection: $selection
					) {
						Text(source.title)
					}.opacity(0)
				}

				List {
					if UIImagePickerController.isSourceTypeAvailable(.camera) {
						Button("Camera") {
							self.isShowingCameraPicker.toggle()
						}
					}
					
					ForEach(self.sources) { source in
						Button(source.getCookie() == nil ? source.title : "✓ " + source.title) {
							self.currentSource = source

							if source.getCookie() != nil  {
								self.selection = source.source.rawValue
							} else {
								self.isWebViewVisible = true
							}
						}
					}
				}
				.sheet(isPresented: self.$isWebViewVisible) {
					WebView(url: $currentSource.wrappedValue?.url, onComplete: { cookies in
						if let cookie = cookies.filter({ $0.path == currentSource?.cookiePath }).first {
							currentSource?.saveCookie(cookie)
							self.isWebViewVisible = false
							if let source =  $currentSource.wrappedValue {
								self.selection = source.source.rawValue
							}
						}
					})
				}
				.fullScreenCover(isPresented: $isShowingCameraPicker) {
					ImagePicker(sourceType: .camera) { (imageUrl) in
						self.isShowingCameraPicker = false
						self.isUploading = true
						self.uploadFile(imageUrl) { uploadError in
							self.isUploading = false
							
							if let uploadError = uploadError {
								self.fileUploadedMessage = uploadError.detail
							} else {
								self.fileUploadedMessage = "File uploaded"
							}
							
							withAnimation {
								self.fileUploadedMessageVisible = true
							}

							DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
								withAnimation {
									self.fileUploadedMessageVisible = false
								}
							}
						}
					}
					.ignoresSafeArea()
				}
			}
			
			ActivityIndicator(isAnimating: .constant(true), style: .whiteLarge)
				.padding(.all)
				.background(Color.gray)
				.cornerRadius(16)
				.opacity(self.isUploading ? 1 : 0)
			
			Text(self.fileUploadedMessage)
				.font(.title)
				.padding(.all)
				.background(Color.gray)
				.foregroundColor(.white)
				.cornerRadius(16)
				.opacity(self.fileUploadedMessageVisible ? 1 : 0)
		}
		.navigationBarTitle(Text("Select Source"))
    }

	private func createViewModelForSource(_ source: SocialSource) -> FilesListViewModel {
		return FilesListViewModel(
			source: source,
			cookie: source.getCookie() ?? "",
			chunkPath: source.chunks.first!.values.first!,
			publicKey: publicKey
		)
	}
	
	private func uploadFile(_ url: URL, completionHandler: @escaping (UploadError?)->Void) {
		let data: Data
		do {
			data = try Data(contentsOf: url)
		} catch let error {
			DLog(error)
			return
		}
		
		let filename = url.lastPathComponent

		if data.count < UploadAPI.multipartMinFileSize {
			self.performDirectUpload(filename: filename, data: data, completionHandler: completionHandler)
		} else {
			self.performMultipartUpload(filename: filename, fileUrl: url, completionHandler: completionHandler)
		}
	}
	
	private func performDirectUpload(filename: String, data: Data, completionHandler: @escaping (UploadError?)->Void) {
		let onProgress: (Double)->Void = { (progress) in
			
		}
		self.api.uploadcare?.uploadAPI.directUpload(files: [filename: data], store: .store, onProgress, { (uploadData, error) in
			if let error = error {
				DLog(error)
				completionHandler(error)
			}

			completionHandler(nil)
			DLog(uploadData ?? "no data")
		})
	}
	
	private func performMultipartUpload(filename: String, fileUrl: URL, completionHandler: @escaping (UploadError?)->Void) {
		let onProgress: (Double)->Void = { (progress) in
		}

		guard let fileForUploading = self.api.uploadcare?.uploadAPI.file(withContentsOf: fileUrl) else {
			assertionFailure("file not found")
			return
		}
		
		fileForUploading.upload(withName: filename, store: .store, onProgress, { (file, error) in
			if let error = error {
				DLog(error)
				completionHandler(error)
				return
			}
			
			completionHandler(nil)
			DLog(file ?? "no file")
		})
	}
	
	public init(publicKey: String) {
		self.publicKey = publicKey
	}
}

//@available(iOS 13.0.0, OSX 10.15.0, *)
//struct SelectSourceView_Previews: PreviewProvider {
//    static var previews: some View {
//		SelectSourceView()
//			.previewLayout(.sizeThatFits)
//    }
//}
