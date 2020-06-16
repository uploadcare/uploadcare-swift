//
//  DocumentPicker.swift
//  Demo
//
//  Created by Sergey Armodin on 16.06.2020.
//  Copyright © 2020 Sergei Armodin. All rights reserved.
//

import SwiftUI

struct DocumentPicker: UIViewControllerRepresentable {
	@Environment(\.presentationMode)
    private var presentationMode
	
	let onDocumentPicked: (URL) -> Void
	
	final class Coordinator: NSObject, UINavigationControllerDelegate, UIDocumentPickerDelegate {
		@Binding
		private var presentationMode: PresentationMode
		private let onDocumentPicked: (URL) -> Void
		
		init(presentationMode: Binding<PresentationMode>,
			 onDocumentPicked: @escaping (URL) -> Void) {
			_presentationMode = presentationMode
			self.onDocumentPicked = onDocumentPicked
		}
		
		func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
		}
		
		func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
			onDocumentPicked(url)
		}
	}
	
	func makeCoordinator() -> Coordinator {
		return Coordinator(presentationMode: presentationMode, onDocumentPicked: onDocumentPicked)
	}
	
	func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
		let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.data"], in: .open)
		documentPicker.delegate = context.coordinator
		return documentPicker
	}

	func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: UIViewControllerRepresentableContext<DocumentPicker>) {
	}
}

struct DocumentPicker_Previews: PreviewProvider {
    static var previews: some View {
		DocumentPicker { (url) in
			
		}
    }
}
