//
//  FileRowView.swift
//  Demo
//
//  Created by Sergey Armodin on 27.03.2020.
//  Copyright © 2020 Sergei Armodin. All rights reserved.
//

import SwiftUI
import Uploadcare

struct FileRowView: View {
	var fileData: FileViewData
	
    var body: some View {
		NavigationLink(destination: FileView(fileData: fileData)) {
			HStack {
				if fileData.file.isImage {
					Image(systemName: "photo.fill")
				} else if fileData.file.videoInfo != nil {
					Image(systemName: "video.fill")
				} else {
					Image(systemName: "doc.fill")
				}
				VStack(alignment: .leading) {
					Text(fileData.file.originalFilename).font(.headline)
					Text("size: \(fileData.file.size / 1024) kb").font(.subheadline)
				}
			}
		}
    }
}

struct FileRowView_Previews: PreviewProvider {
    static var previews: some View {
		FileRowView(fileData: testFileViewData)
			.previewLayout(.sizeThatFits)
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
	rekognitionInfo: nil,
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
