//
//  File.swift
//
//
//  Created by zhtg on 2023/6/18.
//

import Foundation
import Crypto

public class PKCS8Ed25519Handler {
    
    // 从 PKCS#8 私钥中提取原始 Ed25519 私钥
    public static func extractPrivateKeyFromPKCS8(_ pkcs8Data: Data) throws -> Data {
        let bytes = [UInt8](pkcs8Data)
        
        print("完整的 PKCS#8 数据: \(bytes.map { String(format: "%02x", $0) }.joined())")
        
        // PKCS#8 Ed25519 私钥的标准结构：
        // 30 2E - SEQUENCE (46 bytes)
        //   02 01 00 - INTEGER Version (0)
        //   30 05 - SEQUENCE AlgorithmIdentifier (5 bytes)
        //     06 03 2B 65 70 - OID 1.3.101.112 (Ed25519)
        //   04 22 - OCTET STRING (34 bytes)
        //     04 20 - 嵌套的 OCTET STRING (32 bytes) - 这是实际的私钥!
        //       [32字节私钥数据]
        
        guard bytes.count >= 48 else {
            throw NSError(domain: "PKCS8Error", code: 1, userInfo: [NSLocalizedDescriptionKey: "PKCS#8 data too short"])
        }
        
        // 更精确的解析：查找嵌套的 OCTET STRING (04 20)
        for i in 0..<(bytes.count - 34) {
            // 查找模式: 04 20 (OCTET STRING 后面跟着 0x20 = 32 字节)
            if bytes[i] == 0x04 && bytes[i + 1] == 0x20 {
                let keyStart = i + 2
                let keyEnd = keyStart + 32
                
                if keyEnd <= bytes.count {
                    let privateKeyData = Data(bytes[keyStart..<keyEnd])
                    print("找到私钥位置: 偏移量 \(i), 数据: \(privateKeyData.map { String(format: "%02x", $0) }.joined())")
                    
                    if isValidEd25519PrivateKey(privateKeyData) {
                        return privateKeyData
                    }
                }
            }
        }
        
        // 备选方案：尝试从固定位置提取
        // 在 48 字节的 PKCS#8 数据中，私钥通常在第 16-48 字节
        if bytes.count == 48 {
            let potentialKey = Data(bytes[16..<48])
            print("备选私钥: \(potentialKey.map { String(format: "%02x", $0) }.joined())")
            if isValidEd25519PrivateKey(potentialKey) {
                return potentialKey
            }
        }
        
        throw NSError(domain: "PKCS8Error", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not extract private key from PKCS#8 data"])
    }
    
    // 从 PKCS#8 公钥中提取原始 Ed25519 公钥
    public static func extractPublicKeyFromPKCS8(_ pkcs8Data: Data) throws -> Data {
        let bytes = [UInt8](pkcs8Data)
        
        print("完整的 PKCS#8 公钥数据: \(bytes.map { String(format: "%02x", $0) }.joined())")
        
        // PKCS#8 Ed25519 公钥的标准结构：
        // 30 2A - SEQUENCE (42 bytes)
        //   30 05 - SEQUENCE AlgorithmIdentifier (5 bytes)
        //     06 03 2B 65 70 - OID 1.3.101.112 (Ed25519)
        //   03 21 - BIT STRING (33 bytes)
        //     00 - 填充位
        //     [32字节公钥数据]
        
        guard bytes.count >= 35 else {
            throw NSError(domain: "PKCS8Error", code: 1, userInfo: [NSLocalizedDescriptionKey: "PKCS#8 public key data too short"])
        }
        
        // 查找 BIT STRING (03) 后面的公钥数据
        // 公钥通常位于最后 32 字节，但前面可能有 00 填充位
        for i in 0..<(bytes.count - 33) {
            if bytes[i] == 0x03 && bytes[i + 1] == 0x21 { // BIT STRING 长度 33
                let keyStart = i + 3 // 跳过 03 21 和 00 填充位
                let keyEnd = keyStart + 32
                
                if keyEnd <= bytes.count {
                    let publicKeyData = Data(bytes[keyStart..<keyEnd])
                    print("找到公钥位置: 偏移量 \(i), 数据: \(publicKeyData.map { String(format: "%02x", $0) }.joined())")
                    return publicKeyData
                }
            }
        }
        
        // 备选方案：直接取最后 32 字节
        let last32Bytes = Data(bytes.suffix(32))
        print("备选公钥: \(last32Bytes.map { String(format: "%02x", $0) }.joined())")
        return last32Bytes
    }
    
    public static func isValidEd25519PrivateKey(_ data: Data) -> Bool {
        guard data.count == 32 else { return false }
        let bytes = [UInt8](data)
        return !bytes.allSatisfy { $0 == 0 }
    }
}

public enum APIKeyType: Sendable {
    case hmac
    case ed25519
}

/// api配置
/// https://developers.binance.com/docs/zh-CN/binance-spot-api-docs/rest-api/request-security
public class APIConfig {
    
    nonisolated(unsafe) public static let shared = APIConfig()
    
    public init() {
        
    }
    
    enum ConfigError: Error {
        case notSetup
    }
    
    // 从文件中读取配置文件
    public func set(_ apiKey: String, secretKey: String, keyType: APIKeyType = .hmac) throws {
        self.apiKey = apiKey
        self.secretKey = secretKey
        self.keyType = keyType
        
        if keyType == .ed25519 {
            // 处理私钥
            try createKeyDatas()
        }
    }
    
    var keyType: APIKeyType = .hmac
    private var apiKey: String?
    private var secretKey: String?
    
    public func requireApiKey() throws -> String {
        if let apiKey {
            return apiKey
        }
        throw ConfigError.notSetup
    }
    
    public func requireSecretKey() throws -> String {
        if let secretKey {
            return secretKey
        }
        throw ConfigError.notSetup
    }
    
    private var privateKey: Curve25519.Signing.PrivateKey?
    private var publicKey: Curve25519.Signing.PublicKey?
    
    public struct URLGroup {
        public var httpBaseURL: String
        public var wsBaseURL: String
    }
    
    public let spot = URLGroup(httpBaseURL: "https://api.binance.com",
                                      wsBaseURL: "wss://stream.binance.com:443/ws")
    public let feature = URLGroup(httpBaseURL: "https://fapi.binance.com",
                                         wsBaseURL: "wss://fstream.binance.com/ws") // wss://ws-fapi.binance.com/ws-fapi/v1
    
    
    // 初始化 - 直接使用私钥文本内容
    func createKeyDatas() throws {
        
        // 将Base64编码的私钥字符串转换为Data
        guard let privateKeyData = Data(base64Encoded: try requireSecretKey()),
              let publicKeyData = Data(base64Encoded: try requireApiKey()) else {
            throw NSError(domain: "CryptoError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid private key format"])
        }
        
        // 创建私钥对象
        // 根据数据大小处理不同格式
        let rawPrivateKey = try PKCS8Ed25519Handler.extractPrivateKeyFromPKCS8(privateKeyData)
//        let rawPrivateKey = privateKeyData.prefix(32)
        self.privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: rawPrivateKey)
        
        // 创建私钥对象
        // 根据数据大小处理不同格式
        let rawPublicKey = try PKCS8Ed25519Handler.extractPublicKeyFromPKCS8(publicKeyData)
        self.publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: rawPublicKey)
        
//        self.publicKey = self.privateKey?.publicKey
    }
    
    // 创建签名
    public func createSignature(payload: String) throws -> String {
        guard let privateKey else {
            throw ConfigError.notSetup
        }
        let signatureData = try privateKey.signature(for: payload.data(using: .ascii)!)
        return signatureData.base64EncodedString()
    }
    
    // 验证签名
    public func verifySignature(payload: String, signature: String) throws -> Bool {
        guard let payloadData = payload.data(using: .ascii),
              let signatureData = Data(base64Encoded: signature) else {
            throw NSError(domain: "CryptoError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid payload or signature format"])
        }
        
        guard let publicKey else {
            throw ConfigError.notSetup
        }
        
        return publicKey.isValidSignature(signatureData, for: payloadData)
    }
}
