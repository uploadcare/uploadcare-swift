//
//  Tester.swift
//  Demo
//
//  Created by Sergey Armodin on 20.05.2020.
//  Copyright © 2020 Sergei Armodin. All rights reserved.
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
        let uploadcare = Uploadcare(withPublicKey: "", secretKey: "")
        // uploadcare.authScheme = .simple
        // or
        // uploadcare.authScheme = .signed
        return uploadcare
    }()

    func start() {
        let queue = DispatchQueue(label: "uploadcare.test.queue")

//        queue.async { [unowned self] in
//            self.testUploadFileInfo()
//        }
//        queue.async { [unowned self] in
//            self.testUploadFileFromURL()
//        }
//        queue.async { [unowned self] in
//            self.testDirectUpload()
//        }
//        queue.async { [unowned self] in
//            self.testRESTListOfFiles()
//        }
//        queue.async { [unowned self] in
//            self.testRESTFileInfo()
//        }
//        queue.async { [unowned self] in
//            self.testRESTDeleteFile()
//        }
//        queue.async { [unowned self] in
//            self.testRESTBatchDeleteFiles()
//        }
//        queue.async { [unowned self] in
//            self.testRESTStoreFile()
//        }
//        queue.async { [unowned self] in
//            self.testRESTBatchStoreFiles()
//        }
//        queue.async { [unowned self] in
//            self.testListOfGroups()
//        }
//        queue.async { [unowned self] in
//            self.testGroupInfo()
//        }
//        queue.async { [unowned self] in
//            self.testStoreGroup()
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
//            self.testMultipartUpload()
//        }
//        queue.async { [unowned self] in
//            self.testRedirectForAuthenticatedUrls()
//        }
        queue.async {
            self.testCreateWebhook()
        }
        queue.async {
            self.testListOfWebhooks()
        }
    }

    func testUploadFileInfo() {
        print("<------ testUploadFileInfo ------>")
        let semaphore = DispatchSemaphore(value: 0)
        uploadcare.uploadAPI.fileInfo(withFileId: "530384dd-f43a-46de-b3c2-9448a24170cf") { (info, error) in
            defer {
                semaphore.signal()
            }
            if let error = error {
                print(error)
                return
            }
            
            print(info ?? "nil")
        }
        semaphore.wait()
    }
    
    func testUploadFileFromURL() {
        print("<------ testUploadFileFromURL ------>")
        let semaphore = DispatchSemaphore(value: 0)
        
        // upload from url
        let url = URL(string: "https://source.unsplash.com/random")
        let task = UploadFromURLTask(sourceUrl: url!)
            .checkURLDuplicates(true)
            .saveURLDuplicates(true)
            .filename("file_from_url")
            .store(.store)
        
        uploadcare.uploadAPI.upload(task: task) { [unowned self] (result, error) in
            if let error = error {
                print(error)
                return
            }
            print(result ?? "")
            
            guard let token = result?.token else {
                semaphore.signal()
                return
            }
            
            delay(1.0) { [unowned self] in
                self.uploadcare.uploadAPI.uploadStatus(forToken: token) { (status, error) in
                    print(status ?? "no data")
                    print(error ?? "no error")
                    semaphore.signal()
                }
            }
            
        }
        semaphore.wait()
    }
    
    func testUploadStatus() {
        print("<------ testUploadStatus ------>")
        let semaphore = DispatchSemaphore(value: 0)
        uploadcare.uploadAPI.uploadStatus(forToken: "ede4e436-9ff4-4027-8ffe-3b3e4d4a7f5b") { (status, error) in
            print(status ?? "no data")
            print(status?.error ?? "no error")
            semaphore.signal()
        }
        semaphore.wait()
    }
    
    func testDirectUpload() {
        print("<------ testDirectUpload ------>")
        guard let url = URL(string: "https://source.unsplash.com/random"), let data = try? Data(contentsOf: url) else { return }
        
        print("size of file: \(sizeString(ofData: data))")
        
        let semaphore = DispatchSemaphore(value: 0)
        let task = uploadcare.uploadAPI.upload(files: ["random_file_name.jpg": data], store: .store, { (progress) in
            print("upload progress: \(progress * 100)%")
        }) { (resultDictionary, error) in
            defer {
                semaphore.signal()
            }
            
            if let error = error {
                print(error)
                return
            }
            
            guard let files = resultDictionary else { return }
            
            for file in files {
                print("uploaded file name: \(file.key) | file id: \(file.value)")
            }
            print(resultDictionary ?? "nil")
        }
        
        // cancel if need
//        task.cancel()
        
        semaphore.wait()
    }
    
    func testRESTListOfFiles() {
        print("<------ testRESTListOfFiles ------>")
        let semaphore = DispatchSemaphore(value: 0)
        
        let query = PaginationQuery()
            .stored(true)
            .ordering(.sizeDESC)
            .limit(5)
        
        let filesList = uploadcare.listOfFiles()
        filesList.get(withQuery: query) { (list, error) in
            defer {
                semaphore.signal()
            }
            
            if let error = error {
                print(error)
                return
            }
            
            print(list ?? "")
        }
        semaphore.wait()
        
        // get next page
        print("-------------- next page")
        filesList.nextPage { (list, error) in
            defer {
                semaphore.signal()
            }
            
            if let error = error {
                print(error)
                return
            }
            
            print(list ?? "")
        }
        semaphore.wait()
        
        // get previous page
        print("-------------- previous page")
        filesList.previousPage { (list, error) in
            defer {
                semaphore.signal()
            }
            
            if let error = error {
                print(error)
                return
            }
            
            print(list ?? "")
        }
        semaphore.wait()
    }
    
    func testRESTFileInfo() {
        print("<------ testListOfFiles ------>")
        let semaphore = DispatchSemaphore(value: 0)
        
        uploadcare.fileInfo(withUUID: "1bac376c-aa7e-4356-861b-dd2657b5bfd2") { (file, error) in
            defer {
                semaphore.signal()
            }
            
            if let error = error {
                print(error)
                return
            }
            
//            let urlString = file.keyCDNUrl(
//                withToken: "fa3f69df3f4bcc9d4631bc7144838259bb26b34e26b4cc11c52e69f264b6c9fd",
//                expire: 1589136407
//            )
            // https://railsmuffin.ucarecdn.com/{UUID}/?token=fa3f69df3f4bcc9d4631bc7144838259bb26b34e26b4cc11c52e69f264b6c9fd&expire=1589136407
            
            print(file ?? "")
        }
        semaphore.wait()
    }
    
    func testRESTDeleteFile() {
        print("<------ testRESTDeleteFile ------>")
        let semaphore = DispatchSemaphore(value: 0)
        
        uploadcare.deleteFile(withUUID: "1bac376c-aa7e-4356-861b-dd2657b5bfd2") { (file, error) in
            defer {
                semaphore.signal()
            }
            
            if let error = error {
                print(error)
                return
            }
            
            print(file ?? "")
        }
        semaphore.wait()
    }
    
    func testRESTBatchDeleteFiles() {
        print("<------ testRESTBatchDeleteFiles ------>")
        let semaphore = DispatchSemaphore(value: 0)
        
        uploadcare.deleteFiles(withUUIDs: ["b7a301d1-1bd0-473d-8d32-708dd55addc0", "shouldBeInProblems"]) { (response, error) in
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
    
    func testRESTStoreFile() {
        print("<------ testRESTStoreFile ------>")
        let semaphore = DispatchSemaphore(value: 0)
        
        uploadcare.storeFile(withUUID: "1bac376c-aa7e-4356-861b-dd2657b5bfd2") { (file, error) in
            defer {
                semaphore.signal()
            }
            
            if let error = error {
                print(error)
                return
            }
            
            print(file ?? "")
        }
        semaphore.wait()
    }
    
    func testRESTBatchStoreFiles() {
        print("<------ testRESTBatchStoreFiles ------>")
        let semaphore = DispatchSemaphore(value: 0)
        
        uploadcare.storeFiles(withUUIDs: ["1bac376c-aa7e-4356-861b-dd2657b5bfd2", "shouldBeInProblems"]) { (response, error) in
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
    
    func testListOfGroups() {
        print("<------ testListOfGroups ------>")
        let semaphore = DispatchSemaphore(value: 0)
        
        let query = GroupsListQuery()
            .limit(100)
            .ordering(.datetimeCreatedDESC)
        
        uploadcare.listOfGroups(withQuery: query) { (list, error) in
            defer {
                semaphore.signal()
            }

            if let error = error {
                print(error)
                return
            }

            print(list ?? "")
        }
        semaphore.wait()
        
        // using GroupsList object:
        let groupsList = uploadcare.listOfGroups()
        groupsList.get(withQuery: query) { (list, error) in
            defer {
                semaphore.signal()
            }
            
            if let error = error {
                print(error)
                return
            }
            
            print(list ?? "")
        }
        semaphore.wait()
        
        // get next page
        print("-------------- next page")
        groupsList.nextPage { (list, error) in
            defer {
                semaphore.signal()
            }
            
            if let error = error {
                print(error)
                return
            }
            
            print(list ?? "")
        }
        semaphore.wait()
        
        // get previous page
        print("-------------- previous page")
        groupsList.previousPage { (list, error) in
            defer {
                semaphore.signal()
            }
            
            if let error = error {
                print(error)
                return
            }
            
            print(list ?? "")
        }
        semaphore.wait()
    }
    
    func testGroupInfo() {
        print("<------ testGroupInfo ------>")
        let semaphore = DispatchSemaphore(value: 0)
        
        uploadcare.groupInfo(withUUID: "c5bec8c7-d4b6-4921-9e55-6edb027546bc~1") { (group, error) in
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
    
    func testStoreGroup() {
        print("<------ testStoreGroup ------>")
        let semaphore = DispatchSemaphore(value: 0)
        
        uploadcare.storeGroup(withUUID: "c5bec8c7-d4b6-4921-9e55-6edb027546bc~1") { (error) in
            defer {
                semaphore.signal()
            }

            if let error = error {
                print(error)
                return
            }
            print("store group success")
        }
        semaphore.wait()
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

            let newGroup = self.uploadcare.uploadAPI.group(ofFiles: [])
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
    
    func testMultipartUpload() {
        print("<------ testMultipartUpload ------>")
        
        guard let url = Bundle.main.url(forResource: "Mona_Lisa_23mb", withExtension: "jpg") else {
            assertionFailure("no file")
            return
        }
        
        guard let fileForUploading = uploadcare.uploadAPI.file(withContentsOf: url) else {
            assertionFailure("file not found")
            return
        }
        
        // upload without any callbacks
//        fileForUploading.upload(withName: "Mona_Lisa_big111.jpg")
        
        // or
        
        let semaphore = DispatchSemaphore(value: 0)
        
        var task: UploadTaskResumable?
        var didPause = false
        let onProgress: (Double)->Void = { (progress) in
            print("progress: \(progress)")
            
            if !didPause {
                didPause.toggle()
                task?.pause()
                
                delay(10.0) {
                    task?.resume()
                }
            }
        }
        
        task = fileForUploading.upload(withName: "Mona_Lisa_big.jpg", onProgress, { (file, error) in
            defer {
                semaphore.signal()
            }
            if let error = error {
                print(error)
                return
            }
            print(file ?? "")
        })
        
        // pause
        task?.pause()
        delay(2.0) {
            task?.resume()
        }
                
        // cancel if need
//        task?.cancel()
        
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
        
        let url = URL(string: "https://arm1.ru")!
        uploadcare.createWebhook(targetUrl: url, isActive: true) { (value, error) in
            defer { semaphore.signal() }
            
            if let error = error {
                print(error)
                return
            }
            
            print(value ?? "")
        }
        
        semaphore.wait()
    }
}
