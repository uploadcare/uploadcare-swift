# Swift integration for Uploadcare

![license](https://img.shields.io/badge/license-MIT-brightgreen.svg)
![swift](https://img.shields.io/badge/swift-5.1-brightgreen.svg)
[![Build Status](https://travis-ci.com/uploadcare/uploadcare-swift.svg?branch=master)](https://travis-ci.com/uploadcare/uploadcare-swift)

Uploadcare Swift integration handles uploads by wrapping Upload and REST APIs.

Check out [demo](/Demo).

* [Installation](#installation)
* [Initialization](#initialization)
* [Using Upload API](#using-upload-api)
* [Using REST API](#using-rest-api)
* [Useful links](#useful-links)

## Installation

### Swift Package Manager

To use a stable version add a dependency to your Package.swift file:

```swift
dependencies: [
    .package(url: "https://github.com/uploadcare/uploadcare-swift.git", from: "0.1.0")
]
```

If you want to try the current dev version, add a dependency to your Package.swift file:

```swift
dependencies: [
    .package(url: "https://github.com/uploadcare/uploadcare-swift.git", branch("develop"))
]
```

Or you can just add it using Xcode: https://github.com/uploadcare/uploadcare-swift (select master branch)

### Carthage

To use a stable version add a dependency to your Cartfile:

```
github "uploadcare/uploadcare-swift" "0.1.0"
```

To use current dev version:
```
github "uploadcare/uploadcare-swift" "develop"
```

### Cocoapods

To use a stable version add a dependency to your Podfile:
```
pod 'Uploadcare', git: 'https://github.com/uploadcare/uploadcare-swift'
```

To use current dev version:
```
pod 'Uploadcare', git: 'https://github.com/uploadcare/uploadcare-swift', :branch => 'develop'
```

## Initialization

Create your project in [Uploadcare dashboard](https://uploadcare.com/dashboard/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift) and copy its API keys from there.

```swift
let uploadcare = Uploadcare(withPublicKey: "YOUR_PUBLIC_KEY")
// secret key is optional. Initialization with secret key:
let uploadcare = Uploadcare(withPublicKey: "YOUR_PUBLIC_KEY", secretKey: "YOUR_SECRET_KEY")
```

## Using Upload API

Check full [Upload API documentation](https://github.com/uploadcare/uploadcare-swift/blob/master/Documentation/Upload%20API.md) for all available methods.

Some examples:

### Direct uploads ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/baseUpload/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ###

```swift
guard let url = URL(string: "https://source.unsplash.com/random") else { return }
let data = try? Data(contentsOf: url) else { return }

// You can create UploadedFile object to operate with it
let fileForUploading1 = uploadcare.uploadAPI.file(fromData: data)
let fileForUploading2 = uploadcare.uploadAPI.file(withContentsOf: url)

fileForUploading1.upload(withName: "random_file_name.jpg", store: .store) { (result, error) in
    // handle error or result
}

// completion block is optional:
fileForUploading2?.upload(withName: "my_file.jpg", store: .store)

// Or you can just upload data and provide filename
let task = uploadcare.uploadAPI.upload(files: ["random_file_name.jpg": data], store: .store, expire: nil, { (progress) in
    print("upload progress: \(progress * 100)%")
}) { (resultDictionary, error) in
    if let error = error {
        print(error)
        return
    }

    guard let files = result else { return }			
    for file in files {
        print("uploaded file name: \(file.key) | file id: \(file.value)")
    }
}

// you can cancel uploading if need:
task.cancel()
```

### Multipart uploads ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/multipartFileUploadStart/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ###

Multipart Uploads are useful when you are dealing with files larger than 100MB or explicitly want to use accelerated uploads.  Multipart Upload contains 3 steps:
1. Start transaction
2. Upload file chunks
3. Complete transaction

You can use the upload method that will run all 3 steps for you:

```swift
guard let url = Bundle.main.url(forResource: "Mona_Lisa_23mb", withExtension: "jpg") else { return }
let fileForUploading = uploadcare.uploadAPI.file(withContentsOf: url)

// upload without any callbacks
fileForUploading?.upload(withName: "Mona_Lisa_big.jpg")

// uploading with getting data about progress
let task = fileForUploading.upload(withName: "Mona_Lisa_big.jpg", { (progress) in
    print("progress: \(progress)")
}, { (file, error) in
    if let error = error {
        print(error)
        return
    }
    print(file ?? "")
})

// you can cancel uploading if need:
task?.cancel()
```

### Upload files from URLs ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/fromURLUpload/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ###

```swift
let url = URL(string: "https://source.unsplash.com/random")

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
task2.store = .store

// Set parameters using chaining
let task3 = UploadFromURLTask(sourceUrl: url!)
    .checkURLDuplicates(true)
    .saveURLDuplicates(true)
    .store(.store)
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


## Using REST API

Check full [REST API documentation](https://github.com/uploadcare/uploadcare-swift/blob/master/Documentation/REST%20API.md) for all available methods.

Some examples:

### Initialization

REST API requires both public and secret key:
```swift
let uploadcare = Uploadcare(withPublicKey: "YOUR_PUBLIC_KEY", secretKey: "YOUR_SECRET_KEY")
```

### Get list of files ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/filesList?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ###

```swift
// Make query object
let query = PaginationQuery()
    .stored(true)
    .ordering(.sizeDESC)
    .limit(5)
// Make files list object
let filesList = uploadcare.list()

// Get files list
filesList.get(withQuery: query) { (list, error) in
    if let error = error {
        print(error)
        return
    }
			
    print(list ?? "")
}
```
Get next page:
```swift
// check if next page is available
guard filesList.next != nil else { return }
// get next page
filesList.nextPage { (list, error) in
    if let error = error {
        print(error)
        return
    }	
    print(list ?? "")
}
```

Get previous page:
```swift
// check if previous page is available
guard filesList.previous != nil else { return }
// get next page
filesList.previousPage { (list, error) in
    if let error = error {
        print(error)
        return
    }	
    print(list ?? "")
}
```

### File Info ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/fileInfo?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ###

```swift
uploadcare.fileInfo(withUUID: "1bac376c-aa7e-4356-861b-dd2657b5bfd2") { (file, error) in
    if let error = error {
        print(error)
        return
    }		
    print(file ?? "")
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
