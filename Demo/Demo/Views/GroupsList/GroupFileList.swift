//
//  GroupFileList.swift
//  Demo
//
//  Created by Sergey Armodin on 26.06.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import SwiftUI
import Uploadcare

struct GroupFileList: View {
	var viewData: GroupViewData
	
	@EnvironmentObject var api: APIStore
	@ObservedObject private var filesStore: FilesStore = FilesStore()
	@State private var isLoading: Bool = true
	@State private var alertMessage = ""
	@State private var isShowingAlert = false
	@State private var didLoadData: Bool = false
	
    var body: some View {
		ZStack {
			List {
				Section {
					ForEach(self.filesStore.files) { file in
						FileRowView(fileData: file)
					}
				}
			}
			
			VStack(spacing: 16) {
				ProgressView()
					.progressViewStyle(.circular)
					.scaleEffect(CGSize(width: 1.8, height: 1.8))
				Text("Loading...")
			}
			.opacity(self.isLoading ? 1 : 0)
		}
		.onAppear {
			guard self.didLoadData == false else { return }
			self.didLoadData = true
			Task { try await self.loadData() }
		}
		.alert(isPresented: $isShowingAlert) {
			Alert(
				title: Text("Error"),
				message: Text(self.alertMessage),
				dismissButton: .default(Text("OK"))
			)
		}
		.navigationBarTitle(Text("Files in group"))
    }
	
	func loadData() async throws {
		defer {
			DispatchQueue.main.async {
				self.isLoading = false
			}
		}

		do {
			guard let group = try await self.api.uploadcare?.groupInfo(withUUID: self.viewData.group.id) else { return }
			DispatchQueue.main.async {
				self.filesStore.files.removeAll()
				group.files?.forEach { self.filesStore.files.append(FileViewData( file: $0)) }
			}
		} catch {
			DispatchQueue.main.async {
				self.alertMessage = (error as? RESTAPIError)?.detail ?? "Error"
				DLog(error)
			}
		}
	}
}
