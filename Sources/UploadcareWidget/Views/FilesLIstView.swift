//
//  FilesLIstView.swift
//  
//
//  Created by Sergei Armodin on 26.01.2021.
//

import SwiftUI

@available(iOS 13.0.0, OSX 10.15.0, *)
struct FilesLIstView: View {
	@Environment(\.presentationMode) var presentation
	var viewModel: FilesLIstViewModel
	
	var body: some View {
		
		
        Text("Hello, World!")
			.onAppear {
				viewModel.getSourceChunk()
			}
			.navigationBarTitle(Text("Files"))
			.navigationBarItems(trailing: Button("Logout") {
				self.viewModel.logout()
				self.presentation.wrappedValue.dismiss()
			})
    }
}

@available(iOS 13.0.0, OSX 10.15.0, *)
struct FilesLIstView_Previews: PreviewProvider {
    static var previews: some View {
		FilesLIstView(
			viewModel: FilesLIstViewModel(source: SocialSource(source: .vk), cookie: "")
		)
    }
}
