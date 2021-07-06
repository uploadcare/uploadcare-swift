//
//  ImagePicker.swift
//  Demo
//
//  Created by Sergey Armodin on 25.05.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import SwiftUI

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
			if self.sourceType == .photoLibrary || self.sourceType == .savedPhotosAlbum {
				let imageUrl = info[.imageURL] as! URL
				
				onImagePicked(imageUrl)
				presentationMode.dismiss()
			}
			
			if self.sourceType == .camera {
				defer { presentationMode.dismiss() }
				
				guard let image = info[.originalImage] else { return }
				
				
				
				let imageUrl = info[.originalImage] as! URL
				
				onImagePicked(imageUrl)
				
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
