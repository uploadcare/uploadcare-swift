//
//  FilesLIstView.swift
//  
//
//  Created by Sergei Armodin on 26.01.2021.
//

import SwiftUI

@available(iOS 13.0.0, OSX 10.15.0, *)
struct FilesLIstView: View {
	@Environment(\.presentationMode) var presentation
	@ObservedObject var viewModel: FilesLIstViewModel
	@State var chunk: [String: String] = [:]
	
	var body: some View {
		List() {
			Section {
				ForEach(0 ..< self.viewModel.source.chunks.count) { index in
					let chunk = self.viewModel.source.chunks[index]
					HStack(spacing: 8) {
						Text("✓")
						Text(chunk.keys.first ?? "")
					}
				}
			}

			Section {
				ForEach(self.viewModel.currentChunk?.things ?? []) { thing in
					if thing.action?.action == .open_path {
						OpenPathView(thing: thing)
					} else {
						HStack {
							Text(thing.title)
						}
					}
				}
			}
		}
		.onAppear {
			self.chunk = self.viewModel.source.chunks.first!
			viewModel.getSourceChunk(self.chunk)
		}
		.navigationBarTitle(Text(viewModel.source.title))
		.navigationBarItems(trailing: Button("Logout") {
			self.viewModel.logout()
			self.presentation.wrappedValue.dismiss()
		})
    }
}

@available(iOS 13.0.0, OSX 10.15.0, *)
struct FilesLIstView_Previews: PreviewProvider {
    static var previews: some View {
		FilesLIstView(
			viewModel: FilesLIstViewModel(source: SocialSource(source: .vk), cookie: "")
		)
    }
}
