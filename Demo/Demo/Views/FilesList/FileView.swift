//
//  FileView.swift
//  Demo
//
//  Created by Sergey Armodin on 27.03.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import SwiftUI
import Uploadcare

struct FileView: View {
	var fileData: FileViewData

	@State private var isLoading: Bool = true
	@State private var imageUrl: URL?
    @State private var image: UIImage?
	
    var body: some View {
		GeometryReader { geometry in
			ZStack(alignment: .top) {
				List {
					if let image = self.image {
						Image(uiImage: image)
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
                            .font(.title)
                        
                        VStack(alignment: .leading) {
                            Text("Size:")
                                .font(.headline)
                            
                            if let image = self.fileData.file.contentInfo?.image {
                                Text("\(image.width)x\(image.height) | \(self.fileData.file.readableSize)")
                            } else if let video = self.fileData.file.contentInfo?.video?.video.first {
                                Text("\(video.width)x\(video.height) | \(self.fileData.file.readableSize)")
                            } else {
                                Text("\(self.fileData.file.readableSize)")
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
                
				ProgressView()
					.progressViewStyle(.circular)
					.padding()
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
        Task {
            var image: UIImage?
            do {
                let (imageData, _) = try await URLSession.shared.data(from: self.imageUrl!)
                image = UIImage(data: imageData)
            } catch {
                DLog(error.localizedDescription)
            }
            
            await MainActor.run {
                withAnimation {
                    self.isLoading = false
                    self.image = image
                }
            }
        }
	}
}

extension File {
    var readableSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB] // You can specify the units you want
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
}
