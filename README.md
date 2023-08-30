# Swift API client for Uploadcare

![license](https://img.shields.io/badge/license-MIT-brightgreen.svg)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fuploadcare%2Fuploadcare-swift%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/uploadcare/uploadcare-swift)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fuploadcare%2Fuploadcare-swift%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/uploadcare/uploadcare-swift)
[![Build and test](https://github.com/uploadcare/uploadcare-swift/actions/workflows/test.yml/badge.svg)](https://github.com/uploadcare/uploadcare-swift/actions/workflows/test.yml)

Uploadcare Swift API client for iOS, iPadOS, tvOS and macOS handles uploads and further operations with files by wrapping Uploadcare Upload and REST APIs.

Check out our [Demo App](/Demo).

* [Installation](#installation)
* [Initialization](#initialization)
* [Using Upload API](#using-upload-api)
* [Using REST API](#using-rest-api)
* [Demo app](#demo-app)
* [Useful links](#useful-links)

## Installation

### Swift Package Manager

To use a stable version, add a dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/uploadcare/uploadcare-swift.git", .branch("master"))
]
```

If you want to try the current dev version, change the dependency to:

```swift
dependencies: [
    .package(url: "https://github.com/uploadcare/uploadcare-swift.git", branch("develop"))
]
```

To add from Xcode select File -> Swift Packages -> Add Package Dependency and enter the repository URL:
```
https://github.com/uploadcare/uploadcare-swift
```

Or you can add it in Xcode to the packages list using that URL: https://github.com/uploadcare/uploadcare-swift (select master branch).

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
final class MyClass {
    private var uploadcare: Uploadcare
    
    init() {
        self.uploadcare = Uploadcare(withPublicKey: "YOUR_PUBLIC_KEY")
        
        // Secret key is optional if you want to use Upload API only.
        // REST API requires both public and secret keys:
        self.uploadcare = Uploadcare(withPublicKey: "YOUR_PUBLIC_KEY", secretKey: "YOUR_SECRET_KEY")
    }
}
```

You can create more Uploadcare objects if you need to work with multiple projects in your Uploadcare account:

```swift
final class MyClass {
    private let project1: Uploadcare
    private let project2: Uploadcare
    
    init() {
        // A project to use Upload API only 
        self.project1 = Uploadcare(withPublicKey: "YOUR_PUBLIC_KEY_1")

        // A project to use both REST API and Upload API
        self.project2 = Uploadcare(withPublicKey: "YOUR_PUBLIC_KEY_2", secretKey: "YOUR_SECRET_KEY_2")
    }
}
```

Keep in mind that since Uploadcare is not a singleton. You should store a strong reference (as an instance variable, for example) to your Uploadcare object or it will get deallocated.

## Using Upload API

Check the [Upload API documentation](https://github.com/uploadcare/uploadcare-swift/blob/master/Documentation/Upload%20API.md) to see all available methods. Each method has an implementation with a `Result` completion handler and has an alternative `async` implementation to use with Swift concurrency.

Example of uploads:

```swift
guard let url = URL(string: "https://source.unsplash.com/featured") else { return }
guard let data = try? Data(contentsOf: url) else { return }

// You can create an UploadedFile object to operate with it
var fileForUploading1 = uploadcare.file(fromData: data)
fileForUploading2.metadata = ["myKey": "myValue"]
try await fileForUploading1.upload(withName: "random_file_name.jpg", store: .auto)

// Or you can just upload data and provide a filename

var fileForUploading2 = uploadcare.file(withContentsOf: url)!
let file = try await uploadcare.uploadFile(data, withName: "random_file_name.jpg", store: .auto) { progress in
    print("upload progress: \(progress * 100)%")
}

// Same method with a completion callback that returns a task that can be paused or canceled:
let task = uploadcare.uploadFile(data, withName: "random_file_name.jpg", store: .auto, metadata: ["someKey": "someMetaValue"]) { progress in
    print("upload progress: \(progress * 100)%")
} _: { result in
    switch result {
    case .failure(let error):
        print(error.detail)
    case .success(let file):
        print(file)
    }
}
// Cancel uploading if needed
task.cancel()

// task will confirm UploadTaskable protocol if file size is less than 100 mb, and UploadTaskResumable if file size is >= 100mb
// You can pause or resume uploading of file with size >= 100mb if needed
(task as? UploadTaskResumable)?.pause()
(task as? UploadTaskResumable)?.resume()
```

It is possible to perform uploads in the background. But implementation is platform-specific. This lib doesn't provide a default implementation. You can find an example for the iOS in our Demo app. See [FilesListStore.swift](https://github.com/uploadcare/uploadcare-swift/blob/1e6341edcdcb887589a4e798b746c525c9023b4e/Demo/Demo/Modules/FilesListStore.swift).

## Using REST API

Refer to the [REST API documentation](https://github.com/uploadcare/uploadcare-swift/blob/master/Documentation/REST%20API.md) for all methods. Each method has an implementation with a `Result` completion handler and has an alternative `async` implementation to use with Swift concurrency.

Example of getting list of files:

```swift
// Make a list of files object
lazy var filesList = uploadcare.listOfFiles()

func someFilesListMethod() {
    // Make a query object
    let query = PaginationQuery()
        .stored(true)
        .ordering(.dateTimeUploadedDESC)
        .limit(5)

    // Get file list
    let list = try await filesList.get(withQuery: query)
    
    // Same method with a completion callback.
    filesList.get(withQuery: query) { result in
        switch result {
        case .failure(let error):
            print(error)
        case .success(let list):
            print(list)
        }
    }
}
```

Get next page:

```swift
// Check if the next page is available
guard filesList.next != nil else { return }

// Async:
let next = try await filesList.nextPage()

// With a completion callback:
filesList.nextPage { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let list):
        print(list)
    }
}
```

Get previous page:

```swift
// Check if the previous page is available
guard filesList.previous != nil else { return }

// Async:
let previous = try await filesList.previousPage()

// With a completion callback:
filesList.previousPage { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let list):
        print(list)
    }
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
[REST API reference](https://uploadcare.com/api-refs/rest-api/v0.7.0/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)  
[Contributing guide](https://github.com/uploadcare/.github/blob/master/CONTRIBUTING.md)  
[Security policy](https://github.com/uploadcare/uploadcare-swift/security/policy)  
[Support](https://github.com/uploadcare/.github/blob/master/SUPPORT.md)  
