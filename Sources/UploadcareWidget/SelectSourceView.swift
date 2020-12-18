//
//  SelectSourceView.swift
//  
//
//  Created by Sergey Armodin on 18.12.2020.
//

#if canImport(SwiftUI)
import SwiftUI

struct Config {
	static let baseUrl: String = "https://social.uploadcare.com"
}

class SocialSource: Identifiable {
	enum Source: String, CaseIterable {
		case facebook
		case instagram
		case vk
	}
	
	var id = UUID()
	let source: Source
	var title: String {
		switch self.source {
		case .facebook:
			return "Facebook"
		case .instagram:
			return "Instagram"
		case .vk:
			return "VK"
		}
	}
	
	var url: URL {
		return URL(string: Config.baseUrl + "/window3/" + source.rawValue)!
	}
	
	internal init(id: UUID = UUID(), source: SocialSource.Source) {
		self.id = id
		self.source = source
	}
}

@available(iOS 13.0.0, OSX 10.15.0, *)
struct SelectSourceView: View {
	let sources: [SocialSource] = {
		var arr: [SocialSource] = []
		SocialSource.Source.allCases.forEach({ arr.append(SocialSource(source: $0)) })
		return arr
	}()
	
	var body: some View {
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
}

@available(iOS 13.0.0, OSX 10.15.0, *)
struct SelectSourceView_Previews: PreviewProvider {
    static var previews: some View {
		SelectSourceView()
			.previewLayout(.sizeThatFits)
    }
}
#endif
