# Upload API

* [Initialization](#initialization)
* [Get list of files](#get-list-of-files-api-reference)
* [File Info](#file-info-api-reference)

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





