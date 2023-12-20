//
//  NeumorphicButtonStyle.swift
//  Demo
//
//  Created by Sergei Armodin on 21.12.2023.
//  Copyright © 2023 Uploadcare, Inc. All rights reserved.
//

import SwiftUI

struct NeumorphicButtonStyle: ButtonStyle {
	var bgColor: Color

	func makeBody(configuration: Self.Configuration) -> some View {
		configuration.label
			.padding(EdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 18))
			.background(
				ZStack {
					RoundedRectangle(cornerRadius: 10, style: .continuous)
						.blendMode(.overlay)
					RoundedRectangle(cornerRadius: 10, style: .continuous)
						.fill(bgColor)
				}
		)
			.scaleEffect(configuration.isPressed ? 0.95: 1)
			.foregroundColor(.primary)
	}
}
