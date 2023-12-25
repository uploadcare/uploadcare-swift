//
//  DocumentPicker.swift
//
//
//  Created by Sergei Armodin on 25.12.2023.
//

#if os(iOS)
import SwiftUI
import UniformTypeIdentifiers

@available(iOS 13.0, *)
public struct DocumentPicker: UIViewControllerRepresentable {

	@Environment(\.presentationMode)
	private var presentationMode
	let onDocumentsPicked: ([URL]) -> Void

	public init(onDocumentsPicked: @escaping ([URL]) -> Void) {
		self.onDocumentsPicked = onDocumentsPicked
	}

	final public class Coordinator: NSObject, UINavigationControllerDelegate, UIDocumentPickerDelegate {
		@Binding
		private var presentationMode: PresentationMode
		private let onDocumentsPicked: ([URL]) -> Void

		init(presentationMode: Binding<PresentationMode>,
			 onDocumentsPicked: @escaping ([URL]) -> Void) {
			_presentationMode = presentationMode
			self.onDocumentsPicked = onDocumentsPicked
		}

		public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
		}

		public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
			onDocumentsPicked(urls)
		}
	}

	public func makeCoordinator() -> Coordinator {
		return Coordinator(presentationMode: presentationMode, onDocumentsPicked: onDocumentsPicked)
	}

	public func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
		let documentPicker: UIDocumentPickerViewController
		if #available(iOS 14.0, *) {
			documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.data, .image])
		} else {
			documentPicker = UIDocumentPickerViewController()
		}
		documentPicker.delegate = context.coordinator
		documentPicker.allowsMultipleSelection = true
		return documentPicker
	}

	public func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: UIViewControllerRepresentableContext<DocumentPicker>) {}
}
#endif
