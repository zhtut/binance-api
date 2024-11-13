//
//  File.swift
//  
//
//  Created by shutut on 2021/10/10.
//

import Foundation
import Crypto

public extension HashedAuthenticationCode {
    var data: Data? {
        let wapper = self.withUnsafeBytes { pointer -> Data? in
            if let unsafeRawPoint = pointer.baseAddress {
                let data = Data(bytes: unsafeRawPoint, count: pointer.count)
                return data
            }
            return nil
        }
        if let data = wapper {
            return data
        }
        return nil
    }
}

public extension Data {
    var bytes: [UInt8] {
        return [UInt8](self)
    }
    
    var hexString: String {
        let result = self
        let bytes = result.bytes
        let length = result.count
        let hash = NSMutableString(capacity: length)
        for i in 0..<length {
            let x = bytes[i]
            hash.append(String(format: "%02x", x))
        }
        return "\(hash)".lowercased()
    }
}

public extension String {
    
    func hmacWith<H: HashFunction>(key: String, h: H.Type) -> Data {
        let key = SymmetricKey(data: key.data(using: .utf8)!)
        let someData = self.data(using: .utf8)!
        let mac = HMAC<H>.authenticationCode(for: someData, using: key)
        if let data = mac.data {
            return data
        }
        return Data()
    }
    
    func signatureWith<H: HashFunction>(h: H.Type) -> String {
        let someData = self.data(using: .utf8)!
        var hf = h.init()
        hf.update(data: someData)
        let result = hf.finalize()
        let str = result.description.replacingOccurrences(of: "SHA512 digest: ", with: "")
        return str
    }
    
    func sha512Signature() -> String {
        return self.signatureWith(h: SHA512.self)
    }
    
    func hmacSha256ToBase64With(key: String) -> String {
        let result = hmacWith(key: key, h: SHA256.self)
        let base64String = result.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
        return base64String
    }
    
    func hmacSha256With(key: String) -> String {
        let result = hmacWith(key: key, h: SHA256.self)
        return result.hexString
    }
    
    func hmacSha512With(key: String) -> String {
        let result = hmacWith(key: key, h: SHA512.self)
        return result.hexString
    }
}
