# REST API

* [Initialization](#initialization)
* [List of files](#list-of-files-api-reference)
* [File info](#file-info-api-reference)
* [Store files](#store-files-api-reference)
* [Delete files](#delete-files-api-reference)
* [Copy file to local storage](#copy-file-to-local-storage-api-reference)
* [Copy file to remote storage](#copy-file-to-remote-storage-api-reference)
* [List of groups](#list-of-groups-api-reference)
* [Group info](#group-info-api-reference)
* [Store group](#store-group-api-reference)
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


## Initialization

REST API requires both public and secret keys:

```swift
let uploadcare = Uploadcare(withPublicKey: "YOUR_PUBLIC_KEY", secretKey: "YOUR_SECRET_KEY")
```

## List of files ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/filesList)) ##

```swift
// Make a list of files object
lazy var filesList = uploadcare.listOfFiles()

// Make a query object
let query = PaginationQuery()
    .stored(true)
    .ordering(.sizeDESC)
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

## File info ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/fileInfo)) ##

```swift
uploadcare.fileInfo(withUUID: "1bac376c-aa7e-4356-861b-dd2657b5bfd2") { result in
    switch result {
    case .failure(let error):
        print(error)
    case .success(let file):
        print(file)
    }
}
```

## Store files ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/storeFile)) ##

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

## Delete files ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/deleteFile)) ##

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

## Copy file to local storage ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/copyFileLocal)) ##

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

## Copy file to remote storage ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/copyFile)) ##

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

## List of groups ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/groupsList)) ##

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

## Group info ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/groupInfo)) ##

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

## Store group ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#tag/Group/paths/~1groups~1%3Cuuid%3E~1storage~1/put)) ##

```swift
uploadcare.storeGroup(withUUID: "c5bec8c7-d4b6-4921-9e55-6edb027546bc~1") { error in
    if let error = error {
        print(error)
        return
    }
    print("store group success")
}
```

## Project info ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/projectInfo)) ##

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

## List of webhooks ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/webhooksList)) ##

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

## Create webhook ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/webhookCreate)) ##

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

## Update webhook ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/updateWebhook)) ##

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

## Delete webhook ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/webhookUnsubscribe)) ##

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

## Document conversion job status ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#tag/Conversion/paths/~1convert~1document~1status~1{token}~1/get)) ##

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

## Video conversion job status ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/videoConvertStatus)) ##

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
