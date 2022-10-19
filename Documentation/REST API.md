# REST API

* [Initialization](#initialization)
* [List of files](#list-of-files-api-reference)
* [File info](#file-info-api-reference)
* [File metadata](#file-metadata-api-reference)
* [Store files](#store-files-api-reference)
* [Delete files](#delete-files-api-reference)
* [Copy file to local storage](#copy-file-to-local-storage-api-reference)
* [Copy file to remote storage](#copy-file-to-remote-storage-api-reference)
* [List of groups](#list-of-groups-api-reference)
* [Group info](#group-info-api-reference) 
* [Delete group](#delete-group-api-reference)
* [Project info](#project-info-api-reference)
* [Secure delivery](#secure-delivery-api-reference)
* [List of webhooks](#list-of-webhooks-api-reference)
* [Create webhook](#create-webhook-api-reference)
* [Update webhook](#update-webhook-api-reference)
* [Delete webhook](#delete-webhook-api-reference)
* [Convert document](#convert-document-api-reference)
* [Document conversion job status](#document-conversion-job-status-api-reference)
* [Convert video](#convert-video-api-reference)
* [Video conversion job status](#video-conversion-job-status-api-reference)
* [Add-Ons](#add-ons-api-reference)


## Initialization

Create Uploadcare project in the [dashboard](https://app.uploadcare.com/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift) and copy its API keys from there.

REST API requires both public and secret keys:

```swift
final class MyClass {
    private var uploadcare: Uploadcare
    
    init() {
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
        self.project1 = Uploadcare(withPublicKey: "YOUR_PUBLIC_KEY_1", secretKey: "YOUR_SECRET_KEY_1")

        // A project to use both REST API and Upload API
        self.project2 = Uploadcare(withPublicKey: "YOUR_PUBLIC_KEY_2", secretKey: "YOUR_SECRET_KEY_2")
    }
}
```

Keep in mind that since Uploadcare is not a singleton. You should store a strong reference (as an instance variable, for example) to your Uploadcare object or it will get deallocated.

## List of files ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/filesList)) ##

```swift
// Make a list of files object
lazy var filesList = uploadcare.listOfFiles()

// Make a query object
let query = PaginationQuery()
    .stored(true)
    .ordering(.dateTimeUploadedDESC)
    .limit(5)

// Get file list
filesList.get(withQuery: query) { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let list):
        print(list)
    }
}
```

Get next page:

```swift
// Check if the next page is available
guard filesList.next != nil else { return }
// Get the next page
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
// Get the previous page
filesList.previousPage { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let list):
        print(list)
    }
}
```

## File info ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/fileInfo)) ##

```swift
uploadcare.fileInfo(withUUID: "1bac376c-aa7e-4356-861b-dd2657b5bfd2") { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let file):
        print(file)
    }
}

// with query
let fileInfoQuery = FileInfoQuery().include(.appdata)
uploadcare.fileInfo(withUUID: "1bac376c-aa7e-4356-861b-dd2657b5bfd2", withQuery: fileInfoQuery) { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let file):
        print(file)
    }
}
```

## File metadata ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata)) ##

Get file’s metadata:
```swift
uploadcare.fileMetadata(withUUID: "1bac376c-aa7e-4356-861b-dd2657b5bfd2") { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let metadataDictionary):
        print(metadataDictionary)
    }
}
```

Get metadata key's value:
```swift
uploadcare.fileMetadataValue(forKey: "myMeta", withUUID: "1bac376c-aa7e-4356-861b-dd2657b5bfd2") { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let value):
        print(value)
    }
}
```

Update metadata key's value.  If the key does not exist, it will be created:
```swift
uploadcare.updateFileMetadata(withUUID: "1bac376c-aa7e-4356-861b-dd2657b5bfd2", key: "myMeta", value: "myValue") { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let value):
        print(value)
    }
}
```

Delete metadata key:
```swift
uploadcare.deleteFileMetadata(forKey: "myMeta", withUUID: "1bac376c-aa7e-4356-861b-dd2657b5bfd2") { error in
    if let error = error { 
        print(error)
    }
}
```

## Store files ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/storeFile)) ##

Store an individual file:

```swift
uploadcare.storeFile(withUUID: "1bac376c-aa7e-4356-861b-dd2657b5bfd2") { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let file):
        print(file)
    }
}
```

Batch file storing:

```swift
let uuids = ["b7a301d1-1bd0-473d-8d32-708dd55addc0", "1bac376c-aa7e-4356-861b-dd2657b5bfd2"]
uploadcare.storeFiles(withUUIDs: uuids) { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let response):
        print(response)
    }
}
```

## Delete files ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/deleteFileStorage)) ##

Delete an individual file:

```swift
uploadcare.deleteFile(withUUID: "1bac376c-aa7e-4356-861b-dd2657b5bfd2") { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let file):
        print(file)
    }
}
```

Batch file delete:

```swift
let uuids = ["b7a301d1-1bd0-473d-8d32-708dd55addc0", "1bac376c-aa7e-4356-861b-dd2657b5bfd2"]
uploadcare.deleteFiles(withUUIDs: uuids) { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let response):
        print(response)
    }
}
```

## Copy file to local storage ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/createLocalCopy)) ##

```swift
uploadcare.copyFileToLocalStorage(source: "6ca619a8-70a7-4777-8de1-7d07739ebbd9") { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let response):
        print(response)
    }
}
```

## Copy file to remote storage ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/createRemoteCopy)) ##

```swift
let source = "99c48392-46ab-4877-a6e1-e2557b011176"
uploadcare.copyFileToRemoteStorage(source: source, target: "one_more_project", makePublic: true, pattern: .uuid) { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let response):
        print(response)
    }
}
```

## List of groups ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/groupsList)) ##

```swift
let query = GroupsListQuery()
    .limit(100)
    .ordering(.datetimeCreatedDESC)

uploadcare.listOfGroups(withQuery: query) { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let list):
        print(list)
    }
}

// Using a GroupsList object
let groupsList = uploadcare.listOfGroups()

groupsList.get(withQuery: query) { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let list):
        print(list)
    }
}

// Get the next page
groupsList.nextPage { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let list):
        print(list)
    }
}

// Get the previous page
groupsList.previousPage { result in			
    switch result {
    case .failure(let error):
        print(error)
    case .success(let list):
        print(list)
    }
}
```

## Group info ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/groupInfo)) ##

```swift
uploadcare.groupInfo(withUUID: "c5bec8c7-d4b6-4921-9e55-6edb027546bc~1") { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let group):
        print(group)
    }
}
```

## Delete group ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/deleteGroup)) ##
```swift
uploadcare.deleteGroup(withUUID: "groupId") { error in
    if let error = error {
        print(error)
    }
}
```

## Project info ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/projectInfo)) ##

```swift
uploadcare.getProjectInfo { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let project):
        print(project)
    }
}
```

## Secure delivery ([API Reference](https://uploadcare.com/docs/delivery/file_api/#authenticated-urls)) ##

This method allows you to get an authenticated URL from your backend by using redirect.
To answer a request to that URL, your backend should generate an authenticated URL to your file and perform REDIRECT to a generated URL. A redirected URL will be caught and returned in the completion handler of that method.

Example: https://yourdomain.com/{UUID}/ — backend redirects to https://cdn.yourdomain.com/{uuid}/?token={token}&expire={timestamp}.

```swift
let url = URL(string: "https://yourdomain.com/FILE_UUID/")!
uploadcare.getAuthenticatedUrlFromUrl(url) { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let value):
        // Value is https://cdn.yourdomain.com/{uuid}/?token={token}&expire={timestamp}
        print(value)
    }
}
```

## List of webhooks ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/webhooksList)) ##

```swift
uploadcare.getListOfWebhooks { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let list):
        print(list)
    }
}
```

## Create webhook ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/webhookCreate)) ##

Create and subscribe to a webhook. You can use webhooks to receive notifications about your uploads. For instance, once a file gets uploaded to your project, we can notify you by sending a message to a target URL.

```swift
let url = URL(string: "https://yourwebhook.com")!
uploadcare.createWebhook(targetUrl: url, isActive: true, signingSecret: "someSigningSecret") { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let webhook):
        print(webhook)
    }
}
```

## Update webhook ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/updateWebhook)) ##

Update webhook attributes.

```swift
let url = URL(string: "https://yourwebhook.com")!
let webhookId = 100
uploadcare.updateWebhook(id: webhookId, targetUrl: url, isActive: true, signingSecret: "someNewSigningSecret") { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let webhook):
        print(webhook)
    }
}
```

## Delete webhook ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/webhookUnsubscribe)) ##

Unsubscribe and delete a webhook.

```swift
let url = URL(string: "https://yourwebhook.com")!
uploadcare.deleteWebhook(forTargetUrl: url) { error in
    if let error = error {
        print(error)
    }				
}
```

## Convert document ([API Reference](https://uploadcare.com/docs/transformations/document_conversion/#convert)) ##

You can convert multiple files with one request:

```swift
let task1 = DocumentConversionJobSettings(forFile: file1)
    .format(.odt)
let task2 = DocumentConversionJobSettings(forFile: file2)
    .format(.pdf)

uploadcare.convertDocumentsWithSettings([task1, task2]) { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let response):
        print(response)
    }
}
```

Alternatively, you can pass custom "paths" param as array of strings (see ([documentation](https://uploadcare.com/docs/transformations/document_conversion/#convert-url-formatting))):

```swift
uploadcare.convertDocuments([":uuid/document/-/format/:target-format/"]) { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let response):
        print(response)
    }  
}
```

## Document conversion job status ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/documentConvertStatus)) ##

```swift
uploadcare.documentConversionJobStatus(token: 123456) { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let job):
        switch job.status {
        case .failed(let conversionError):
            print(conversionError)
        default: 
            break
        }
    }
}
```

## Convert video ([API Reference](https://uploadcare.com/docs/transformations/video_encoding/#video-encoding)) ##

You can convert multiple video files with one request:

```swift
let task1 = VideoConversionJobSettings(forFile: file1)
    .format(.webm)
    .size(VideoSize(width: 640, height: 480))
    .resizeMode(.addPadding)
    .quality(.lightest)
    .cut( VideoCut(startTime: "0:0:5.000", length: "15") )
    .thumbs(15)
    
let task2 = VideoConversionJobSettings(forFile: file2)
    .format(.mp4)
    .quality(.lightest)

uploadcare.convertVideosWithSettings([task1, task2]) { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let response):
        print(response)
    }   
}
```

Alternatively, you can pass custom "paths" param as array of strings (see ([documentation](https://uploadcare.com/docs/transformations/video_encoding/#process-url-formatting))):

```swift
uploadcare.convertVideos([":uuid/video/-/format/ogg/"]) { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let response):
        print(response)
    }   
}
```

## Video conversion job status ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/videoConvertStatus)) ##

```swift
uploadcare.videoConversionJobStatus(token: 123456) { result in    
    switch result {
    case .failure(let error):
        print(error)
    case .success(let job):
        print(job)
        switch job.status {
        case .failed(let conversionError):
            print(conversionError)
        default: 
            break
        }
    }
}
```


## Add-Ons ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons)) ##
An Add-On is an application implemented by Uploadcare that accepts uploaded files as an input and can produce other files and/or appdata as an output.

### Execute AWS Rekognition
Execute AWS Rekognition Add-On for a given target to detect labels in an image. Note: Detected labels are stored in the file's appdata.
```swift
uploadcare.executeAWSRecognition(fileUUID: "uuid") { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let response):
        print(response) // contains requestID
    }
}

// check status
uploadcare.checkAWSRecognitionStatus(requestID: "requestID") { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let status):
        print(status)
    }
}
```

### Execute ClamAV
Execute ClamAV virus checking Add-On for a given target.
```swift
let parameters = ClamAVAddonExecutionParams(purgeInfected: true)
uploadcare.executeClamav(fileUUID: "uuid", parameters: parameters) { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let response):
        print(response) // contains requestID
    }
}
                
// check status
uploadcare.checkClamAVStatus(requestID: "requestID") { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let status):
        print(status)
    }
}
```

### Execute Remove.bg
Execute remove.bg background image removal Add-On for a given target.
```swift
// more parameters in RemoveBGAddonExecutionParams model
let parameters = RemoveBGAddonExecutionParams(crop: true, typeLevel: .two) 
uploadcare.executeRemoveBG(fileUUID: "uuid", parameters: parameters) { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let response):
        print(response) // contains requestID
    }
}
                
// check status
uploadcare.checkRemoveBGStatus(requestID: "requestID") { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let status):
        print(status)
    }
}
```
