# Upload API

* [Initialization](#initialization)
* [File upload](#file-upload)
* [Direct uploads](#direct-uploads-api-reference)
* [Multipart uploads](#multipart-uploads-api-reference)
* [Background uploads](#background-uploads)
* [Upload files from URLs](#upload-files-from-urls-api-reference)
* [Check the status of a file uploaded from URL](#check-the-status-of-a-file-uploaded-from-url-api-reference)
* [File info](#file-info-api-reference)
* [Create files group](#create-files-group-api-reference)
* [Files group info](#files-group-info-api-reference)
* [Secure uploads](#secure-uploads-api-reference)

## Initialization

Create Uploadcare project in the [dashboard](https://app.uploadcare.com/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift) and copy its API keys from there.

Upload API requires only a public key:

```swift
final class MyClass {
    private var uploadcare: Uploadcare
    
    init() {
        self.uploadcare = Uploadcare(withPublicKey: "YOUR_PUBLIC_KEY")
        
        // Secret key is optional for Upload API
        // But you still can provide it if you want to use both Upload API and REST API:
        self.uploadcare = Uploadcare(withPublicKey: "YOUR_PUBLIC_KEY", secretKey: "YOUR_SECRET_KEY")
    }
}
```

You can create more than Uploadcare objects if you need to work with multiple projects on your Uploadcare account:

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

## File upload ##
Uploadcare provides a simple method that will handle file upload. It decides internally the best way to upload a file (to use direct or multipart upload).

```swift
guard let url = Bundle.main.url(forResource: "Mona_Lisa_23mb", withExtension: "jpg") else { return }
guard let data = try? Data(contentsOf: url) else { return }

// Async:
let file = try await uploadcare.uploadFile(data, withName: "random_file_name.jpg", store: .doNotStore) { progress in
    print("progress: \(progress)")
}

// With completion callback:
let task = uploadcare.uploadFile(data, withName: "some_file.ext", store: .doNotStore, metadata: ["someKey": "someMetaValue"]) { progress in
    print("progress: \(progress)")
} _: { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let file):
        print(file)
    }
}

// You can cancel uploading if needed
task.cancel()

// You can pause uploading
(task as? UploadTaskResumable)?.pause()

// To resume uploading
(task as? UploadTaskResumable)?.resume()
```

If you want to create a file object (alternative syntax):
```swift
// Async:
var fileForUploading = uploadcare.file(withContentsOf: url)!
fileForUploadingfileForUploading.metadata = ["myKey": "myValue"]
let file = try await fileForUploading.upload(withName: "random_file_name.jpg", store: .doNotStore)

var fileForUploading2 = uploadcare.file(withContentsOf: url)!
fileForUploading2.metadata = ["myKey": "myValue"]

// progress and completion callbacks are optional
fileForUploading2.upload(withName: "my_file.jpg", store: .store)
```

Sometimes you don't want to have the secret key in your client app and want to get it from backend. In that case you can provide upload signature directly:

```swift
let signature = UploadSignature(signature: "signature", expire: 1658486910)
let task = uploadcare.uploadFile(data, withName: "some_file.ext", store: .doNotStore, uploadSignature: signature) { progress in
    print("progress: \(progress)")
} _: { result in
    ...
}
```

## Direct uploads ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/baseUpload/)) ##

Direct uploads work with background URLSession, so uploading will continue if the app goes to the background state. It support files smaller than 100MB only

```swift
guard let url = URL(string: "https://source.unsplash.com/featured"),
      let data = try? Data(contentsOf: url) else { return }
      
let task = uploadcare.uploadAPI.directUpload(files:  ["random_file_name.jpg": data], store: .store, metadata: ["someKey": "someMetaValue"]) { progress in
    print("upload progress: \(progress * 100)%")
} _: { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let files):
        for file in files {
            print("uploaded file name: \(file.key) | file id: \(file.value)")
        }
    }
}

// You can cancel uploading if needed
task.cancel()
```

Sometimes you don't want to have the secret key in your client app and want to get it from backend. In that case you can provide upload signature directly:

```swift
guard let url = URL(string: "https://source.unsplash.com/featured"),
      let data = try? Data(contentsOf: url) else { return }
      
let signature = UploadSignature(signature: "signature", expire: 1658486910)
let task = uploadcare.uploadAPI.directUpload(files:  ["random_file_name.jpg": data], store: .store, uploadSignature: signature) { progress in
    print("upload progress: \(progress * 100)%")
} _: { result in
    /// ...
}
```

## Multipart uploads ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/multipartFileUploadStart/)) ##

Multipart Uploads are useful when you are dealing with files larger than 100MB or you explicitly want to accelerate uploads. Each Multipart Upload contains 3 steps:
1. Start transaction
2. Upload file chunks concurrently
3. Complete transaction

You can use this upload method and it'll run all 3 steps for you:

```swift
guard let url = Bundle.main.url(forResource: "Mona_Lisa_23mb", withExtension: "jpg") else { return }
let data = try! Data(contentsOf: url)

let task = uploadcare.uploadAPI.multipartUpload(data, withName: "Mona_Lisa_big.jpg", store: .store, metadata: ["someKey": "someMetaValue"]) { progress in
    print("progress: \(progress)")
} _: { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let file):
        print(file)
    }
}

// You can cancel uploading if needed
task.cancel()

// You can pause uploading
task.pause()

// To resume uploading
task.resume()
```

## Background uploads

It is possible to perform uploads in background. But implementation is a platform-specific. This lib doesn't provide default implementation. You can find an example for the iOS in our Demo app. See [FilesListStore.swift](https://github.com/uploadcare/uploadcare-swift/blob/1e6341edcdcb887589a4e798b746c525c9023b4e/Demo/Demo/Modules/FilesListStore.swift).

Direct upload method works with background URLSession, so uploading will continue if the app goes to the background state.

## Upload files from URLs ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/fromURLUpload/)) ##

```swift
guard let url = URL(string: "https://source.unsplash.com/featured") else { return }

// Set parameters by accessing properties
let task1 = UploadFromURLTask(sourceUrl: url)
task1.checkURLDuplicates = true
task1.saveURLDuplicates = true
task1.store = .store

// Or set parameters using chaining
let task2 = UploadFromURLTask(sourceUrl: url)
    .checkURLDuplicates(true)
    .saveURLDuplicates(true)
    .store(.store)
    .setMetadata("myValue", forKey: "someKey")

// Upload
uploadcare.uploadAPI.upload(task: task1) { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let response):
        print(response)
        
		// Upload token that you can use to check status
		let token = result?.token
    }
}
```

Sometimes you don't want to have the secret key in your client app and want to get it from backend. In that case you can provide upload signature directly:
```swift
let signature = UploadSignature(signature: "signature", expire: 1658486910)
uploadcare.uploadAPI.upload(task: task1) { result in
    // ...
}
```


## Check the status of a file uploaded from URL ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/fromURLUploadStatus/)) ##

Use a token recieved with Upload files from the URLs method:

```swift
uploadcare.uploadAPI.uploadStatus(forToken: "UPLOAD_TOKEN") { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let status):
        print(status)
    }
}
```

## File info ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/fileUploadInfo/)) ##

```swift
uploadcare.uploadAPI.fileInfo(withFileId: "FILE_UUID") { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let file):
        print(file)
    }
}
```

## Create files group ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/createFilesGroup/)) ##

Uploadcare library provides 2 methods to create a group:

1. Provide files as an array of UploadedFile:

```swift
let files: [UploadedFile] = [file1,file2]
uploadcare.uploadAPI.createFilesGroup(files: files) { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let group):
        print(group)
    }
}
```

2. Provide an array of file UUIDs:

```swift
let filesIds: [String] = ["FILE_UUID1", "FILE_UUID2"]
uploadcare.uploadAPI.createFilesGroup(fileIds: filesIds) { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let group):
        print(group)
    }
}
```

Sometimes you don't want to have the secret key in your client app and want to get it from backend. In that case you can provide upload signature directly:
```swift
let signature = UploadSignature(signature: "signature", expire: 1658486910)
uploadcare.uploadAPI.createFilesGroup(files: files) { result in
    // ...
}
// or
uploadcare.uploadAPI.createFilesGroup(fileIds: filesIds) { result in
    // ...
}
```

## Files group info ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/filesGroupInfo/)) ##

```swift
uploadcare.uploadAPI.filesGroupInfo(groupId: "FILES_GROUP_ID") { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let group):
        print(group)
    }
}
```

Sometimes you don't want to have the secret key in your client app and want to get it from backend. In that case you can provide upload signature directly:

```swift
let signature = UploadSignature(signature: "signature", expire: 1658486910)
uploadcare.uploadAPI.filesGroupInfo(groupId: "FILES_GROUP_ID") { result in
    // ...
}
```

## Secure uploads ([API Reference](https://uploadcare.com/docs/api_reference/upload/signed_uploads/)) ##

Signing requests works by default if a Secret key is provided during SDK initialization. SDK generates a signature internally, and this signature stays valid for 30 minutes. New signatures are generated automatically when older ones expire.

Note that Signed Uploads should be enabled in the project’s settings in your [Uploadcare dashboard](https://uploadcare.com/dashboard/).
