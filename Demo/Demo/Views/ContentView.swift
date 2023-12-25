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
	@ObservedObject private var filesStore = FilesStore(files: [])

	@State var widgetVisible: Bool = false

	@State private var isShowingAddFilesAlert = false
	@State private var isShowingSheetWithPicker = false
	@State private var pickerType: PickerType = .photos
	@State private var messageText: String = ""

	@State var isUploading: Bool = false

	private let sources: [SocialSource] = [
		SocialSource(source: .facebook),
		SocialSource(source: .gdrive),
		SocialSource(source: .gphotos),
		SocialSource(source: .dropbox),
		SocialSource(source: .instagram),
		SocialSource(source: .onedrive)
	]

	var body: some View {
		NavigationView {
			ZStack {
				VStack {
					List {
						NavigationLink(destination: FilesListView(filesStore: self.filesStore)) {
							Text("List of files")
						}
						NavigationLink(destination: GroupsListView(store: GroupsStore(uploadcare: api.uploadcare))) {
							Text("List of file groups")
						}
						NavigationLink(destination: ProjectInfoView(store: ProjectInfoStore(uploadcare: api.uploadcare))) {
							Text("Project info")
						}
					}
					.listStyle(GroupedListStyle())
					.navigationBarTitle(Text("Uploadcare demo"), displayMode: .automatic)
					.sheet(isPresented: self.$widgetVisible, content: {
						NavigationView {
							SelectSourceView(publicKey: publicKey, sources: sources)
								.navigationBarItems(trailing: Button("Close") {
									self.widgetVisible = false
								})
								.environmentObject(api)
						}
					})
					.sheet(isPresented: $isShowingSheetWithPicker) {
						if self.pickerType == .photos {
							ImagePicker(sourceType: .photoLibrary) { (imageUrl) in
								withAnimation(.easeIn) {
									self.isUploading = true
								}

								self.filesStore.uploadFile(imageUrl, completionHandler: { fileId in
									withAnimation(.easeOut) {
										self.isUploading = false
										delay(0.5) {
											self.messageText = "Upload finished"
											delay(3) {
												self.messageText = ""
											}
										}
									}
								})
							}
						} else {
							DocumentPicker { (urls) in
								withAnimation(.easeIn) {
									self.isUploading = true
								}
								self.filesStore.uploadFiles(urls, completionHandler: { fileIds in
									withAnimation(.easeOut) {
										self.isUploading = false
										delay(0.5) {
											self.messageText = "Upload finished"
											delay(3) {
												self.messageText = ""
											}
										}
									}
								})
							}
						}
					}
				}

				VStack(spacing: 16) {
					Spacer()
					if !self.messageText.isEmpty {
						Text(self.messageText)
					}
					if self.isUploading {
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
					}

					Button("Upload file") {
						if self.filesStore.uploadcare == nil {
							self.filesStore.uploadcare = self.api.uploadcare
						}
						self.isShowingAddFilesAlert.toggle()
					}
					.buttonStyle(NeumorphicButtonStyle(bgColor: Color.gray.opacity(0.05)))
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
								.default(Text("External Sources"), action: {
									self.widgetVisible = true
								}),
								.cancel()
							]
						)
					})
				}
			}
		}
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
}

#Preview {
	MainView()
		.environmentObject(
			APIStore(
				uploadcare: Uploadcare(withPublicKey: publicKey,secretKey: secretKey)
			)
		)
}
