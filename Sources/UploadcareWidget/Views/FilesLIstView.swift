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
	@State var isRoot: Bool
	@State var didLoad: Bool = false
	
	var body: some View {
		GeometryReader { geometry in
			List() {
				if self.isRoot {
					Section {
						ForEach(0 ..< self.viewModel.source.chunks.count) { index in
							let chunk = self.viewModel.source.chunks[index]
							HStack(spacing: 8) {
								Text("✓")
								Text(chunk.keys.first ?? "")
							}
						}
					}
				}

				let things = self.viewModel.currentChunk?.things ?? []
				let hasFolders = things.filter({ $0.action?.action == .open_path }).count > 0
				let hasFiles = things.filter({ $0.action?.action == .select_file }).count > 0

				Section {
					if hasFolders {
						ForEach(things) { thing in
							let chunkPath = thing.action!.path?.chunks.last?.path_chunk ?? ""
							NavigationLink(destination: FilesLIstView(viewModel: self.viewModel.modelWithChunkPath(chunkPath), isRoot: false)) {
								OpenPathView(thing: thing)
							}
						}
					}
				}

				Section {
					if hasFiles {
						let cols = 4
						let num = things.count

						let dev = num / cols
						let rows = num % cols == 0 ? dev : dev + 1

						GridView(rows: rows, columns: cols) { (row, col) in
							let index = row * cols + col
							if index < num {
								let thing = things[index]
								SelectFileView(thing: thing, size: geometry.size.width / CGFloat(cols))
							}
						}
					}
				}
			}
		}
		.onAppear {
			guard !didLoad else { return }
			viewModel.getSourceChunk()
			self.didLoad = true
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
			viewModel: FilesLIstViewModel(source: SocialSource(source: .vk), cookie: "", chunkPath: ""), isRoot: true
		)
    }
}
