//
//  FilesListView.swift
//  Demo
//
//  Created by Sergey Armodin on 27.03.2020.
//  Copyright © 2020 Sergei Armodin. All rights reserved.
//

import SwiftUI
import Combine
import Uploadcare


class FilesListStore: ObservableObject {
	@Published var files: [FileViewData] = []
	
    init(files: [FileViewData]) {
        self.files = files
    }
}


struct FilesListView: View {
	@State private var isLoading: Bool = true
	
	@ObservedObject private var filesListStore: FilesListStore = FilesListStore(files: [])
	
	@State private var isShowingAlert = false
    @State private var isShowingAddFilesAlert = false
    @State private var showingImagePicker = false
	@State private var alertMessage = ""
    
    @State private var inputImage: UIImage?
	
	@EnvironmentObject var api: APIStore
	
    var body: some View {
        ZStack {
            List {
                Section {
                    ForEach(self.filesListStore.files) { file in
                        FileRowView(fileData: file)
                    }.onDelete(perform: delete)
                }
            }
            VStack {
                ActivityIndicator(isAnimating: .constant(true), style: .large)
                Text("Loading...")
            }.opacity(self.isLoading ? 1 : 0)
        }
        .onAppear {
            self.loadData()
        }
        .actionSheet(isPresented: $isShowingAddFilesAlert, content: { ActionSheet(
                title: Text("Select source"),
                message: Text(""),
                buttons: [
                    .default(Text("Photos"), action: { self.showingImagePicker.toggle() }),
                    .default(Text("Files"), action: { print("files") }),
                    .cancel()
                ]
            )
        })
        .alert(isPresented: $isShowingAlert) {
            Alert(
                title: Text("Error"),
                message: Text(self.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
            ImagePicker(sourceType: .photoLibrary) { (imageUrl) in
                self.uploadImage(imageUrl)
            }
        }
        .navigationBarItems(trailing:
            HStack {
                Button(
                    action: { self.isShowingAddFilesAlert.toggle() },
                    label: { Text("Add") }
                )
                EditButton()
            }
            
        )
        .navigationBarTitle(Text("List of files"))
	}
	
    func uploadImage(_ imageUrl: URL) {
        let data: Data
        do {
            data = try Data(contentsOf: imageUrl)
        } catch let error {
            print(error)
            return
        }
        
        let filename = imageUrl.lastPathComponent
        
        let onProgress: (Double)->Void = { (progress) in
            print("progress: \(progress)")
        }
        
        if data.count < UploadAPI.multipartMinFileSize {
            // using direct upload
            self.api.uploadcare?.uploadAPI.upload(files: [filename: data], store: .store, onProgress, { (uploadData, error) in
                if let error = error {
                    self.alertMessage = error.detail
                    self.isShowingAlert.toggle()
                    return print(error)
                }
                guard let uploadData = uploadData, let fileId = uploadData.first?.value else { return }
                self.api.uploadcare?.fileInfo(withUUID: fileId, { (file, error) in
                    if let error = error {
                        self.alertMessage = error.detail
                        self.isShowingAlert.toggle()
                        return print(error)
                    }
                    guard let file = file else { return }
                    let viewData = FileViewData(file: file)
                    self.filesListStore.files.insert(viewData, at: 0)
                })
                
                print(uploadData)
            })
            
            return
        }
        
        guard let fileForUploading = self.api.uploadcare?.uploadAPI.file(withContentsOf: imageUrl) else {
            assertionFailure("file not found")
            return
        }
        
        
        var task: UploadTaskResumable?
        task = fileForUploading.upload(withName: "Mona_Lisa_big.jpg", onProgress, { (file, error) in
            if let error = error {
                print(error)
                return
            }
            print(file ?? "")
        })
        
//        let data: Data
//        do {
//            data = try Data(contentsOf: imageUrl)
//        } catch let error {
//            print(error)
//            return
//        }
//        let fileName = imageUrl.lastPathComponent
//
//        let fileForUploading = self.api.uploadcare?.uploadAPI.file(fromData: data)
//
//        let onProgress: (Double)->Void = { (progress) in
//            print("progress: \(progress)")
//        }
//
//        fileForUploading?.upload(withName: fileName, onProgress, { (file, error) in
//            if let error = error { return print(error) }
//
//            print(file ?? "")
//        })
    }
    
	func delete(at offsets: IndexSet) {
        offsets.forEach { (index) in
            let fileView = filesListStore.files[index]
            let uuid = fileView.file.uuid
            
            self.api.uploadcare?.deleteFile(withUUID: uuid, { (_, error) in
                if let error = error {
                    print(error)
                }
            })
        }
        
		filesListStore.files.remove(atOffsets: offsets)
	}
	
	func loadData() {
		let query = PaginationQuery()
			.limit(100)
            .ordering(.dateTimeUploadedDESC)
		self.api.uploadcare?.listOfFiles(withQuery: query, { (list, error) in
			defer { self.isLoading = false }
			if let error = error {
				self.alertMessage = error.detail
				self.isShowingAlert.toggle()
				return print(error)
			}
			self.filesListStore.files.removeAll()
			list?.results.forEach({ self.filesListStore.files.append(FileViewData( file: $0)) })
		})
	}
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
//        image = Image(uiImage: inputImage)
    }
}

struct ImagePicker: UIViewControllerRepresentable {

    @Environment(\.presentationMode)
    private var presentationMode

    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (URL) -> Void

    final class Coordinator: NSObject,
    UINavigationControllerDelegate,
    UIImagePickerControllerDelegate {

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
struct FilesListView_Previews: PreviewProvider {
    static var previews: some View {
        let flist = FilesListView()
        return flist
    }
}
