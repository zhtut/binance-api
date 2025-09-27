//
//  AggTrade.swift
//  BinanceTrader
//
//  Created by tutuzhou on 2024/11/14.
//

import Foundation

public struct Trade: Codable, Sendable {
    
    /// 交易类型
    public enum TradeType: String, Codable, Sendable {
        /// 逐笔交易
        case trade
        /// 归集交易
        case aggTrade
    }
    
    ///    "e": "aggTrade",      // 事件类型
    public var e: TradeType
    ///    "E": 1672515782136,   // 事件时间
    public var E: Int
    ///    "s": "BNBBTC",        // 交易对
    public var s: String
    ///    "a": 12345,           // 归集交易ID
    public var a: Int?
    ///    "t": 12345,          // 交易ID
    public var t: Int?
    ///    "p": "0.001",         // 成交价格
    public var p: String
    ///    "q": "100",           // 成交数量
    public var q: String
    ///    "f": 100,             // 被归集的首个交易ID
    public var f: Int?
    ///    "l": 105,             // 被归集的末次交易ID
    public var l: Int?
    ///    "T": 1672515782136,   // 成交时间
    public var T: Int
    ///    "m": true,            // 做市方是否是买入。如true，则此次成交是一个主动卖出单，否则是一个主动买入单。
    public var m: Bool
    ///    "M": true             // 请忽略该字段
    public var M: Bool
    
    public var isBuyOrder: Bool {
        m == false
    }
}

extension Trade: Equatable {
    
}
