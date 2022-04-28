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
		//            self.testCreateFileGroups()
		//        }
		//        queue.async { [unowned self] in
		//            self.testFileGroupInfo()
		//        }		
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
}
