# uploadcare-swift

Work in progress.


Dependency managers support:
- [x] Swift Package Manager
- [x] Carthage
- [x] CocoaPods

Check DemoApp dir for demo app.

## Installation

### Swift Package Manager
To use stable version add a dependency to you Package.swift file:
```swift
dependencies: [
    .package(url: "https://github.com/uploadcare/uploadcare-swift.git", from: "1.0.0")
]
```

If you want to try current dev version add a dependency to you Package.swift file:
```swift
dependencies: [
    .package(url: "https://github.com/uploadcare/uploadcare-swift.git", branch("develop"))
]
```

Add repo url in Xcode: https://github.com/uploadcare/uploadcare-swift


### Carthage
TBD

### Cocoapods
TBD

## Initialization
```swift
let uploadcare = Uploadcare(withPublicKey: "YOUR_PUBLIC_KEY", secretKey: "YOUR_SECRET_KEY")
```

## Using REST API
Direct upload from url:
```swift
let url = URL(string: "https://ucarecdn.com/assets/images/cloud.6b86b4f1d77e.jpg")
let task = UploadFromURLTask(sourceUrl: url!)
    .checkURLDuplicates(true)
    .saveURLDuplicates(true)
    .store(.store)
uploadcare.uploadAPI.upload(task: task) { [unowned self] (result, error) in
    if let error = error {
        print(error)
        return
    }
    print(result)
}
```

Check the status of a file uploaded from URL:
```swift
uploadcare.uploadAPI.uploadStatus(forToken: "UPLOAD_TOKEN") { (status, error) in
    if let error = error {
        print(error)
        return
    }
    print(status)
}
```
