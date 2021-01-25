//
//  SelectSourceView.swift
//  
//
//  Created by Sergey Armodin on 18.12.2020.
//

import SwiftUI

struct Config {
	static let baseUrl: String = "https://social.uploadcare.com"
}

@available(iOS 13.0.0, OSX 10.15.0, *)
public struct SelectSourceView: View {
	let sources: [SocialSource] = {
		var arr: [SocialSource] = []
		SocialSource.Source.allCases.forEach({ arr.append(SocialSource(source: $0)) })
		return arr
	}()
	
	public var body: some View {
		VStack(alignment: .leading) {
			Text("Select Source")
				.font(.title)
			
			List {
				ForEach(self.sources) { source in
					Text(source.title)
				}
			}
		}
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
