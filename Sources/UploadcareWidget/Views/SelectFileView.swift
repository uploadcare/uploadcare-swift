//
//  SwiftUIView.swift
//  
//
//  Created by Sergey Armodin on 16.02.2021.
//

import SwiftUI

@available(iOS 13.0.0, OSX 10.15.0, *)
struct SelectFileView: View {
	let thing: ChunkThing
	@State private var image: UIImage?
	let size: CGFloat
	
    var body: some View {
		HStack(spacing: 0) {
			if let image = self.image {
				Image(uiImage: image)
					.resizable()
					.aspectRatio(contentMode: .fill)
					.frame(width: size - 12, height: size - 12, alignment: .center)
					.clipped()
			} else {
				Image(systemName: "doc.fill")
					.frame(width: size - 12, height: size - 12, alignment: .center)
			}
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
