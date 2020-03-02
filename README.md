# [WIP] Swift integration for Uploadcare

![license](https://img.shields.io/badge/license-MIT-brightgreen.svg)
![swift](https://img.shields.io/badge/swift-5.1-brightgreen.svg)

Uploadcare Swift integration handles uploads _(and further operations with files)_ by wrapping Upload _(and REST, which is currently work in progress)_ APIs.

GIF TBD

Check out [demo app](/DemoApp).

* [Installation](#installation)
* [Initialization](#initialization)
* [Using Upload API](#using-upload-api)
* [Useful links](#useful-links)

## Installation

### Swift Package Manager

To use a stable version add a dependency to your Package.swift file:

```swift
dependencies: [
    .package(url: "https://github.com/uploadcare/uploadcare-swift.git", from: "1.0.0")
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

Create your project in [Uploadcare dashboard](https://uploadcare.com/dashboard/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift) and copy its API keys from there.

```swift
let uploadcare = Uploadcare(withPublicKey: "YOUR_PUBLIC_KEY", secretKey: "YOUR_SECRET_KEY")
```

## Using Upload API

### Direct uploads ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/baseUpload/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ###

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

### Multipart uploads ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/multipartFileUploadStart/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ###

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

### Upload files from URLs ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/fromURLUpload/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ###

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

### Check the status of a file uploaded from URL ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/fromURLUploadStatus/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ###

```swift
uploadcare.uploadAPI.uploadStatus(forToken: "UPLOAD_TOKEN") { (status, error) in
    if let error = error {
        print(error)
        return
    }
    print(status)
}
```

### File info ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/fileUploadInfo/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ###

```swift
uploadcare.uploadAPI.fileInfo(withFileId: "FILE_UUID") { (file, error) in
    if let error = error {
        print(error)
        return
    }
    print(info)
}
```

### Create files group ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/createFilesGroup/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ###

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

### Files group info ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/filesGroupInfo/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ###

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

[Uploadcare documentation](https://uploadcare.com/docs/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)  
[Upload API reference](https://uploadcare.com/api-refs/upload-api/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)  
[REST API reference](https://uploadcare.com/api-refs/rest-api/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)  
[Changelog](https://github.com/uploadcare/uploadcare-swift/blob/master/CHANGELOG.md)  
[Contributing guide](https://github.com/uploadcare/.github/blob/master/CONTRIBUTING.md)  
[Security policy](https://github.com/uploadcare/uploadcare-swift/security/policy)  
[Support](https://github.com/uploadcare/.github/blob/master/SUPPORT.md)  
