//
//  ContentView.swift
//  Demo
//
//  Created by Sergey Armodin on 26.03.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import SwiftUI
import Uploadcare
import UploadcareWidget

struct MainView: View {
	@EnvironmentObject var api: APIStore
	@ObservedObject private var filesListStore = FilesListStore(files: [])
	
	@State var widgetVisible: Bool = false

	@State private var isShowingAddFilesAlert = false
	@State private var isShowingSheetWithPicker = false
	@State private var pickerType: PickerType = .photos

	@State var isUploading: Bool = false
	
    var body: some View {
		NavigationView {
            ZStack {
				VStack {
					HStack {
						ProgressView(
							self.filesListStore.uploadState == .paused ? "Paused" : "Uploading \(self.filesListStore.uploadedFromQueue) of \(self.filesListStore.filesQueue.count)",
							value: self.filesListStore.progressValue, total: 1.0
						).frame(maxWidth: 200)

						if self.filesListStore.uploadState == .uploading {
							Button(action: {
								self.toggleUpload()
							}) {
								Image(systemName: "pause.fill")
							}
						}
						if self.filesListStore.uploadState == .paused {
							Button(action: {
								self.toggleUpload()
							}) {
								Image(systemName: "play.fill")
							}
						}
					}
					.opacity(self.isUploading ? 1 : 0)

					List {
						NavigationLink(destination: FilesListView(filesListStore: self.filesListStore)) {
							Text("List of files")
						}
						NavigationLink(destination: GroupsListView(viewModel: GroupsListViewModel(uploadcare: api.uploadcare))) {
							Text("List of file groups")
						}
						NavigationLink(destination: ProjectInfoView(viewModel: ProjectInfoViewModel(uploadcare: api.uploadcare))) {
							Text("Project info")
						}

						Button("External Sources") {
							self.widgetVisible = true
						}
					}
					.listStyle(GroupedListStyle())
					.navigationBarTitle(Text("Uploadcare demo"), displayMode: .automatic)
					.sheet(isPresented: self.$widgetVisible, content: {
						NavigationView {
							SelectSourceView(publicKey: publicKey)
								.navigationBarItems(trailing: Button("Close") {
									self.widgetVisible = false
								})
								.environmentObject(api)
						}
					})

					.actionSheet(isPresented: $isShowingAddFilesAlert, content: {
						ActionSheet(
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
					.sheet(isPresented: $isShowingSheetWithPicker) {
						if self.pickerType == .photos {
							ImagePicker(sourceType: .photoLibrary) { (imageUrl) in
								self.isUploading = true

								self.filesListStore.uploadFile(imageUrl, completionHandler: { fileId in
									self.isUploading = false
								})
							}
						} else {
							DocumentPicker { (urls) in
								self.isUploading = true
								self.filesListStore.uploadFiles(urls, completionHandler: { fileIds in
									self.isUploading = false
								})
							}
						}
					}
			}

				VStack {
					Spacer()
					Button("Upload file") {
						if self.filesListStore.uploadcare == nil {
							self.filesListStore.uploadcare = self.api.uploadcare
						}
						self.isShowingAddFilesAlert.toggle()
					}
				}
            }
		}
    }

	func toggleUpload() {
		guard let task = self.filesListStore.currentTask else { return }
		switch self.filesListStore.uploadState {
		case .uploading:
			task.pause()
			self.filesListStore.uploadState = .paused
		case .paused:
			task.resume()
			self.filesListStore.uploadState = .uploading
		default: break
		}
	}
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
		MainView()
			.environmentObject(APIStore())
			.previewDevice(PreviewDevice(rawValue: "iPhone X"))
    }
}
