//
//  ImagePicker.swift
//  Demo
//
//  Created by Sergey Armodin on 25.05.2020.
//  Copyright © 2020 Sergei Armodin. All rights reserved.
//

import SwiftUI

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
			let imageUrl = info[UIImagePickerController.InfoKey.imageURL] as! URL
			
			onImagePicked(imageUrl)
			presentationMode.dismiss()
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

struct ImagePicker_Previews: PreviewProvider {
    static var previews: some View {
        ImagePicker(sourceType: .photoLibrary) { (_) in
        }
    }
}
