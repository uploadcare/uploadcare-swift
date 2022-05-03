# Swift API client for Uploadcare

![license](https://img.shields.io/badge/license-MIT-brightgreen.svg)
![swift](https://img.shields.io/badge/swift-5.1-brightgreen.svg)
[![Build Status](https://travis-ci.com/uploadcare/uploadcare-swift.svg?branch=master)](https://travis-ci.com/uploadcare/uploadcare-swift)

Uploadcare Swift API client for iOS, iPadOS, tvOS, macOS, and Linux handles uploads and further operations with files by wrapping Uploadcare Upload and REST APIs.

Check out our [Demo App](/Demo).

* [Installation](#installation)
* [Initialization](#initialization)
* [Using Upload API](#using-upload-api)
* [Using REST API](#using-rest-api)
* [Demo app](#demo-app)
* [Useful links](#useful-links)

## Installation

### Swift Package Manager

To use a stable version, add a dependency to your Package.swift file:

```swift
dependencies: [
    .package(url: "https://github.com/uploadcare/uploadcare-swift.git", .branch("master"))
]
```

If you want to try the current dev version, change dependency to:

```swift
dependencies: [
    .package(url: "https://github.com/uploadcare/uploadcare-swift.git", branch("develop"))
]
```

To add from Xcode select File -> Swift Packages -> Add Package Dependency and enter repository URL:
```
https://github.com/uploadcare/uploadcare-swift
```

Or you can add it in Xcode: https://github.com/uploadcare/uploadcare-swift (select master branch).

### Carthage

To use a stable version, add a dependency to your Cartfile:

```
github "uploadcare/uploadcare-swift"
```

To use the current dev version:

```
github "uploadcare/uploadcare-swift" "develop"
```

### Cocoapods

To use a stable version, add a dependency to your Podfile:

```
pod 'Uploadcare', git: 'https://github.com/uploadcare/uploadcare-swift'
```

To use current dev version:

```
pod 'Uploadcare', git: 'https://github.com/uploadcare/uploadcare-swift', :branch => 'develop'
```

## Initialization

Create your project in [Uploadcare dashboard](https://uploadcare.com/dashboard/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift) and copy its API keys from there.

Upload API requires only a public key, while REST API requires both public and secret keys:

```swift
let uploadcare = Uploadcare(withPublicKey: "YOUR_PUBLIC_KEY")
// Secret key is optional. Initialization with secret key:
let uploadcare = Uploadcare(withPublicKey: "YOUR_PUBLIC_KEY", secretKey: "YOUR_SECRET_KEY")
```

## Using Upload API

Check the [Upload API documentation](https://github.com/uploadcare/uploadcare-swift/blob/master/Documentation/Upload%20API.md) to see all available methods.

Example of uploads:

```swift
guard let url = URL(string: "https://source.unsplash.com/random") else { return }
guard let data = try? Data(contentsOf: url) else { return }

// You can create UploadedFile object to operate with it
let fileForUploading1 = uploadcare.file(fromData: data)
let fileForUploading2 = uploadcare.file(withContentsOf: url)

// Handle error or result
fileForUploading1.upload(withName: "random_file_name.jpg", store: .store) { (result, error) in
}

// Completion block is optional
fileForUploading2?.upload(withName: "my_file.jpg", store: .store)

// Or you can just upload data and provide a filename
let task = uploadcare.uploadFile(data, withName: "random_file_name.jpg", store: .store) { progress in
    print("upload progress: \(progress * 100)%")
} _: { file, error in
    if let error = error {
	print(error.detail)
	return
    }

    print(file ?? "Error: no file")
}
// You can cancel uploading if needed
task.cancel()

// task will confirm UploadTaskable protocol if file size is less than 100 mb, and UploadTaskResumable if file size is >= 100mb
// You can pause or resume uploading of file with size >= 100mb if needed
(task as? UploadTaskResumable)?.pause()
(task as? UploadTaskResumable)?.resume()
```

## Using REST API

Refer to the [REST API documentation](https://github.com/uploadcare/uploadcare-swift/blob/master/Documentation/REST%20API.md) for all methods.

Example of getting list of files:

```swift
// Make a query object
let query = PaginationQuery()
    .stored(true)
    .ordering(.sizeDESC)
    .limit(5)
// Make a list of files object
let filesList = uploadcare.list()

// Get file list
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
// Check if the next page is available
guard filesList.next != nil else { return }
// Get the next page
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
// Check if the previous page is available
guard filesList.previous != nil else { return }
// Get the previous page
filesList.previousPage { (list, error) in
    if let error = error {
        print(error)
        return
    }	
    print(list ?? "")
}
```

## Demo app

Check the [demo app](https://github.com/uploadcare/uploadcare-swift/tree/master/Demo) for usage examples: 
* List of files
* List of groups
* File info
* File upload (both direct and multipart, including upload in background)
* Multiple file upload
* Pause and continue multipart uploading
* Project info

## Useful links

[Swift Upload API client documentation](https://github.com/uploadcare/uploadcare-swift/blob/master/Documentation/Upload%20API.md)  
[Swift REST API client documentation](https://github.com/uploadcare/uploadcare-swift/blob/master/Documentation/REST%20API.md)  
[Uploadcare documentation](https://uploadcare.com/docs/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)  
[Upload API reference](https://uploadcare.com/api-refs/upload-api/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)  
[REST API reference](https://uploadcare.com/api-refs/rest-api/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)  
[Changelog](https://github.com/uploadcare/uploadcare-swift/blob/master/CHANGELOG.md)  
[Contributing guide](https://github.com/uploadcare/.github/blob/master/CONTRIBUTING.md)  
[Security policy](https://github.com/uploadcare/uploadcare-swift/security/policy)  
[Support](https://github.com/uploadcare/.github/blob/master/SUPPORT.md)  
