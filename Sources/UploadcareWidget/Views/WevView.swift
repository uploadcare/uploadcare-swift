//
//  File.swift
//  
//
//  Created by Sergei Armodin on 25.01.2021.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
	var url: URL
	var onComplete: (()->Void)?
	var mainWebView: WKWebView = {
		let configuration = WKWebViewConfiguration()
		let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
		webView.allowsBackForwardNavigationGestures = true
		webView.scrollView.isScrollEnabled = true
		return webView
	}()
	
	// Make a coordinator to co-ordinate with WKWebView's default delegate functions
	func makeCoordinator() -> Coordinator {
		Coordinator(self, onComplete: self.onComplete)
	}
	
	func makeUIView(context: Context) -> WKWebView {
		mainWebView.navigationDelegate = context.coordinator
		mainWebView.uiDelegate = context.coordinator
		return mainWebView
	}
	
	func updateUIView(_ webView: WKWebView, context: Context) {
		webView.load(URLRequest(url: url))
	}
	
	class Coordinator : NSObject, WKNavigationDelegate, WKUIDelegate {
		var parent: WebView
		var newWebviewPopupWindow: WKWebView?
		
		var onComplete: (()->Void)?
		
		init(_ uiWebView: WebView, onComplete: (()->Void)?) {
			self.parent = uiWebView
			self.onComplete = onComplete
		}
		
		func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
			decisionHandler(.allow)
		}
		
		func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
			
			let newWebView = WKWebView(frame: parent.mainWebView.bounds, configuration: configuration)
			newWebView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			newWebView.navigationDelegate = self
			newWebView.uiDelegate = self
			
			parent.mainWebView.addSubview(newWebView)
			
			newWebviewPopupWindow = newWebView
			return newWebView
		}
		
		func webViewDidClose(_ webView: WKWebView) {
			webView.removeFromSuperview()
			newWebviewPopupWindow = nil
		}
	}
}

