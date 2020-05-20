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


struct FileView: View {
	var fileData: FileViewData
	@ObservedObject private var imageStore: ImageStore = ImageStore()
	
	@State private var isLoading: Bool = true
	
    var body: some View {
		GeometryReader { geometry in
			ZStack(alignment: .top) {
				List {
					if self.imageStore.image != nil {
						Image(uiImage: self.imageStore.image!)
							.resizable()
							.aspectRatio(contentMode: .fit)
							.frame(maxWidth: .infinity, maxHeight: geometry.size.height / 2, alignment: .center)
							.clipped()
					}
					VStack(alignment: .leading, spacing: 8) {
						Text("\(self.fileData.file.originalFilename)").bold()
						Text("\(self.fileData.file.size / 1024) kb")
						Text("UUID: \(self.fileData.file.uuid)")
						if self.fileData.file.imageInfo?.width != nil && self.fileData.file.imageInfo?.height != nil {
							HStack {
								Text("Image size:").bold()
								Text("\(self.fileData.file.imageInfo!.width)x\(self.fileData.file.imageInfo!.height)")
							}
						}
						if self.fileData.file.videoInfo?.video.width != nil && self.fileData.file.videoInfo?.video.height != nil {
							HStack {
								Text("Video size:").bold()
								Text("\(self.fileData.file.videoInfo!.video.width)x\(self.fileData.file.videoInfo!.video.height)")
							}
						}
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
			guard let url = self.fileData.file.originalFileUrl,
				let imageUrl = URL(string: url) else { return }
			
			DispatchQueue.global(qos: .utility).async {
				guard let data = try? Data(contentsOf: imageUrl, options: .mappedIfSafe) else { return }
				let image = UIImage(data: data)
				DispatchQueue.main.async {
					withAnimation {
						self.isLoading = false
						self.imageStore.image = image
					}
				}
			}
		}
		.navigationBarTitle(Text(self.fileData.file.originalFilename))
	}
}

struct FileView_Previews: PreviewProvider {
    static var previews: some View {
		FileView(fileData: testFileViewData)
    }
}




