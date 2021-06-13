//
//  SwiftUIView.swift
//  
//
//  Created by Sergey Armodin on 16.02.2021.
//  Copyright © 2021 Uploadcare, Inc. All rights reserved.
//

import SwiftUI

@available(iOS 14.0.0, OSX 10.15.0, *)
struct SelectFileView: View {
	let thing: ChunkThing
	@State private var image: UIImage?
	let size: CGFloat
	
    var body: some View {
		if let url = URL(string: self.thing.thumbnail) {
			AsyncImage(
				url: url,
				placeholder: {
					Image(systemName: "doc.fill")
				},
				image: {
					Image(uiImage: $0)
						.resizable()
				}
			)
			.frame(width: size - 12, height: size - 12, alignment: .center)
			.aspectRatio(contentMode: .fill)
			.clipped()
		}
    }
}
