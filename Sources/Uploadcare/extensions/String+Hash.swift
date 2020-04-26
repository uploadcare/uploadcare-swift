//
//  String+Hash.swift
//  
//
//  Created by Sergey Armodin on 26.04.2020.
//

import Foundation
import CommonCrypto


extension String {
	/// String -> MD5
	/// - Returns: hash
	func md5() -> String {
		let str = self.cString(using: String.Encoding.utf8)
		let strLen = CUnsignedInt(self.lengthOfBytes(using: String.Encoding.utf8))
		let digestLen = Int(CC_MD5_DIGEST_LENGTH)
		let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
		CC_MD5(str!, strLen, result)
		let hash = NSMutableString()
		for i in 0..<digestLen {
			hash.appendFormat("%02x", result[i])
		}
		result.deallocate()
		return String(format: hash as String)
	}
	
	
	/// String -> SHA1 signed
	/// - Parameter key: sign key
	/// - Returns: hash
	func hmac(key: String) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), key, key.count, self, self.count, &digest)
        let data = Data(digest)
        return data.map { String(format: "%02hhx", $0) }.joined()
    }
}
