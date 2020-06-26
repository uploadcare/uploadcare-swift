//
//  FileView.swift
//  Demo
//
//  Created by Sergey Armodin on 27.03.2020.
//  Copyright © 2020 Sergei Armodin. All rights reserved.
//

import SwiftUI
import Combine
import Uploadcare

class ImageStore: ObservableObject {
	@Published var image: UIImage?
	
    init(image: UIImage? = nil) {
        self.image = image
    }
}

struct RandomTransformator {
	static var sharp: [String] {
		let strength = (0...20).randomElement() ?? 0
		return ["sharp", "\(strength)"]
	}
	static var blur: [String] {
		let strength = (1...1000).randomElement() ?? 0
		return ["blur", "\(strength)"]
	}
	
	static var imageFilter: [String] {
		let name = [
		  "adaris",
		  "briaril",
		  "calarel",
		  "carris",
		  "cynarel",
		  "cyren",
		  "elmet",
		  "elonni",
		  "enzana",
		  "erydark",
		  "fenralan",
		  "ferand",
		  "galen",
		  "gavin",
		  "gethriel",
		  "iorill",
		  "iothari",
		  "iselva",
		  "jadis",
		  "lavra",
		  "misiara",
		  "namala",
		  "nerion",
		  "nethari",
		  "pamaya",
		  "sarnar",
		  "sedis",
		  "sewen",
		  "sorahel",
		  "sorlen",
		  "tarian",
		  "thellassan",
		  "varriel",
		  "varven",
		  "vevera",
		  "virkas",
		  "yedis",
		  "yllara",
		  "zatvel",
		  "zevcen"
		].randomElement() ?? "zevcen"
		
		let amount = (-100...200).randomElement() ?? 100
		return ["filter", "\(name)", "\(amount)"]
	}
	
	static var crop: [String] {
		let width = (100...1000).randomElement()!
		let height = (100...1000).randomElement()!
		
		return ["scale_crop", "\(width)x\(height)", "smart"]
	}
	
	static func getRandomTransformation(imageURL: URL) -> URL {
		let effects = [crop, imageFilter, blur, sharp]
		
		let randomNumber = (2..<effects.count).randomElement()!
		var newURL = imageURL
		
		for i in (0...randomNumber) {
			let effect = effects[i]
			
			newURL = newURL.appendingPathComponent("-")
			for el in effect {
				newURL = newURL.appendingPathComponent(el)
			}
		}
		return newURL
	}
}


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
						Text("\(self.fileData.file.originalFilename) \(self.fileData.file.datetimeStored != nil ? "[stored]" : "[not stored]")")
							.bold()
						
						
						
						if self.fileData.file.imageInfo?.width != nil && self.fileData.file.imageInfo?.height != nil {
							VStack(alignment: .leading) {
								Text("Size:").bold()
								Text("\(self.fileData.file.imageInfo!.width)x\(self.fileData.file.imageInfo!.height) | \(self.fileData.file.size / 1024) kb")
							}
						} else if self.fileData.file.videoInfo?.video.width != nil && self.fileData.file.videoInfo?.video.height != nil {
							VStack(alignment: .leading) {
								Text("Size:").bold()
								Text("\(self.fileData.file.videoInfo!.video.width)x\(self.fileData.file.videoInfo!.video.height) | \(self.fileData.file.size / 1024) kb")
							}
						} else {
							VStack(alignment: .leading) {
								Text("Size:")
									.bold()
								Text("\(self.fileData.file.size / 1024) kb")
							}
						}
						
						VStack(alignment: .leading) {
							Text("URL:")
								.bold()
							Text("\(self.imageUrl?.absoluteString ?? "")")
						}
						
						VStack(alignment: .leading) {
							Text("UUID:")
								.bold()
							Text("\(self.fileData.file.uuid)")
						}
						
						Text("Demo files are not stored and will be deleted after 24 hours")
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
			
			print(self.fileData.file)
			
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
						makeRandomTransformation()
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
		print(self.imageUrl)
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

struct FileView_Previews: PreviewProvider {
    static var previews: some View {
		NavigationView {
			FileView(fileData: testFileViewData)
		}
    }
}




