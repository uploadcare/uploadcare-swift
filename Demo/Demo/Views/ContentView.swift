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
	@ObservedObject private var api: APIStore
	@ObservedObject private var filesStore = FilesStore(files: [])
	@ObservedObject private var uploader: Uploader

	@State private var widgetVisible: Bool = false
	@State private var isShowingAddFilesAlert = false
	@State private var isShowingSheetWithPicker = false
	@State private var pickerType: PickerType = .photos
	@State private var messageText: String = ""


	init(api: APIStore) {
		self.api = api
		self.uploader = Uploader(uploadcare: api.uploadcare!)
	}

	private let sources: [SocialSource] = [
		SocialSource(source: .facebook),
		SocialSource(source: .gdrive),
		SocialSource(source: .gphotos),
		SocialSource(source: .dropbox),
		SocialSource(source: .instagram),
		SocialSource(source: .onedrive)
	]

	private var listElements: some View {
		List {
			NavigationLink(destination: FilesListView(filesStore: self.filesStore, api: api)) {
				Text("List of files")
			}
			NavigationLink(destination: GroupsListView(store: GroupsStore(uploadcare: api.uploadcare), api: api)) {
				Text("List of file groups")
			}
			NavigationLink(destination: ProjectInfoView(store: ProjectInfoStore(uploadcare: api.uploadcare))) {
				Text("Project info")
			}
		}
		.listStyle(GroupedListStyle())
	}

	var body: some View {
		NavigationView {
			ZStack {
				VStack {
					listElements
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
						self.uploader.picker
					}
				}

				VStack(spacing: 16) {
					Spacer()
					if !self.messageText.isEmpty {
						Text(self.messageText)
					}
					if self.uploader.isUploading {
						HStack {
							ProgressView(
								self.filesStore.uploadState == .paused ? "Paused" : "Uploading \(self.uploader.currentUploadingNumber) of \(self.uploader.uploadQueue.count)",
								value: self.uploader.uploadProgress, total: 1.0
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
									self.uploader.pickerType = .photos
									self.isShowingSheetWithPicker.toggle()
								}),
								.default(Text("Files"), action: {
									self.uploader.pickerType = .files
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
	MainView(
		api: APIStore(
			uploadcare: Uploadcare(withPublicKey: publicKey,secretKey: secretKey)
		)
	)
}
