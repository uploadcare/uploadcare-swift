//
//  FileView.swift
//  Demo
//
//  Created by Sergey Armodin on 27.03.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import SwiftUI

struct FileView: View {
	var fileData: FileViewData
	@ObservedObject private var imageStore: ImageStore = ImageStore()
	
	@State private var isLoading: Bool = true
	@State private var imageUrl: URL?
	
    var body: some View {
		GeometryReader { geometry in
			ZStack(alignment: .top) {
				List {
					if self.imageStore.image != nil {
						Image(uiImage: self.imageStore.image!)
							.resizable()
							.aspectRatio(contentMode: .fit)
							.frame(
								maxWidth: .infinity,
								minHeight: geometry.size.height / 2.2,
								maxHeight: geometry.size.height / 2.2,
								alignment: .center
							)
							.clipped()
					}
					VStack(alignment: .leading, spacing: 12) {
						Text("\(self.fileData.file.originalFilename)")
							.bold()

						if let width = self.fileData.file.contentInfo?.image?.width, let height = self.fileData.file.contentInfo?.image?.height {
							VStack(alignment: .leading) {
								Text("Size:").bold()
								Text("\(width)x\(height) | \(self.fileData.file.size / 1024) kb")
							}
						} else if let width = self.fileData.file.contentInfo?.video?.video.first?.width, let height = self.fileData.file.contentInfo?.video?.video.first?.height {
							VStack(alignment: .leading) {
								Text("Size:").bold()
								Text("\(width)x\(height) | \(self.fileData.file.size / 1024) kb")
							}
						} else {
							VStack(alignment: .leading) {
								Text("Size:")
									.bold()
								Text("\(self.fileData.file.size / 1024) kb")
							}
						}
						
						if self.imageUrl?.absoluteString != nil {
							VStack(alignment: .leading) {
								Text("URL:")
									.bold()
								Text("\(self.imageUrl?.absoluteString ?? "")")
							}
						} else {
							VStack(alignment: .leading) {
								Text("URL:")
									.bold()
								Text("\(self.fileData.file.originalFileUrl ?? "")")
							}
						}
						
						
						VStack(alignment: .leading) {
							Text("UUID:")
								.bold()
							Text("\(self.fileData.file.uuid)")
						}
						
						VStack(alignment: .leading) {
							Text("Stored:")
								.bold()
							Text("\(self.fileData.file.datetimeStored != nil ? "true" : "false")")
						}
						
						Text("Demo files will be deleted after 24 hours")
							.font(.footnote)
					}.padding([.leading, .trailing], 8)
				}
				ActivityIndicator(isAnimating: .constant(true), style: .large)
					.padding(.all)
					.opacity(self.isLoading ? 1 : 0)
			}
		}
		.onAppear {
			UITableView.appearance().separatorStyle = .none
			
			DLog(self.fileData.file)
			
			guard self.fileData.file.isImage == true else {
				self.isLoading = false
				return
			}
			
			guard let urlString = self.fileData.file.originalFileUrl,
				let url = URL(string: urlString) else { return }
			
			self.imageUrl = url.deletingLastPathComponent()
			self.loadImage()
		}
		.navigationBarItems(trailing:
			HStack {
				if self.fileData.file.isImage == true {
					Button(action: {
						self.makeRandomTransformation()
					}) {
						Text("Random transformation")
					}
				}
			}
		)
		.navigationBarTitle("Image")
	}
	
	func makeRandomTransformation() {
		guard let urlString = self.fileData.file.originalFileUrl,
			let url = URL(string: urlString) else { return }
		let originalUrl = url.deletingLastPathComponent()
		
		self.imageUrl = RandomTransformator.getRandomTransformation(imageURL: originalUrl)
		DLog(self.imageUrl ?? "")
		isLoading.toggle()
		loadImage()
	}
	
	func loadImage() {
		DispatchQueue.global(qos: .utility).async {
			guard let data = try? Data(contentsOf: self.imageUrl!, options: .mappedIfSafe) else { return }
			let image = UIImage(data: data)
			DispatchQueue.main.async {
				withAnimation {
					self.isLoading = false
					self.imageStore.image = image
				}
			}
		}
	}
}
