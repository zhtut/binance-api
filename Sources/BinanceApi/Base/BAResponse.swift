//
//  File.swift
//  
//
//  Created by zhtg on 2023/6/18.
//

import Foundation
import AsyncNetwork

public struct BAResponse {

    public var res: Response

    public init(res: Response) {
        self.res = res
        if let json = res.bodyJson {
            if res.succeed {
            } else {
                if let dict = json as? [String: Any] {
                    self.code = dict["code"] as? Int
                    self.msg = dict["msg"] as? String
                }
            }
        }
    }

    public var code: Int?
    public var data: Any? {
        if let _ = res.request.decodeConfig {
           return res.model
        } else {
            return res.bodyJson
        }
    }
    
    /// 服务器返回的错误日志
    public var msg: String?

    public var succeed: Bool {
        if res.succeed {
            return code == nil || code == 200
        }
        return false
    }
}
