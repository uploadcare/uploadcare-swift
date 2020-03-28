# REST API

* [Initialization](#initialization)
* [Getting info about account project](#getting-info-about-account-project-api-reference)
* [Get list of files](#get-list-of-files-api-reference)
* [File Info](#file-info-api-reference)
* [Delete files](#delete-files-api-reference)
* [Store files](#store-files-api-reference)
* [Get list of groups](#get-list-of-groups-api-reference)
* [Group info](#group-info-api-reference)
* [Store group](#store-group-api-reference)
* [Copy file to local storage](#copy-file-to-local-storage-api-reference)
* [Copy file to remote storage](#copy-file-to-remote-storage-api-reference)


### Initialization

REST API requires both public and secret key:
```swift
let uploadcare = Uploadcare(withPublicKey: "YOUR_PUBLIC_KEY", secretKey: "YOUR_SECRET_KEY")
```

### Getting info about account project ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/projectInfo?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ###

```swift
uploadcare.getProjectInfo { (project, error) in
    if let error = error {
        print(error)
        return
    }
    print(project ?? "")
}
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

### Delete files ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/deleteFile?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ###

Delete individual file:
```swift
uploadcare.deleteFile(withUUID: "1bac376c-aa7e-4356-861b-dd2657b5bfd2") { (file, error) in
    if let error = error {
        print(error)
        return
    }			
    print(file ?? "")
}
```
Batch file delete:
```swift
let uuids = ["b7a301d1-1bd0-473d-8d32-708dd55addc0", "1bac376c-aa7e-4356-861b-dd2657b5bfd2"]
uploadcare.deleteFiles(withUUIDs: uuids) { (response, error) in
    if let error = error {
        print(error)
        return
    }
    print(response ?? "")
}
```

### Store files ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/storeFile?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ###

Store individual file:
```swift
uploadcare.storeFile(withUUID: "1bac376c-aa7e-4356-861b-dd2657b5bfd2") { (file, error) in
    if let error = error {
        print(error)
        return
    }
    print(file ?? "")
}
```

Batch file storing:
```swift
let uuids = ["b7a301d1-1bd0-473d-8d32-708dd55addc0", "1bac376c-aa7e-4356-861b-dd2657b5bfd2"]
uploadcare.storeFiles(withUUIDs: uuids) { (response, error) in
    if let error = error {
        print(error)
        return
    }
    print(response ?? "")
}
```

### Get list of groups ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/groupsList?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ###

```swift
let query = GroupsListQuery()
    .limit(100)
    .ordering(.datetimeCreatedDESC)
		
uploadcare.listOfGroups(withQuery: query) { (list, error) in
    if let error = error {
        print(error)
        return
    }
    print(list ?? "")
}
```

### Group info ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/groupInfo?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ###

```swift
uploadcare.groupInfo(withUUID: "c5bec8c7-d4b6-4921-9e55-6edb027546bc~1") { (group, error) in
    if let error = error {
        print(error)
        return
    }
    print(group ?? "")
}
```

### Store group ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#tag/Group/paths/~1groups~1%3Cuuid%3E~1storage~1/put?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ###

```swift
uploadcare.storeGroup(withUUID: "c5bec8c7-d4b6-4921-9e55-6edb027546bc~1") { (error) in
    if let error = error {
        print(error)
        return
    }
    print("store group success")
}
```

### Copy file to local storage ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/copyFileLocal?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ###

```swift
uploadcare.copyFileToLocalStorage(source: "6ca619a8-70a7-4777-8de1-7d07739ebbd9") { (response, error) in
    if let error = error {
        print(error)
        return
    }
    print(response ?? "")
}
```

### Copy file to remote storage ([API Reference](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/copyFile?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-swift)) ###

```swift
let source = "99c48392-46ab-4877-a6e1-e2557b011176"
uploadcare.copyFileToRemoteStorage(source: source, target: "one_more_project", pattern: .uuid) { (response, error) in
    if let error = error {
        print(error)
        return
    }
    print(response ?? "")
}
```








