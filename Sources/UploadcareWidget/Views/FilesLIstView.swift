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
	@State var currentChunk: String = ""
	@State var isLoading: Bool = true
	@State private var alertVisible: Bool = false
	
	var body: some View {
		GeometryReader { geometry in
			ZStack {
				List() {
					if self.isRoot {
						Section {
							ForEach(0 ..< self.viewModel.source.chunks.count) { index in
								let chunk = self.viewModel.source.chunks[index]
								let chunkName = chunk.keys.first ?? ""
								let chunkValue = chunk.values.first ?? ""
								let isCurrent = (index == 0 && self.currentChunk.isEmpty) || (chunkValue == self.currentChunk)
								HStack(spacing: 8) {
									Text("✓")
										.opacity(isCurrent ? 1 : 0)
									Text(chunkName)
								}.onTapGesture {
									if let value = chunk.values.first {
										self.viewModel.chunkPath = value
										self.isLoading = true
										self.viewModel.getSourceChunk {
											self.isLoading = false
											self.currentChunk = value
										}
									}
								}
							}
						}
					}

					let things = self.viewModel.currentChunk?.things ?? []

					let folders = things.filter({ $0.obj_type == "album" })
					let files = things.filter({ $0.obj_type != "album" })
					
					Section {
						if folders.count > 0 {
							ForEach(folders) { thing in
								let chunkPath = thing.action!.path?.chunks.last?.path_chunk ?? ""
								NavigationLink(destination: FilesLIstView(viewModel: self.viewModel.modelWithChunkPath(chunkPath), isRoot: false)) {
									OpenPathView(thing: thing)
								}
							}
						}
					}

					Section {
						if files.count > 0 {
							let cols = 4
							let num = files.count

							let dev = num / cols
							let rows = num % cols == 0 ? dev : dev + 1

							GridView(rows: rows, columns: cols) { (row, col) in
								let index = row * cols + col
								if index < num {
									let thing = files[index]
									SelectFileView(thing: thing, size: geometry.size.width / CGFloat(cols))
										.onTapGesture {
											if let path = thing.action?.url {
												self.viewModel.uploadFileFromPath(path)
											}
										}
								}
							}
						}
					}
				}
				.listStyle(GroupedListStyle())

				ActivityIndicator(isAnimating: .constant(true), style: .large)
					.padding(.all)
					.opacity(self.isLoading ? 1 : 0)
			}
		}
		.onAppear {
			guard !didLoad else { return }
			self.isLoading = true
			viewModel.getSourceChunk {
				if let firstChunk = self.viewModel.source.chunks.first {
					self.currentChunk = firstChunk.values.first ?? ""
				}
				self.isLoading = false
			}
			self.didLoad = true
		}
		.alert(isPresented: $alertVisible) {
			Alert(
				title: Text("Logout"),
				message: Text("Are you sure?"),
				primaryButton: .default(Text("Logout"), action: {
					self.viewModel.logout()
					self.presentation.wrappedValue.dismiss()
				}),
				secondaryButton: .cancel())
		}
		.navigationBarTitle(Text(viewModel.source.title))
		.navigationBarItems(trailing: Button("Logout") {
			self.alertVisible = true
		})
    }
}

@available(iOS 13.0.0, OSX 10.15.0, *)
struct FilesLIstView_Previews: PreviewProvider {
    static var previews: some View {
		Text("")
//		FilesLIstView(
//			viewModel: FilesLIstViewModel(source: SocialSource(source: .vk), cookie: "", chunkPath: ""), isRoot: true
//		)
    }
}
