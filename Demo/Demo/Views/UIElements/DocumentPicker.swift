//
//  DocumentPicker.swift
//  Demo
//
//  Created by Sergey Armodin on 16.06.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
	@Environment(\.presentationMode)
    private var presentationMode
	
	let onDocumentsPicked: ([URL]) -> Void
	
	final class Coordinator: NSObject, UINavigationControllerDelegate, UIDocumentPickerDelegate {
		@Binding
		private var presentationMode: PresentationMode
		private let onDocumentsPicked: ([URL]) -> Void
		
		init(presentationMode: Binding<PresentationMode>,
			 onDocumentsPicked: @escaping ([URL]) -> Void) {
			_presentationMode = presentationMode
			self.onDocumentsPicked = onDocumentsPicked
		}
		
		func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
		}
		
		func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
			onDocumentsPicked(urls)
		}
	}
	
	func makeCoordinator() -> Coordinator {
		return Coordinator(presentationMode: presentationMode, onDocumentsPicked: onDocumentsPicked)
	}
	
	func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
		let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.data, .image])
		documentPicker.delegate = context.coordinator
		documentPicker.allowsMultipleSelection = true
		return documentPicker
	}

	func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: UIViewControllerRepresentableContext<DocumentPicker>) {
	}
}

struct DocumentPicker_Previews: PreviewProvider {
    static var previews: some View {
		DocumentPicker { (urls) in
			
		}
    }
}
