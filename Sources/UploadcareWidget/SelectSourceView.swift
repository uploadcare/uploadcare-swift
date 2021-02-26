//
//  SelectSourceView.swift
//  
//
//  Created by Sergey Armodin on 18.12.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import SwiftUI

struct Config {
	static let baseUrl: String = "https://social.uploadcare.com"
	static let cookieDomain: String = "social.uploadcare.com"
}

@available(iOS 13.0.0, OSX 10.15.0, *)
public struct SelectSourceView: View {
	let sources: [SocialSource] = SocialSource.Source.allCases.map { SocialSource(source: $0) }
	
	public var body: some View {
		VStack(alignment: .leading) {
			List {
				ForEach(self.sources) { source in
					if let savedCookie = source.getCookie() {
						NavigationLink(
							destination: FilesLIstView(
								viewModel: FilesLIstViewModel(
									source: source,
									cookie: savedCookie,
									chunkPath: source.chunks.first!.values.first!
								),
								isRoot: true
							)
						) {
							Text(source.title)
						}
					} else {
						NavigationLink(destination: WebView(url: source.url, onComplete: { cookies in
							if let cookie = cookies.filter({ $0.path == source.cookiePath }).first {
								source.saveCookie(cookie)
							}
						})) {
							Text(source.title)
						}
					}
				}
			}
		}
		.navigationBarTitle(Text("Select Source"))
    }
	
	public init() {
		
	}
}

@available(iOS 13.0.0, OSX 10.15.0, *)
struct SelectSourceView_Previews: PreviewProvider {
    static var previews: some View {
		SelectSourceView()
			.previewLayout(.sizeThatFits)
    }
}
