//
//  ImagePicker.swift
//  Demo
//
//  Created by Sergey Armodin on 25.05.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import SwiftUI

#if os(iOS)
@available(iOS 13.0, *)
struct ImagePicker: UIViewControllerRepresentable {

	@Environment(\.presentationMode)
	private var presentationMode

	let sourceType: UIImagePickerController.SourceType
	let onImagePicked: (URL) -> Void

	final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

		@Binding
		private var presentationMode: PresentationMode
		private let sourceType: UIImagePickerController.SourceType
		private let onImagePicked: (URL) -> Void
		
		init(presentationMode: Binding<PresentationMode>,
			 sourceType: UIImagePickerController.SourceType,
			 onImagePicked: @escaping (URL) -> Void) {
			_presentationMode = presentationMode
			self.sourceType = sourceType
			self.onImagePicked = onImagePicked
		}

		func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
			defer { presentationMode.dismiss() }
			
			if self.sourceType == .photoLibrary || self.sourceType == .savedPhotosAlbum {
				let imageUrl = info[.imageURL] as! URL
				onImagePicked(imageUrl)
			}
			
			if self.sourceType == .camera {
				guard let image = info[.originalImage] as? UIImage else { return }
				let data = image.jpegData(compressionQuality: 1.0)
				let tempDirectoryURL = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)
				let targetURL = tempDirectoryURL.appendingPathComponent("\(UUID()).jpeg")
				
				do {
					try data?.write(to: targetURL)
				} catch let error {
					DLog(error.localizedDescription)
				}
				
				onImagePicked(targetURL)
			}
		}
		
		func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
			presentationMode.dismiss()
		}
	}

	func makeCoordinator() -> Coordinator {
		return Coordinator(presentationMode: presentationMode,
						   sourceType: sourceType,
						   onImagePicked: onImagePicked)
	}

	func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
		let picker = UIImagePickerController()
		picker.sourceType = sourceType
		picker.delegate = context.coordinator
		return picker
	}

	func updateUIViewController(_ uiViewController: UIImagePickerController,
								context: UIViewControllerRepresentableContext<ImagePicker>) {

	}

}

@available(iOS 13.0.0, *)
struct ImagePicker_Previews: PreviewProvider {
	@State private var isShowingImagePicker = false
	
	static var previews: some View {
		ZStack {
			ImagePicker(sourceType: .photoLibrary) { (_) in
			}
		}
	}
}
#endif
