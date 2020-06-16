//
//  ActivityIndicator.swift
//  Demo
//
//  Created by Sergey Armodin on 27.03.2020.
//  Copyright © 2020 Sergei Armodin. All rights reserved.
//

import SwiftUI

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

struct ActivityIndicator_Previews: PreviewProvider {
    static var previews: some View {
		ActivityIndicator(isAnimating: .constant(true), style: .large)
			.previewLayout(.sizeThatFits)
    }
}