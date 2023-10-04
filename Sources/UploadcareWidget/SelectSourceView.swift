//
//  SelectSourceView.swift
//  
//
//  Created by Sergey Armodin on 18.12.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

#if os(iOS)
import SwiftUI
import Uploadcare

struct Config {
	static let baseUrl: String = "https://social.uploadcare.com"
	static let cookieDomain: String = "social.uploadcare.com"
}

@available(iOS 14.0.0, macOS 10.15.0, *)
public struct SelectSourceView: View {
	let sources: [SocialSource]
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
						Task {
							var message = "File uploaded"
							do {
								try await self.uploadFile(imageUrl)
							} catch {
								if let uploadError = error as? UploadError {
									message = uploadError.detail
								} else {
									DLog(error)
								}
							}
							
							await MainActor.run {
								withAnimation {
									self.isUploading = false
									self.fileUploadedMessage = message
									self.fileUploadedMessageVisible = true
								}
							}
							try await Task.sleep(nanoseconds: 2 * NSEC_PER_SEC)
							await MainActor.run {
								withAnimation {
									self.fileUploadedMessageVisible = false
								}
							}
						}
					}
					.ignoresSafeArea()
				}
			}
			
			ActivityIndicator(isAnimating: .constant(true), style: .large)
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
			chunkPath: source.chunks.first!.value,
			publicKey: publicKey
		)
	}

	private func uploadFile(_ url: URL) async throws {
		guard let uploadcare = api.uploadcare else {
			var error = UploadError.defaultError()
			error.detail = "Uploadcare object missing"
			throw error
		}
		let data = try Data(contentsOf: url)
		let filename = url.lastPathComponent
		try await uploadcare.uploadFile(data, withName: filename)
	}
	
	public init(publicKey: String, sources: [SocialSource]) {
		self.publicKey = publicKey
		self.sources = sources
	}
}
#endif
