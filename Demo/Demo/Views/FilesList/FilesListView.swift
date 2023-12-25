//
//  FilesListView.swift
//  Demo
//
//  Created by Sergey Armodin on 27.03.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import SwiftUI
import Combine
import Uploadcare

struct FilesListView: View {
	@ObservedObject var filesStore: FilesStore
    
    @State private var isLoading: Bool = true
	@State private var isShowingAlert = false
    
	@State private var isShowingAddFilesAlert = false
	@State private var isShowingSheetWithPicker = false
	@State private var pickerType: PickerType = .photos
	
    @State private var alertMessage = ""
	
	@State var isUploading: Bool = false
	
	@EnvironmentObject var api: APIStore
	
	@State private var didLoadData: Bool = false
	
    var body: some View {
        ZStack {
            VStack {
                HStack {
					ProgressView(
						self.filesStore.uploadState == .paused ? "Paused" : "Uploading \(self.filesStore.uploadedFromQueue) of \(self.filesStore.filesQueue.count)",
						value: self.filesStore.progressValue, total: 1.0
					).frame(maxWidth: 200)
						
					if self.filesStore.uploadState == .uploading {
                        Button(action: {
                            self.toggleUpload()
                        }) {
                            Image(systemName: "pause.fill")
						}
                    }
					if self.filesStore.uploadState == .paused {
                        Button(action: {
                            self.toggleUpload()
                        }) {
                            Image(systemName: "play.fill")
						}
                    }
                }
				.opacity(self.isUploading ? 1 : 0)
                
                List {
                    Section {
                        ForEach(self.filesStore.files) { file in
                            FileRowView(fileData: file)
								.onAppear {
									if file.file.uuid == self.filesStore.files.last?.file.uuid {
										self.loadMoreIfNeed()
									}
								}
                        }.onDelete(perform: delete)
                    }
                }
            }
            
			VStack(spacing: 16) {
				ProgressView()
					.progressViewStyle(.circular)
					.scaleEffect(CGSize(width: 1.8, height: 1.8))
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
					self.isUploading = true
					
					self.filesStore.uploadFile(imageUrl, completionHandler: { fileId in
						self.isUploading = false
						self.insertFileByFileId(fileId)
					})
				}
			} else {
				DocumentPicker { (urls) in
					self.isUploading = true
					self.filesStore.uploadFiles(urls, completionHandler: { fileIds in
						self.isUploading = false
						fileIds.forEach({ self.insertFileByFileId($0) })
					})
				}
			}
		}
        .navigationBarItems(trailing:
            HStack {
				Button("Add") {
					self.isShowingAddFilesAlert.toggle()
				}
				EditButton()
            }
        )
        .navigationBarTitle(Text("List of files"))
	}
    
    func toggleUpload() {
		guard let task = self.filesStore.currentTask else { return }
		switch self.filesStore.uploadState {
        case .uploading:
            task.pause()
			self.filesStore.uploadState = .paused
        case .paused:
            task.resume()
			self.filesStore.uploadState = .uploading
        default: break
        }
    }
	
	func loadMoreIfNeed() {
		self.isLoading = true
		Task {
			defer { DispatchQueue.main.async { self.isLoading = false } }

			do {
				try await filesStore.loadNext()
			} catch let error {
				DispatchQueue.main.async {
					self.alertMessage = (error as? RESTAPIError)?.detail ?? error.localizedDescription
					self.isShowingAlert.toggle()
				}
			}
		}
	}
    
	func delete(at offsets: IndexSet) {
		Task {
			try await self.filesStore.deleteFiles(at: offsets)
		}
	}
	
	func loadData() {
		filesStore.uploadcare = self.api.uploadcare
		Task {
			defer { DispatchQueue.main.async { self.isLoading = false } }

			do {
				try await self.filesStore.load()
				DispatchQueue.main.async { self.didLoadData = true }
			} catch let error {
				DispatchQueue.main.async {
					self.alertMessage = (error as? RESTAPIError)?.detail ?? error.localizedDescription
					self.isShowingAlert.toggle()
				}
			}
		}
	}
	
	func insertFileByFileId(_ fileId: String) {
		// getting file by uuid
		self.api.uploadcare?.fileInfo(withUUID: fileId) { result in
			switch result {
			case .failure(let error):
				self.alertMessage = error.detail
				self.isShowingAlert.toggle()
				DLog(error)
			case .success(let file):
				let viewData = FileViewData(file: file)
				self.filesStore.files.insert(viewData, at: 0)
			}
		}
	}
}

// MARK: - Preview
#Preview {
	NavigationView {
		FilesListView(filesStore: FilesStore(files: []))
			.environmentObject(APIStore())
			.navigationBarTitle(Text("List of files"))
	}
}
