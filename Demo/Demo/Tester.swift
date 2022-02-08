//
//  Tester.swift
//  Demo
//
//  Created by Sergey Armodin on 20.05.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation
import Uploadcare


/// Delay function using GCD.
///
/// - Parameters:
///   - delay: delay in seconds
///   - closure: block to execute after delay
func delay(_ delay: Double, closure: @escaping ()->()) {
	DispatchQueue.main.asyncAfter(
		deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

func DLog(
	_ messages: Any...,
	fullPath: String = #file,
	line: Int = #line,
	functionName: String = #function
) {
	let file = URL(fileURLWithPath: fullPath)
	for message in messages {
		#if DEBUG
		let string = "\(file.pathComponents.last!):\(line) -> \(functionName): \(message)"
		print(string)
		#endif
	}
}

/// Count size of Data (in mb)
/// - Parameter data: data
func sizeString(ofData data: Data) -> String {
	let bcf = ByteCountFormatter()
	bcf.allowedUnits = [.useMB] // optional: restricts the units to MB only
	bcf.countStyle = .file
	return bcf.string(fromByteCount: Int64(data.count))
}


class Tester {
	private lazy var uploadcare: Uploadcare = {
		// Define your Public Key here
		let uploadcare = Uploadcare(withPublicKey: publicKey, secretKey: secretKey)
		// uploadcare.authScheme = .simple
		// or
		// uploadcare.authScheme = .signed
		return uploadcare
	}()
	
	func start() {
		let queue = DispatchQueue(label: "uploadcare.test.queue")
		//        queue.async { [unowned self] in
		//            self.testRESTFileInfo()
		//        }
		//        queue.async { [unowned self] in
		//            self.testCopyFileToLocalStorage()
		//        }
		//        queue.async { [unowned self] in
		//            self.testCopyFileToRemoteStorate()
		//        }
		//        queue.async { [unowned self] in
		//            self.testCreateFileGroups()
		//        }
		//        queue.async { [unowned self] in
		//            self.testFileGroupInfo()
		//        }
		//        queue.async { [unowned self] in
		//            self.testRedirectForAuthenticatedUrls()
		//        }
//		        queue.async {
//		            self.testCreateWebhook()
//		        }
//		        queue.async {
//		            self.testListOfWebhooks()
//		        }
//				queue.async {
//		            self.testUpdateWebhook()
//		        }
		//		queue.async {
		//            self.testDeleteWebhook()
		//        }
		//		queue.async {
		//            self.testDocumentConversion()
		//        }
//		queue.async {
//			self.testDocumentConversionStatus()
//		}
		//		queue.async {
		//            self.testVideoConversionStatus()
		//        }
		
	}
	
	func testCopyFileToLocalStorage() {
		print("<------ testCopyFileToLocalStorage ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		uploadcare.copyFileToLocalStorage(source: "6ca619a8-70a7-4777-8de1-7d07739ebbd9") { (response, error) in
			defer {
				semaphore.signal()
			}
			
			if let error = error {
				print(error)
				return
			}
			print(response ?? "")
		}
		semaphore.wait()
	}
	
	func testCopyFileToRemoteStorate() {
		print("<------ testCopyFileToLocalStorage ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		uploadcare.copyFileToRemoteStorage(source: "99c48392-46ab-4877-a6e1-e2557b011176", target: "one_more_project", pattern: .uuid) { (response, error) in
			defer {
				semaphore.signal()
			}
			
			if let error = error {
				print(error)
				return
			}
			print(response ?? "")
		}
		semaphore.wait()
	}
	
	func testCreateFileGroups() {
		print("<------ testCreateFileGroups ------>")
		let semaphore = DispatchSemaphore(value: 0)
		uploadcare.uploadAPI.filesGroupInfo(groupId: "69b8e46f-91c9-494f-ba3b-e5fdf9c36db2~2") { (group, error) in
			guard group != nil else {
				print(error ?? "")
				return
			}
			
			let newGroup = self.uploadcare.group(ofFiles: [])
			newGroup.files = group?.files ?? []
			newGroup.create { (_, error) in
				print(error ?? "")
				print(newGroup)
			}
		}
		semaphore.wait()
	}
	
	func testFileGroupInfo() {
		print("<------ testFileGroupInfo ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		uploadcare.uploadAPI.filesGroupInfo(groupId: "69b8e46f-91c9-494f-ba3b-e5fdf9c36db2~2") { (group, error) in
			defer {
				semaphore.signal()
			}
			if let error = error {
				print(error)
				return
			}
			print(group ?? "")
		}
		semaphore.wait()
	}
	
	func testRedirectForAuthenticatedUrls() {
		print("<------ testRedirectForAuthenticatedUrls ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		let url = URL(string: "http://goo.gl/")!
		uploadcare.getAuthenticatedUrlFromUrl(url, { (value, error) in
			defer { semaphore.signal() }
			
			if let error = error {
				print(error)
				return
			}
			
			print(value ?? "")
		})
		
		semaphore.wait()
	}
	
	func testListOfWebhooks() {
		print("<------ testListOfWebhooks ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		uploadcare.getListOfWebhooks { (value, error) in
			defer { semaphore.signal() }
			
			if let error = error {
				print(error)
				return
			}
			
			print(value ?? "")
		}
		
		semaphore.wait()
	}
	
	func testCreateWebhook() {
		print("<------ testCreateWebhook ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		let random = (0...1000).randomElement()!
		let url = URL(string: "https://google.com/\(random)")!
		uploadcare.createWebhook(targetUrl: url, isActive: true, signingSecret: "sss1") { (value, error) in
			defer { semaphore.signal() }
			
			if let error = error {
				print(error)
				return
			}
			
			print(value ?? "")
		}
		
		semaphore.wait()
	}
	
	func testUpdateWebhook() {
		print("<------ testUpdateWebhook ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		let random = (0...1000).randomElement()!
		let url = URL(string: "https://apple.com/\(random)")!
		
		uploadcare.getListOfWebhooks { (value, error) in
			if let error = error {
				print(error)
				semaphore.signal()
				return
			}
			
			guard let webhook = value?.first else {
				semaphore.signal()
				return
			}
			
			print(webhook)
			self.uploadcare.updateWebhook(id: webhook.id, targetUrl: url, isActive: true, signingSecret: "sss2") { (value, error) in
				defer { semaphore.signal() }
				
				if let error = error {
					print(error)
					return
				}
				
				print(value ?? "")
			}
		}
		
		semaphore.wait()
	}
	
	func testDeleteWebhook() {
		print("<------ testDeleteWebhook ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		uploadcare.getListOfWebhooks { (value, error) in
			if let error = error {
				print(error)
				semaphore.signal()
				return
			}
			
			guard let webhook = value?.first else {
				semaphore.signal()
				return
			}
			
			print("will delete:")
			print(webhook)
			let url = URL(string: webhook.targetUrl)!
			self.uploadcare.deleteWebhook(forTargetUrl: url) { (error) in
				if let error = error {
					print(error)
				}
				
				semaphore.signal()
			}
		}
		
		semaphore.wait()
	}
	
	func testDocumentConversion() {
		print("<------ testDocumentConversion ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		uploadcare.fileInfo(withUUID: "b40e1f1a-46e1-471e-8a57-cb863719e8b0") { (file, error) in
			guard let file = file else {
				print(error ?? "fileInfo error")
				semaphore.signal()
				return
			}
			
			let convertSettings = DocumentConversionJobSettings(forFile: file)
				.format(.odt)
			
			self.uploadcare.convertDocumentsWithSettings([convertSettings]) { (response, error) in
				defer { semaphore.signal() }
				
				guard let response = response else {
					print(error ?? "error")
					return
				}
				
				print(response)
			}
		}
		semaphore.wait()
	}
	
	func testDocumentConversionStatus() {
		print("<------ testDocumentConversionStatus ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		uploadcare.fileInfo(withUUID: "b40e1f1a-46e1-471e-8a57-cb863719e8b0") { (file, error) in
			guard let file = file else {
				print(error ?? "fileInfo error")
				semaphore.signal()
				return
			}
			
			let convertSettings = DocumentConversionJobSettings(forFile: file)
				.format(.odt)
			
			self.uploadcare.convertDocumentsWithSettings([convertSettings]) { (response, error) in
				guard let response = response else {
					print(error ?? "error")
					semaphore.signal()
					return
				}
				
				guard response.problems.isEmpty, let job = response.result.first else {
					print(response)
					semaphore.signal()
					return
				}
				
				let timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { (timer) in
					self.uploadcare.documentConversionJobStatus(token: job.token) { (status, error) in
						guard let status = status else {
							print(error ?? "error")
							return
						}
						
						print(status)
						switch status.status {
						case .finished, .failed(_):
							timer.invalidate()
							semaphore.signal()
						default: break
						}
					}
				}
				timer.fire()
			}
		}
		semaphore.wait()
	}
	
	func testVideoConversionStatus() {
		print("<------ testVideoConversionStatus ------>")
		let semaphore = DispatchSemaphore(value: 0)
		
		uploadcare.fileInfo(withUUID: "8968032a-6d52-4d68-8af7-154552412f93") { (file, error) in
			guard let file = file else {
				print(error ?? "fileInfo error")
				semaphore.signal()
				return
			}
			
			print(file)
			
			let convertSettings = VideoConversionJobSettings(forFile: file)
				.format(.webm)
				.size(VideoSize(width: 640, height: 480))
				.resizeMode(.addPadding)
				.quality(.lightest)
				.cut( VideoCut(startTime: "0:0:5.000", length: "15") )
				.thumbs(15)
			
			self.uploadcare.convertVideosWithSettings([convertSettings]) { (response, error) in
				guard let response = response else {
					print(error ?? "error")
					semaphore.signal()
					return
				}
				
				guard response.problems.isEmpty, let job = response.result.first else {
					print(response)
					semaphore.signal()
					return
				}
				
				let timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { (timer) in
					self.uploadcare.videoConversionJobStatus(token: job.token) { (status, error) in
						guard let status = status else {
							print(error ?? "error")
							return
						}
						
						print(status)
						switch status.status {
						case .finished, .failed(_):
							timer.invalidate()
							semaphore.signal()
						default: break
						}
					}
				}
				timer.fire()
			}
		}
		semaphore.wait()
	}
}
