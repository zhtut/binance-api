//
//  File.swift
//
//
//  Created by zhtg on 2023/6/18.
//

import Foundation
import AsyncNetworking

/// Binance接口请求
public struct RestAPI {
    
    public struct APIError: Error {
        var msg: String?
    }
    
    @discardableResult
    public static func post(path: String,
                            params: Any? = nil,
                            dataKey: String = "data",
                            dataClass: Decodable.Type? = nil,
                            printLog: Bool = false) async throws -> BAResponse {
        let res = try await send(path: path,
                             params: params,
                             method: .POST,
                             dataKey: dataKey,
                             dataClass: dataClass,
                             printLog: printLog)
        if res.succeed {
            return res
        } else {
            throw APIError(msg: res.msg)
        }
    }
    
    @discardableResult
    public static func get(path: String,
                           params: Any? = nil,
                           dataKey: String = "data",
                           dataClass: Decodable.Type? = nil,
                           printLog: Bool = false) async throws -> BAResponse {
        let res = try await send(path: path,
                             params: params,
                             method: .GET,
                             dataKey: dataKey,
                             dataClass: dataClass,
                             printLog: printLog)
        if res.succeed {
            return res
        } else {
            throw APIError(msg: res.msg)
        }
    }
    
    
    @discardableResult
    public static func send(path: String,
                            params: Any? = nil,
                            method: HTTPMethod = .GET,
                            dataKey: String = "data",
                            dataClass: Decodable.Type? = nil,
                            printLog: Bool = false) async throws -> BAResponse {
        var newMethod = method
        var newPath = path
        
        if newPath.hasPrefix("GET") {
            newMethod = .GET
        } else if newPath.hasPrefix("POST") {
            newMethod = .POST
        } else if newPath.hasPrefix("DELETE") {
            newMethod = .DELETE
        } else if newPath.hasPrefix("PUT") {
            newMethod = .PUT
        }
        
        newPath = newPath.replacingOccurrences(of: "\(newMethod) ", with: "")
        
        var needSign = false
        if newPath.hasSuffix(" (HMAC SHA256)") {
            needSign = true
            newPath = newPath.replacingOccurrences(of: " (HMAC SHA256)", with: "")
        }
        
        var urlStr: String
        if !newPath.hasPrefix("/") {
            newPath = "/\(newPath)"
        }
        
        let baseURL: String
        if newPath.hasPrefix("/api/") || newPath.hasPrefix("/sapi/") {
            baseURL = APIConfig.shared.spot.httpBaseURL
        } else if newPath.hasPrefix("/fapi/") {
            baseURL = APIConfig.shared.feature.httpBaseURL
        } else {
            print("暂时不支持path: \(newPath)")
            throw URLError(.badURL)
        }
        
        urlStr = "\(baseURL)\(newPath)"
        
        var paramStr = ""
        if let params = params as? [String: Any] {
            paramStr = params.urlQueryStr ?? ""
        }
        if needSign {
            var newParams = params as? [String: Any] ?? [String: Any]()
            newParams["timestamp"] = Int(Date().timeIntervalSince1970 * 1000.0)
            if let queryStr = newParams.urlQueryStr {
                let sign = queryStr.hmacSha256With(key: try APIConfig.shared.requireSecretKey())
                paramStr = "\(queryStr)&signature=\(sign)"
            }
        }
        
        if paramStr.count > 0 {
            urlStr = "\(urlStr)?\(paramStr)"
        }
        
        var headerFields = [String: String]()
        headerFields["X-MBX-APIKEY"] = try APIConfig.shared.requireApiKey()
        headerFields["Accept"] = "application/json"
        
        var decodeConfig: DecodeConfig?
        if let dataClass {
            decodeConfig = DecodeConfig(dataKey: dataKey, modelType: dataClass)
        }
        
        let req = Request(path: urlStr,
                          method: newMethod,
                          header: headerFields,
                          decodeConfig: decodeConfig,
                          printLog: printLog)
        let response = try await Networking.send(request: req)
        let baRes = BAResponse(res: response)
        return baRes
    }
}
