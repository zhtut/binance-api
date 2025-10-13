//
//  BookTiker.swift
//  binance-api
//
//  Created by tutuzhou on 2025/10/13.
//

import Foundation

public struct BookTiker: Codable, Sendable {
    /// "e":"bookTicker",        // 事件类型
    public var e: String
    /// "u":400900217,         // 更新ID
    public var u: Int
    /// "E": 1568014460893,    // 事件推送时间
    public var E: Int
    /// "T": 1568014460891,    // 撮合时间
    public var T: Int
    /// "s":"BNBUSDT",         // 交易对
    public var s: String
    /// "b":"25.35190000",     // 买单最优挂单价格
    public var b: String
    /// "B":"31.21000000",     // 买单最优挂单数量
    public var B: String
    /// "a":"25.36520000",     // 卖单最优挂单价格
    public var a: String
    /// "A":"40.66000000"      // 卖单最优挂单数量
    public var A: String
    
    /// 中间价
    public var centerPrice: Decimal? {
        guard let bid = b.decimal,
              let ask = a.decimal else {
            return nil
        }
        let center = (bid + ask) / 2.0
        return center
    }
}
