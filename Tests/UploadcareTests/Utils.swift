//
//  Utils.swift
//  
//
//  Created by Sergei Armodin on 01.02.2022.
//

import Foundation

func DLog(
    _ messages: Any...,
    fullPath: String = #file,
    line: Int = #line,
    functionName: String = #function
) {
    let file = URL(fileURLWithPath: fullPath)
    for message in messages {
        #if DEBUG
        let string = "\(file.pathComponents.last!):\(line) -> \(functionName): \(message)"
        print(string)
        #endif
    }
}

/// Count size of Data (in mb)
/// - Parameter data: data
func sizeString(ofData data: Data) -> String {
    let bcf = ByteCountFormatter()
    bcf.allowedUnits = [.useMB] // optional: restricts the units to MB only
    bcf.countStyle = .file
    return bcf.string(fromByteCount: Int64(data.count))
}

func delay(_ delay: Double, closure: @escaping ()->()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}
