//
//  FilesListView.swift
//  
//
//  Created by Sergei Armodin on 26.01.2021.
//  Copyright © 2021 Uploadcare, Inc. All rights reserved.
//

#if os(iOS)
import SwiftUI

@available(iOS 14.0.0, *)
struct FilesListView: View {
	@Environment(\.presentationMode) var presentation
	@StateObject var viewModel: FilesListViewModel
	@State var isRoot: Bool
	@State var didLoad: Bool = false
	@State var currentChunk: String = ""
	@State var isLoading: Bool = true
	@State var fileUploadedMessageVisible: Bool = false

	@State private var alertVisible: Bool = false
	@State private var pathsToUpload: [String] = []
	
	var body: some View {
		GeometryReader { geometry in
			ZStack {
				List() {
					// Root chunks
					if self.isRoot {
						Section {
							ForEach(Array(self.viewModel.source.chunks.enumerated()), id: \.element) { index, chunk in
								let chunkName = chunk.key
								let chunkValue = chunk.value

								let isCurrent = (index == 0 && self.currentChunk.isEmpty) || (chunkValue == self.currentChunk)

								HStack(spacing: 8) {
									Text("✓")
										.opacity(isCurrent ? 1 : 0)
									Text(chunkName)
								}.onTapGesture {
									self.viewModel.chunkPath = chunk.value
									self.isLoading = true
									Task {
										try await self.viewModel.getSourceChunk()
										await MainActor.run {
											self.isLoading = false
											self.currentChunk = chunk.value
										}
									}
								}
							}
						}
					}

					// Folders (albums)
					Section {
						ForEach(self.viewModel.folders) { thing in
							let chunkPath = thing.action!.path?.chunks.last?.path_chunk ?? ""
							let viewModel = self.viewModel.modelWithChunkPath(chunkPath)
							NavigationLink(destination: FilesListView(viewModel: viewModel, isRoot: false)) {
								OpenPathView(thing: thing)
							}
						}
					}

					// Files
					Section {
						if self.viewModel.files.count > 0 {
							let cols = 4
							let num = self.viewModel.files.count

							let dev = num / cols
							let rows = num % cols == 0 ? dev : dev + 1

							GridView(rows: rows, columns: cols) { (row, col) in
								let index = row * cols + col
								if index < num {
									let thing = self.viewModel.files[index]
									let size = geometry.size.width / CGFloat(cols)

									ZStack {
										SelectFileView(thing: thing, size: size)
											.onTapGesture {
												if let path = thing.action?.url {
													self.pathsToUpload.contains(path) == true
													? self.pathsToUpload.removeAll(where: { $0 == path })
													: self.pathsToUpload.append(path)
												}
											}

										Image(systemName: "checkmark.circle.fill")
											.resizable()
											.frame(width: size / 3, height: size / 3, alignment: .center)
											.opacity(self.pathsToUpload.contains(thing.action?.url ?? "") ? 1 : 0)
									}
								}
							}
						}
					}

					// Pagination
					if self.viewModel.currentChunk?.next_page != nil {
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

				ActivityIndicator(isAnimating: .constant(true), style: .large)
					.padding(.all)
					.background(Color.gray)
					.cornerRadius(16)
					.opacity(self.isLoading ? 1 : 0)

				Text(self.pathsToUpload.count > 1 ? "Files uploaded" : "File uploaded" )
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
		.navigationBarItems(trailing:
			HStack {
				if self.pathsToUpload.count > 0 {
					Button("Upload") {
						self.pathsToUpload.forEach { path in
							Task {
								try await self.viewModel.uploadFileFromPath(path)
							}
						}
						self.pathsToUpload.removeAll()

						withAnimation {
							self.fileUploadedMessageVisible = true
						}

						DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
							withAnimation {
								self.fileUploadedMessageVisible = false
							}
						}
					}
				} else {
					Button("Logout") {
						self.alertVisible = true
					}
				}
			}
		)
    }

	func loadData() {
		guard !didLoad else { return }
		isLoading = true
		Task {
			try await self.viewModel.getSourceChunk()
			DLog("loaded first page")
			await MainActor.run {
				if let firstChunk = viewModel.source.chunks.first {
					currentChunk = firstChunk.value
				}
				self.isLoading = false
			}
		}
		didLoad = true
	}

	func loadMore() {
		guard let nextPage = self.viewModel.currentChunk?.next_page,
			  let path = nextPage.chunks.first?.path_chunk else { return }
		isLoading = true

		Task {
			try await self.viewModel.loadMore(path: path)
			DLog("loaded next page")
			await MainActor.run {
				self.isLoading = false
			}
		}
	}
}

@available(iOS 13.0.0, macOS 10.15.0, *)
struct FilesLIstView_Previews: PreviewProvider {
    static var previews: some View {
		Text("")
//		FilesLIstView(
//			viewModel: FilesLIstViewModel(source: SocialSource(source: .vk), cookie: "", chunkPath: ""), isRoot: true
//		)
    }
}
#endif
