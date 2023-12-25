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
	@ObservedObject private var filesListStore: FilesStore = FilesStore(files: [])
	@State private var isLoading: Bool = true
	@State private var alertMessage = ""
	@State private var isShowingAlert = false
	@State private var didLoadData: Bool = false
	
    var body: some View {
		ZStack {
			List {
				Section {
					ForEach(self.filesListStore.files) { file in
						FileRowView(fileData: file)
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
				self.filesListStore.files.removeAll()
				group.files?.forEach { self.filesListStore.files.append(FileViewData( file: $0)) }
			}
		} catch {
			DispatchQueue.main.async {
				self.alertMessage = (error as? RESTAPIError)?.detail ?? "Error"
				DLog(error)
			}
		}
	}
}

struct GroupFileList_Previews: PreviewProvider {
    static var previews: some View {
		#if DEBUG
        GroupFileList(viewData: testGroupViewData)
			.environmentObject(APIStore())
		#endif
    }
}
