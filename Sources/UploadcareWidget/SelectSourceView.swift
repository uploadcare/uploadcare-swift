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
	let sources: [SocialSource] = SocialSource.Source.allCases.map { SocialSource(source: $0) }
	@State var currentSource: SocialSource?
	@State var isWebViewVisible: Bool = false
	@State private var selection: String? = nil
	private let publicKey: String
	@State var isShowingSheetWithPicker: Bool = true
	@State var isUploading: Bool = false
	
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
							self.isShowingSheetWithPicker.toggle()
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
				.sheet(isPresented: $isShowingSheetWithPicker) {
					ImagePicker(sourceType: .camera) { (imageUrl) in
						self.isShowingSheetWithPicker = false
						self.isUploading = true
						self.uploadFile(imageUrl) { _ in
							self.isUploading = false
						}
					}
				}
			}
			
			ActivityIndicator(isAnimating: .constant(true), style: .whiteLarge)
				.padding(.all)
				.background(Color.gray)
				.cornerRadius(16)
				.opacity(self.isUploading ? 1 : 0)
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
	
	private func uploadFile(_ url: URL, completionHandler: @escaping (String)->Void) {
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
	
	private func performDirectUpload(filename: String, data: Data, completionHandler: @escaping (String)->Void) {
		let onProgress: (Double)->Void = { (progress) in
			
		}
		self.api.uploadcare?.uploadAPI.upload(files: [filename: data], store: .store, onProgress, { (uploadData, error) in
			if let error = error {
				return DLog(error)
			}

			guard let uploadData = uploadData, let fileId = uploadData.first?.value else { return }
			completionHandler(fileId)
			DLog(uploadData)
		})
	}
	
	private func performMultipartUpload(filename: String, fileUrl: URL, completionHandler: @escaping (String)->Void) {
		let onProgress: (Double)->Void = { (progress) in
		}

		guard let fileForUploading = self.api.uploadcare?.uploadAPI.file(withContentsOf: fileUrl) else {
			assertionFailure("file not found")
			return
		}
		
		fileForUploading.upload(withName: filename, store: .store, onProgress, { (file, error) in
			if let error = error {
				DLog(error)
				return
			}
			
			guard let file = file else { return }
			completionHandler(file.fileId)
			DLog(file)
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
