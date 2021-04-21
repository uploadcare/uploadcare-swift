//
//  FilesLIstView.swift
//  
//
//  Created by Sergei Armodin on 26.01.2021.
//  Copyright © 2021 Uploadcare, Inc. All rights reserved.
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
	@State var fileUploadedMessageVisible: Bool = false
	@State private var alertVisible: Bool = false
	
	var body: some View {
		GeometryReader { geometry in
			ZStack {
				List() {
					// Root chunks
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
					let nextPage = self.viewModel.currentChunk?.next_page

					let folders = things.filter({ $0.obj_type == "album" })
					let files = things.filter({ $0.obj_type != "album" })

					// Folders (albums)
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

					// Files
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
												withAnimation {
													self.fileUploadedMessageVisible = true
												}

												DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
													withAnimation {
														self.fileUploadedMessageVisible = false
													}
												}
											}
										}
								}
							}
						}
					}

					// Pagination
					if nextPage != nil {
						Section {
							Button("Load more") {
								self.loadMore()
							}.onAppear {
								self.loadMore()
							}
						}
					}
				}
				.listStyle(GroupedListStyle())

				ActivityIndicator(isAnimating: .constant(true), style: .whiteLarge)
					.padding(.all)
					.background(Color.gray)
					.cornerRadius(16)
					.opacity(self.isLoading ? 1 : 0)

				Text("File uploaded")
					.font(.title)
					.padding(.all)
					.background(Color.gray)
					.foregroundColor(.white)
					.cornerRadius(16)
					.opacity(self.fileUploadedMessageVisible ? 1 : 0)
			}
		}
		.onAppear {
			self.loadData()
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

	func loadData() {
		guard !didLoad else { return }
		isLoading = true
		viewModel.getSourceChunk {
			DLog("loaded first page")
			if let firstChunk = viewModel.source.chunks.first {
				currentChunk = firstChunk.values.first ?? ""
			}
			self.isLoading = false
		}
		didLoad = true
	}

	func loadMore() {
		guard let nextPage = self.viewModel.currentChunk?.next_page,
			  let path = nextPage.chunks.first?.path_chunk else { return }
		isLoading = true
		viewModel.loadMore(path: path) {
			DLog("loaded next page")
			self.isLoading = false
		}
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
