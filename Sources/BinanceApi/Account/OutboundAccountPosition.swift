//
//  File.swift
//  
//
//  Created by zhtut on 2023/7/23.
//

import Foundation

/// 账户更新收到的消息
/// 每当帐户余额发生更改时，都会发送一个事件outboundAccountPosition，其中包含可能由生成余额变动的事件而变动的资产。
public struct OutboundAccountPosition: Codable {
    
    public static let key = "outboundAccountPosition"
    
    public struct Balance: Codable {
        public var a: String // ": "ETH",                 // 资产名称
        public var f: String // ": "10000.000000",        // 可用余额
        public var l: String // ": "0.000000"             // 冻结余额
    }
    
    public var e: String // 事件类型
    public var E: Int // 事件时间
    public var U: Int? // 账户末次更新时间戳
    public var B: [Balance] // 余额
}
