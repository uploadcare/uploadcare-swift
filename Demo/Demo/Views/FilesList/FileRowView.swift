//
//  FileRowView.swift
//  Demo
//
//  Created by Sergey Armodin on 27.03.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import SwiftUI
import Uploadcare

struct FileRowView: View {
	var fileData: FileViewData
	
	@State private var image: UIImage?
	
    var body: some View {
		NavigationLink(destination: FileView(fileData: fileData)) {
			HStack {
				if fileData.file.isImage {
					if self.image != nil {
						Image(uiImage: self.image!)
							.frame(width: 30, height: 30, alignment: .center)
					} else {
						Image(systemName: "photo.fill")
							.frame(width: 30, height: 30, alignment: .center)
					}
				} else if fileData.file.videoInfo != nil {
					Image(systemName: "video.fill")
						.frame(width: 30, height: 30, alignment: .center)
				} else {
					Image(systemName: "doc.fill")
						.frame(width: 30, height: 30, alignment: .center)
				}
				VStack(alignment: .leading) {
					Text(fileData.file.originalFilename).font(.headline)
					Text("size: \(fileData.file.size / 1024) kb").font(.subheadline)
				}
			}
		}.onAppear {
			if self.fileData.file.isImage {
				self.loadImage()
			}
		}
    }
	
	private func loadImage() {
		guard let imageUrl = self.fileData.file.originalFileUrl, var url = URL(string: imageUrl) else { return }
		var str = url.deletingLastPathComponent().absoluteString
		str = str + "-/preview/30x30/-/crop"
		
//		DLog(str)
		
		url = URL(string: str)!
		
		DispatchQueue.global(qos: .utility).async {
			guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return }
			
			let image = UIImage(data: data)
			DispatchQueue.main.async {
				withAnimation {
					self.image = image
				}
			}
		}
	}
}

struct FileRowView_Previews: PreviewProvider {
    static var previews: some View {
		#if DEBUG
		FileRowView(fileData: testFileViewData)
			.previewLayout(.sizeThatFits)
		#endif
    }
}

#if DEBUG
let testFile = File(
	size: 54306,
	uuid: "d1a13e8a-eb9a-4782-b828-e561adad2cf1",
	originalFilename: "random_file_name.jpg",
	mimeType: "image/jpeg",
	isImage: true,
	isReady: true,
	datetimeRemoved: nil,
	datetimeStored: nil,
	datetimeUploaded: Date(),
	originalFileUrl: "https://ucarecdn.com/d1a13e8a-eb9a-4782-b828-e561adad2cf1/random_file_name.jpg",
	url: "https://api.uploadcare.com/files/d1a13e8a-eb9a-4782-b828-e561adad2cf1/",
	source: nil,
	variations: nil,
	imageInfo: ImageInfo(
		height: 2002,
		width: 3000,
		geoLocation: nil,
		datetimeOriginal: nil,
		format: "JPEG",
		colorMode: .RGB,
		dpi: [72, 72],
		orientation: 1,
		sequence: false
	),
	videoInfo: nil
)
let testFileViewData = FileViewData(file: testFile)
#endif
