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
	@State var isShowingSheetWithPicker: Bool = false
	@EnvironmentObject var api: APIStore
	
	public var body: some View {
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
				Button("Camera") {
					self.isShowingSheetWithPicker.toggle()
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
				}
			}
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
