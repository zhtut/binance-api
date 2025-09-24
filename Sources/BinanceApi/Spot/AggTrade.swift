//
//  AggTrade.swift
//  BinanceTrader
//
//  Created by tutuzhou on 2024/11/14.
//

import Foundation

struct AggTrade: Codable {
    ///    "e": "aggTrade",      // 事件类型
    var e: String
    ///    "E": 1672515782136,   // 事件时间
    var E: Int
    ///    "s": "BNBBTC",        // 交易对
    var s: String
    ///    "a": 12345,           // 归集交易ID
    var a: Int
    ///    "p": "0.001",         // 成交价格
    var p: String
    ///    "q": "100",           // 成交数量
    var q: String
    ///    "f": 100,             // 被归集的首个交易ID
    var f: Int
    ///    "l": 105,             // 被归集的末次交易ID
    var l: Int
    ///    "T": 1672515782136,   // 成交时间
    var T: Int
    ///    "m": true,            // 做市方是否是买入。如true，则此次成交是一个主动卖出单，否则是一个主动买入单。
    var m: Bool
    ///    "M": true             // 请忽略该字段
    var M: Bool
    
    var isBuyOrder: Bool {
        m == false
    }
}

extension AggTrade: Equatable {
    
}
