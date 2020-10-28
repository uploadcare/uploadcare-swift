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

struct FilesListView: View {
	@ObservedObject private var filesListStore: FilesListStore = FilesListStore(files: [])
    
    @State private var isLoading: Bool = true
	@State private var isShowingAlert = false
    
	@State private var isShowingAddFilesAlert = false
	@State private var isShowingSheetWithPicker = false
	@State private var pickerType: PickerType = .photos
	
    @State private var alertMessage = ""
	
	@EnvironmentObject var api: APIStore
	@EnvironmentObject var uploader: Uploader
    
	@State private var didLoadData: Bool = false
	
    var body: some View {
        ZStack {
            VStack {
                HStack {
					ProgressView("Uploading…", value: self.uploader.progressValue, total: 1.0)
						.frame(maxWidth: 200)
						
					if self.uploader.uploadState == .uploading {
                        Button(action: {
                            self.toggleUpload()
                        }) {
                            Image(systemName: "pause.fill")
                        }
                    }
					if self.uploader.uploadState == .paused {
                        Button(action: {
                            self.toggleUpload()
                        }) {
                            Image(systemName: "play.fill")
                        }
                    }
                }
				.opacity(self.uploader.isUploading ? 1 : 0)
                
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
			guard self.didLoadData == false else { return }
            self.loadData()
        }
        .actionSheet(isPresented: $isShowingAddFilesAlert, content: { ActionSheet(
                title: Text("Select source"),
                message: Text(""),
                buttons: [
                    .default(Text("Photos"), action: {
						self.pickerType = .photos
						self.isShowingSheetWithPicker.toggle()
					}),
					.default(Text("Files"), action: {
						self.pickerType = .files
						self.isShowingSheetWithPicker.toggle()
					}),
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
		.sheet(isPresented: $isShowingSheetWithPicker) {
			if self.pickerType == .photos {
				ImagePicker(sourceType: .photoLibrary) { (imageUrl) in
					self.uploader.uploadFile(imageUrl, completionHandler: { fileId in
						self.insertFileByFileId(fileId)
					})
				}
			} else {
				DocumentPicker { (url) in
					self.uploader.uploadFile(url, completionHandler: { fileId in
						self.insertFileByFileId(fileId)
					})
				}
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
    
    func toggleUpload() {
		guard let task = self.uploader.task else { return }
		switch self.uploader.uploadState {
        case .uploading:
            task.pause()
			self.uploader.uploadState = .paused
        case .paused:
            task.resume()
			self.uploader.uploadState = .uploading
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
				return DLog(error)
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
					DLog(error)
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
				return DLog(error)
			}
			self.didLoadData = true
			self.filesListStore.files.removeAll()
			list?.results.forEach { self.filesListStore.files.append(FileViewData( file: $0)) }
			
//			list?.results.forEach { print($0) }
		}
	}
	
	func insertFileByFileId(_ fileId: String) {
		// getting file by uuid
		self.api.uploadcare?.fileInfo(withUUID: fileId, { (file, error) in
			if let error = error {
				self.alertMessage = error.detail
				self.isShowingAlert.toggle()
				return DLog(error)
			}
			guard let file = file else { return }
			let viewData = FileViewData(file: file)
			self.filesListStore.files.insert(viewData, at: 0)
		})
	}
}

// MARK: - Preview
struct FilesListView_Previews: PreviewProvider {
    static var previews: some View {
		NavigationView {
			FilesListView()
				.environmentObject(APIStore())
				.navigationBarTitle(Text("List of files"))
		}
    }
}
