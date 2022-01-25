//
//  SwiftUIView.swift
//  
//
//  Created by Sergey Armodin on 16.02.2021.
//  Copyright © 2021 Uploadcare, Inc. All rights reserved.
//

import SwiftUI

#if os(iOS)
@available(iOS 14.0.0, *)
struct SelectFileView: View {
	// MARK: - Public properties
	let thing: ChunkThing
	let size: CGFloat

	// MARK: - Private properties
	@State private var image: UIImage?
	
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
			.aspectRatio(contentMode: .fill)
			.frame(width: size - 12, height: size - 12, alignment: .center)
			.clipped()
		}
    }
}
#endif
