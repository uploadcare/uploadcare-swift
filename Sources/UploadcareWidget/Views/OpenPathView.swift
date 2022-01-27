//
//  OpenPathView.swift
//  
//
//  Created by Sergey Armodin on 16.02.2021.
//  Copyright © 2021 Uploadcare, Inc. All rights reserved.
//

import SwiftUI

#if os(iOS)
@available(iOS 13.0.0, OSX 10.15.0, *)
struct OpenPathView: View {
	let thing: ChunkThing
	@State private var image: UIImage?

	var body: some View {
		HStack {
			if let image = self.image {
				Image(uiImage: image)
					.resizable()
					.aspectRatio(contentMode: .fill)
					.frame(width: 45, height: 45, alignment: .center)
					.clipped()
			} else {
				Image(systemName: "folder.fill")
					.frame(width: 45, height: 45, alignment: .center)
			}

			Text(self.thing.title)
		}.onAppear {
			guard let url = URL(string: self.thing.thumbnail) else { return }

			DispatchQueue.global(qos: .utility).async {
				guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return }

				let image = UIImage(data: data)
				DispatchQueue.main.async {
					withAnimation {
						self.image = image
					}
				}
			}
		}
	}
}
#endif
