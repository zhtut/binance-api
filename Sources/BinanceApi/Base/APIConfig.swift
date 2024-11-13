//
//  File.swift
//
//
//  Created by zhtg on 2023/6/18.
//

import Foundation

/// api配置
public class APIConfig {
    
    nonisolated(unsafe) public static let shared = APIConfig()
    
    init() {
        
    }
    
    enum ConfigError: Error {
        case notSetup
    }
    
    // 从文件中读取配置文件
    public func set(_ apiKey: String, secretKey: String) {
        self.apiKey = apiKey
        self.secretKey = secretKey
    }
    
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
    
    public struct URLGroup {
        public var httpBaseURL: String
        public var wsBaseURL: String
    }
    
    public let spot = URLGroup(httpBaseURL: "https://api.binance.com",
                                      wsBaseURL: "wss://stream.binance.com:9443/ws")
    public let feature = URLGroup(httpBaseURL: "https://fapi.binance.com",
                                         wsBaseURL: "wss://fstream.binance.com/ws")
}
