# Upload API

* [Initialization](#initialization)
* [Direct uploads](#direct-uploads-api-reference)
* [Multipart uploads](#multipart-uploads-api-reference)
* [Upload files from URLs](#upload-files-from-urls-api-reference)
* [Check the status of a file uploaded from URL](#check-the-status-of-a-file-uploaded-from-url-api-reference)
* [File info](#file-info-api-reference)
* [Create files group](#create-files-group-api-reference)
* [Files group info](#files-group-info-api-reference)
* [Secure uploads](#secure-uploads-api-reference)

## Initialization

Upload API requires only a public key:

```swift
let uploadcare = Uploadcare(withPublicKey: "YOUR_PUBLIC_KEY")
```

## Direct uploads ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/baseUpload/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ##

Direct uploads work with background URLSession, so uploading will continue if the app goes to the background state.

```swift
guard let url = URL(string: "https://source.unsplash.com/random") else { return }
let data = try? Data(contentsOf: url) else { return }

// You can create UploadedFile object to operate with it
let fileForUploading1 = uploadcare.uploadAPI.file(fromData: data)
let fileForUploading2 = uploadcare.uploadAPI.file(withContentsOf: url)

// Handle error or result
fileForUploading1.upload(withName: "random_file_name.jpg", store: .store) { (result, error) in
}

// Completion block is optional
fileForUploading2?.upload(withName: "my_file.jpg", store: .store)

// Or you can just upload data and provide a filename
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

// You can cancel uploading if needed
task.cancel()
```

## Multipart uploads ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/multipartFileUploadStart/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ##

Multipart Uploads are useful when you are dealing with files larger than 100MB or you explicitly want to accelerate uploads. Each Multipart Upload contains 3 steps:
1. Start transaction
2. Upload file chunks concurrently
3. Complete transaction

You can use this upload method and it'll run all 3 steps for you:

```swift
guard let url = Bundle.main.url(forResource: "Mona_Lisa_23mb", withExtension: "jpg") else { return }
let fileForUploading = uploadcare.uploadAPI.file(withContentsOf: url)

// Upload without any callbacks
fileForUploading?.upload(withName: "Mona_Lisa_big.jpg")

// Upload with getting data about progress
let task = fileForUploading.upload(withName: "Mona_Lisa_big.jpg", { (progress) in
    print("progress: \(progress)")
}, { (file, error) in
    if let error = error {
        print(error)
        return
    }
    print(file ?? "")
})

// You can cancel uploading if needed
task?.cancel()

// You can pause uploading
task?.pause()

// To resume uploading
task?.resume()
```

## Upload files from URLs ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/fromURLUpload/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ##

```swift
guard let url = URL(string: "https://source.unsplash.com/random") else { return }
let task1 = UploadFromURLTask(sourceUrl: url)

// Upload
uploadcare.uploadAPI.upload(task: task1) { [unowned self] (result, error) in
    if let error = error {
        print(error)
        return
    }
    print(result)
}
```

UploadFromURLTask is used to store upload parameters:

```swift
// Set parameters by accessing properties
let task2 = UploadFromURLTask(sourceUrl: url!)
task2.store = .store

// Set parameters by using chaining
let task3 = UploadFromURLTask(sourceUrl: url!)
    .checkURLDuplicates(true)
    .saveURLDuplicates(true)
    .store(.store)
```

## Check the status of a file uploaded from URL ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/fromURLUploadStatus/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ##

Use a token recieved with Upload files from the URLs method:

```swift
uploadcare.uploadAPI.uploadStatus(forToken: "UPLOAD_TOKEN") { (status, error) in
    if let error = error {
        print(error)
        return
    }
    print(status)
}
```

## File info ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/fileUploadInfo/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ##

```swift
uploadcare.uploadAPI.fileInfo(withFileId: "FILE_UUID") { (file, error) in
    if let error = error {
        print(error)
        return
    }
    print(info)
}
```

## Create file group ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/createFilesGroup/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ##

Uploadcare library provides 2 methods to create a group:

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

2. Provide an array of file UUIDs:

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

## Files group info ([API Reference](https://uploadcare.com/api-refs/upload-api/#operation/filesGroupInfo/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ##

```swift
uploadcare.uploadAPI.filesGroupInfo(groupId: "FILES_GROUP_ID") { (group, error) in
    if let error = error {
        print(error)
        return
    }
    print(group)
}
```

## Secure uploads ([API Reference](https://uploadcare.com/docs/api_reference/upload/signed_uploads/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ##

Signing requests works by default if a Secret key is provided during SDK initialization. SDK generates a signature internally, and this signature stays valid for 30 minutes. New signatures are generated automatically when older ones expire.

Note that Signed Uploads should be enabled in the project’s settings in your [Uploadcare dashboard](https://uploadcare.com/dashboard/).
