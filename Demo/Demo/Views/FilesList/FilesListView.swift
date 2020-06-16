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
	private var list: FilesList?
	var uploadcare: Uploadcare? {
		didSet {
			self.list = uploadcare?.listOfFiles()
		}
	}
	
	init(files: [FileViewData]) {
        self.files = files
    }
	
	func load(_ completionHandler: @escaping (FilesList?, RESTAPIError?) -> Void) {
		let query = PaginationQuery()
			.limit(5)
            .ordering(.dateTimeUploadedDESC)
		
		self.list?.get(withQuery: query, completionHandler)
	}
	
	func loadNext(_ completionHandler: @escaping (FilesList?, RESTAPIError?) -> Void) {
		self.list?.nextPage(completionHandler)
	}
}


struct FilesListView: View {
    enum UploadState {
        case uploading
        case paused
        case notRunning
    }
    
	@ObservedObject private var filesListStore: FilesListStore = FilesListStore(files: [])
    
    @State private var isLoading: Bool = true
    @State private var isUploading: Bool = false
	@State private var isShowingAlert = false
    @State private var isShowingAddFilesAlert = false
    @State private var isShowingImagePicker = false
	@State private var isShowingDocumentPicker = false
	
    @State private var alertMessage = ""
    @State private var inputImage: UIImage?
    @State private var progressValue: Float = 0.0
    @State private var task: UploadTaskResumable?
    
    @State private var uploadState: UploadState = .notRunning
	
	@EnvironmentObject var api: APIStore
    
    private var uploadingFile: UploadedFile?	
	
    var body: some View {
        ZStack {
            VStack {
                HStack {
					// Progress bar
                    ProgressBar(value: $progressValue)
                        .frame(height: 20)
                        .frame(maxWidth: 200)
                    
                    if self.uploadState == .uploading {
                        Button(action: {
                            self.toggleUpload()
                        }) {
                            Image(systemName: "pause.fill")
                        }
                    }
                    if self.uploadState == .paused {
                        Button(action: {
                            self.toggleUpload()
                        }) {
                            Image(systemName: "play.fill")
                        }
                    }
                }.opacity(self.isUploading ? 1 : 0)
                
                List {
                    Section {
                        ForEach(self.filesListStore.files) { file in
                            FileRowView(fileData: file)
							.onAppear {
								if file.file.uuid == self.filesListStore.files.last?.file.uuid {
									self.loadMoreIfNeed()
								}
							}
                        }.onDelete(perform: delete)
                    }
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
                    .default(Text("Photos"), action: { self.isShowingImagePicker.toggle() }),
					.default(Text("Files"), action: { self.isShowingDocumentPicker.toggle() }),
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
		.sheet(isPresented: $isShowingImagePicker, onDismiss: loadImage) {
			ImagePicker(sourceType: .photoLibrary) { (imageUrl) in
				self.uploadFile(imageUrl)
			}
		}
		.sheet(isPresented: $isShowingDocumentPicker, onDismiss: loadImage) {
			DocumentPicker { (url) in
				self.uploadFile(url)
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
	
	func uploadFile(_ url: URL) {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch let error {
            print(error)
            return
        }
        
        self.progressValue = 0
        self.isUploading = true
        let filename = url.lastPathComponent
            
        if data.count < UploadAPI.multipartMinFileSize {
            self.performDirectUpload(filename: filename, data: data)
        } else {
            self.performMultipartUpload(filename: filename, fileUrl: url)
        }
    }
    
    func toggleUpload() {
        guard let task = self.task else { return }
        switch self.uploadState {
        case .uploading:
            task.pause()
            self.uploadState = .paused
        case .paused:
            task.resume()
            self.uploadState = .uploading
        default: break
        }
    }
	
	func loadMoreIfNeed() {
		self.isLoading = true
		filesListStore.loadNext { (list, error) in
			defer { self.isLoading = false }
			if let error = error {
				self.alertMessage = error.detail
				self.isShowingAlert.toggle()
				return print(error)
			}
			list?.results.forEach({ self.filesListStore.files.append(FileViewData( file: $0)) })
		}
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
		filesListStore.uploadcare = self.api.uploadcare
		filesListStore.load { (list, error) in
			defer { self.isLoading = false }
			if let error = error {
				self.alertMessage = error.detail
				self.isShowingAlert.toggle()
				return print(error)
			}
			self.filesListStore.files.removeAll()
			list?.results.forEach({ self.filesListStore.files.append(FileViewData( file: $0)) })
		}
	}
    
    func loadImage() {
//        guard let inputImage = inputImage else { return }
//        image = Image(uiImage: inputImage)
    }
}

// MARK: - Uploading
private extension FilesListView {
    func performDirectUpload(filename: String, data: Data) {
        let onProgress: (Double)->Void = { (progress) in
            self.progressValue = Float(progress)
        }
        self.api.uploadcare?.uploadAPI.upload(files: [filename: data], store: .store, onProgress, { (uploadData, error) in
            defer { self.isUploading = false }
            
            if let error = error {
                self.alertMessage = error.detail
                self.isShowingAlert.toggle()
                return print(error)
            }
            
            guard let uploadData = uploadData, let fileId = uploadData.first?.value else { return }
            
            self.insertFileByFileId(fileId)
            print(uploadData)
        })
    }
    
    func insertFileByFileId(_ fileId: String) {
        // getting file by uuid
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
    }
    
    func performMultipartUpload(filename: String, fileUrl: URL) {
        let onProgress: (Double)->Void = { (progress) in
            self.progressValue = Float(progress)
        }
        
        guard let fileForUploading = self.api.uploadcare?.uploadAPI.file(withContentsOf: fileUrl) else {
            assertionFailure("file not found")
            return
        }
        
        self.uploadState = .uploading
        self.task = fileForUploading.upload(withName: filename, onProgress, { (file, error) in
            defer {
                self.isUploading = false
                self.uploadState = .notRunning
                self.task = nil
            }
            
            if let error = error {
                print(error)
                return
            }
            
            guard let file = file else { return }
            self.insertFileByFileId(file.fileId)
            print(file)
        })
    }
}

// MARK: - Preview
struct FilesListView_Previews: PreviewProvider {
    static var previews: some View {
        let flist = FilesListView()
            .environmentObject(APIStore())
        
        return flist
    }
}
