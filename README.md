# [WIP] Swift integration for Uploadcare

<p align="left">
    <a href="LICENSE">
        <img src="https://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License">
    </a>
    <a href="https://swift.org">
        <img src="https://img.shields.io/badge/swift-5.1-brightgreen.svg" alt="Swift 5.1">
    </a>
</p>

Swift library for Uploadcare handles uploads (and further operations with files) by wrapping Upload (and REST, which is currently work in progress) APIs.

GIF TBD

Check out [demo app](https://github.com/uploadcare/uploadcare-swift/tree/readme-alfa/DemoApp).

* [Installation](#installation)
* [Initialization](#initialization)
* [Using Upload API](#using-upload-api)
* [Useful links](#useful-links)

## Installation

### Swift Package Manager

To use a stable version add a dependency to your Package.swift file:

```swift
dependencies: [
    .package(url: "https://github.com/uploadcare/uploadcare-swift.git", branch("master"))
]
```

If you want to try the current dev version, add a dependency to your Package.swift file:

```swift
dependencies: [
    .package(url: "https://github.com/uploadcare/uploadcare-swift.git", branch("develop"))
]
```

Or you can just add it using Xcode: https://github.com/uploadcare/uploadcare-swift

### Carthage

TBD

### Cocoapods

TBD

## Initialization

```swift
let uploadcare = Uploadcare(withPublicKey: "YOUR_PUBLIC_KEY", secretKey: "YOUR_SECRET_KEY")
```

## Using Upload API

### Direct uploads ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/baseUpload)) ###

```swift
guard let image = UIImage(named: "MonaLisa.jpg"), let data = image.jpegData(compressionQuality: 1) else { return }

uploadcare.uploadAPI.upload(files: ["mona_lisa.jpg": data], store: .store) { (result, error) in
    if let error = error {
        print(error)
        return
    }

    guard let files = result else { return }			
    for file in files {
        print("uploaded file name: \(file.key) | file id: \(file.value)")
    }
}
```

### Multipart uploads ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/multipartFileUploadStart)) ###

Multipart Uploads are useful when you are dealing with files larger than 100MB or explicitly want to use accelerated uploads.  Multipart Upload contains 3 steps:
1. Start transaction
2. Upload file chunks
3. Complete transaction

You can use the upload method that will run all 3 steps for you:

```swift
guard let url = Bundle.main.url(forResource: "Mona_Lisa_23mb", withExtension: "jpg") else { return }
guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return }
uploadcare.uploadAPI.uploadFile(data, withName: "Mona_Lisa_big.jpg") { (file, error) in
    if let error = error {
        print(error)
        return
    }
    print(file ?? "")
}
```

If you want to run these steps manually, you can use 3 API methods:

```swift
// start transaction
uploadcare.uploadAPI.startMulipartUpload(withName: "file_name", size: data.count, mimeType: "image/jpeg") { (response, error) in
    // handle response or error
    // response contains presigned urls for chunks (response.parts) and file UUID (response.uuid)
}

// prepare 5MB Data chunks (5242880 bytes) by yourself. Upload every chunk with:
uploadcare.uploadAPI.uploadIndividualFilePart(chunk, toPresignedUrl: presignedUrl, withMimeType: "image/jpeg")

// finish transaction when all chunks was uploaded
uploadcare.uploadAPI.completeMultipartUpload(forFileUIID: "FILE_UUID") { (file, error) in
    // handle result or error
}
```

### Upload files from URLs ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/fromURLUpload)) ###

```swift
let url = URL(string: "https://ucarecdn.com/assets/images/cloud.6b86b4f1d77e.jpg")

let task1 = UploadFromURLTask(sourceUrl: url!)
// upload
uploadcare.uploadAPI.upload(task: task1) { [unowned self] (result, error) in
    if let error = error {
        print(error)
        return
    }
    print(result)
}
```

UploadFromURLTask is used to store upload parameters.

```swift
// Set parameters by accessing properties:
let task2 = UploadFromURLTask(sourceUrl: url!)
task2.store = .doNotstore

// Set parameters using chaining
let task3 = UploadFromURLTask(sourceUrl: url!)
    .checkURLDuplicates(true)
    .saveURLDuplicates(true)
    .store(.doNotstore)
```

### Check the status of a file uploaded from URL ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/fromURLUploadStatus)) ###

```swift
uploadcare.uploadAPI.uploadStatus(forToken: "UPLOAD_TOKEN") { (status, error) in
    if let error = error {
        print(error)
        return
    }
    print(status)
}
```

### File info ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/fileUploadInfo)) ###

```swift
uploadcare.uploadAPI.fileInfo(withFileId: "FILE_UUID") { (file, error) in
    if let error = error {
        print(error)
        return
    }
    print(info)
}
```

### Create files group ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/createFilesGroup)) ###

Uploadcare lib provides 2 methods to create group.

1. Provide files as an array of UploadedFile:

```swift
let files: [UploadedFile] = [file1,file2]
self.uploadcare.uploadAPI.createFilesGroup(files: files) { (response, error) in
    if let error = error {
        print(error)
        return
    }
    print(response)
}
```

2. Provide an array of files UUIDs:

```swift
let filesIds: [String] = ["FILE_UUID1", "FILE_UUID2"]
self.uploadcare.uploadAPI.createFilesGroup(fileIds: filesIds) { (response, error) in
    if let error = error {
        print(error)
        return
    }
    print(response)
}
```

### Files group info ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/filesGroupInfo)) ###

```swift
uploadcare.uploadAPI.filesGroupInfo(groupId: "FILES_GROUP_ID") { (group, error) in
    if let error = error {
        print(error)
        return
    }
    print(group)
}
```

## Useful links

[Uploadcare documentation](https://uploadcare.com/docs/)  
[Upload API reference](https://uploadcare.com/api-refs/upload-api/)  
[REST API reference](https://uploadcare.com/api-refs/rest-api/)  
[Changelog](https://github.com/uploadcare/uploadcare-swift/blob/master/CHANGELOG.md)  
[Security policy](https://github.com/uploadcare/uploadcare-swift/security/policy)  
[Contributing guide](https://github.com/uploadcare/.github/blob/master/CONTRIBUTING.md)  
[Support](https://github.com/uploadcare/.github/blob/master/SUPPORT.md)  
