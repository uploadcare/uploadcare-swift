//
//  String+Hash.swift
//  
//
//  Created by Sergey Armodin on 26.04.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation
#if !os(Linux)
import CommonCrypto
#else
import Crypto
#endif


extension String {
	/// String -> MD5
	/// - Returns: hash
	func md5() -> String {
		#if !os(Linux)
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
		#else
		let d = Data(self.utf8)
		let h = Insecure.MD5.hash(data: d)

		let hash = NSMutableString(capacity: Insecure.MD5.byteCount)
		for i in Array(h) {
			hash.append(String(format: "%02x", arguments: [i]))
		}
		return String(format: hash as String)
		#endif
	}
	
	/// String -> SHA1 signed
	/// - Parameter key: sign key
	/// - Returns: hash
	func hmac(key: String) -> String {
		#if !os(Linux)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), key, key.count, self, self.count, &digest)
        let data = Data(digest)
        return data.map { String(format: "%02hhx", $0) }.joined()
		#else
		let symmetricKey = SymmetricKey(data: key.data(using: .utf8)!)
		let someData = self.data(using: .utf8)!
		let mac = HMAC<Insecure.SHA1>.authenticationCode(for: someData, using: symmetricKey)
		let data = Data(mac)
		return data.map { String(format: "%02hhx", $0) }.joined()
		#endif
    }
	
	/// String -> SHA256 signed
	/// - Parameter key: sign key
	/// - Returns: hash
	func sha256(key: String) -> String {
		#if !os(Linux)
		var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
		CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), key, key.count, self, self.count, &digest)
		
        let data = Data(digest)
        return data.map { String(format: "%02hhx", $0) }.joined()
		#else
		let symmetricKey = SymmetricKey(data: key.data(using: .utf8)!)
		let someData = self.data(using: .utf8)!
		let mac = HMAC<SHA256>.authenticationCode(for: someData, using: symmetricKey)
		let data = Data(mac)
		return data.map { String(format: "%02hhx", $0) }.joined()
		#endif
    }
}
