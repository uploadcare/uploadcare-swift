//
//  SwiftUIView.swift
//  
//
//  Created by Sergey Armodin on 16.02.2021.
//  Copyright © 2021 Uploadcare, Inc. All rights reserved.
//

#if !os(tvOS)
#if canImport(SwiftUI)
import SwiftUI
#endif

@available(iOS 13.0.0, macOS 10.15.0, watchOS 6.0, *)
struct GridView<Content: View>: View {
	let rows: Int
	let columns: Int
	let content: (Int, Int) -> Content

	var body: some View {
		VStack(alignment: .leading, spacing: 8, content: {
			ForEach(0 ..< rows, id: \.self) { row in
				HStack(spacing: 8) {
					ForEach(0 ..< columns, id: \.self) { column in
						content(row, column)
					}
				}
			}
		})
	}

	init(rows: Int, columns: Int, @ViewBuilder content: @escaping (Int, Int) -> Content) {
		self.rows = rows
		self.columns = columns
		self.content = content
	}
}
#endif
