//
//  BackgroundSessionManager.swift
//  
//
//  Created by Sergey Armodin on 03.12.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if !os(Linux)
class BackgroundSessionManager: NSObject {
	static let instance = BackgroundSessionManager()

    /// Running background tasks where key is URLSessionTask.taskIdentifier
	var backgroundTasks = [Int: UploadTask]()
	
	lazy var session: URLSession = {
		let bundle = Bundle.main.bundleIdentifier ?? ""

		if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
			let config = URLSessionConfiguration.default
			return URLSession(configuration: config, delegate: self, delegateQueue: nil)
		}

		let config = URLSessionConfiguration.background(withIdentifier: "\(bundle).com.uploadcare.backgroundUrlSession")
		config.isDiscretionary = false
		
		// TODO: add a public settings for that
		#if !os(macOS)
		config.sessionSendsLaunchEvents = true
		#endif
		
		config.waitsForConnectivity = true
		return URLSession(configuration: config, delegate: self, delegateQueue: nil)
	}()
	weak var sessionDelegate: URLSessionDelegate?
}

// MARK: - URLSessionTaskDelegate proxy
extension BackgroundSessionManager: URLSessionDataDelegate {
	public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
		(sessionDelegate as? URLSessionDataDelegate)?.urlSession?(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
	}
}

// MARK: - URLSessionTaskDelegate proxy
extension BackgroundSessionManager: URLSessionTaskDelegate {
	public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		(sessionDelegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, didCompleteWithError: error)
	}
	
	public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
		(sessionDelegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
	}
	
	public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
		(sessionDelegate as? URLSessionDataDelegate)?.urlSession?(session, dataTask: dataTask, didReceive: data)
	}
}
#endif