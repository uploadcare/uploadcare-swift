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
**Direct upload from url:**
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

**Check the status of a file uploaded from URL:**
```swift
uploadcare.uploadAPI.uploadStatus(forToken: "UPLOAD_TOKEN") { (status, error) in
    if let error = error {
        print(error)
        return
    }
    print(status)
}
```

**Direct uploads** ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/baseUpload))
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

**Multipart uploads** ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/multipartFileUploadStart))

Multipart uploads might be used for files with size > 100mb. It contains 3 steps:
1. Start transaction
2. Upload file chunks
3. Complete transaction

You can just use upload method that will make all steps for you:

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

If you want to run these steps manually you can use 3 API methods:
```swift
// start transaction
uploadcare.uploadAPI.startMulipartUpload(withName: "file_name", size: data.count, mimeType: "image/jpeg") { (response, error) in
    // handle response or error
    // response contains presigned urls for chunks and file UUID
}
		
// prepare 5MB Data chunks (5242880 bytes) by yourself. Upload every chunk with:
uploadcare.uploadAPI.uploadIndividualFilePart(chunk, toPresignedUrl: presignedUrl, withMimeType: "image/jpeg")
		
// finish transaction when all chunks was uploaded
uploadcare.uploadAPI.completeMultipartUpload(forFileUIID: "FILE_UUID") { (file, error) in
    // handle result or error
}
```
