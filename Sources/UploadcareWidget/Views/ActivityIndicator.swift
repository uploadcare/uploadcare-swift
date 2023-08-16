//
//  ActivityIndicator.swift
//  Demo
//
//  Created by Sergey Armodin on 27.03.2020.
//  Copyright © 2021 Uploadcare, Inc. All rights reserved.
//

#if os(iOS)
import SwiftUI

@available(iOS 13.0.0, *)
struct ActivityIndicator: UIViewRepresentable {

	@Binding var isAnimating: Bool
	let style: UIActivityIndicatorView.Style

	func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
		let view = UIActivityIndicatorView(style: style)
		view.hidesWhenStopped = true
		return view
	}

	func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
		isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
	}
}

@available(iOS 13.0.0, *)
struct ActivityIndicator_Previews: PreviewProvider {
	static var previews: some View {
		ActivityIndicator(isAnimating: .constant(true), style: .large)
			.previewLayout(.sizeThatFits)
	}
}
#endif
