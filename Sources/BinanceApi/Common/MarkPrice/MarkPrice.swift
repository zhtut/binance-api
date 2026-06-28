//
//  MarkPrice.swift
//  binance-api
//
//  合约标记价格 + 资金费率推送模型（<symbol>@markPrice@1s）
//

import Foundation

/// 标记价格更新
/// https://developers.binance.com/docs/zh-CN/derivatives/usds-margined-futures/websocket-market-streams/Mark-Price-Stream
public struct MarkPrice: Codable, Sendable {
    /// 事件类型 "markPriceUpdate"
    public var e: String
    /// 事件时间
    public var E: Int
    /// 交易对
    public var s: String
    /// 标记价格
    public var p: String
    /// 现货指数价格
    public var i: String?
    /// 预估结算价，仅结算前最后一小时有参考价值
    public var P: String?
    /// 资金费率
    public var r: String?
    /// 下次资金时间
    public var T: Int?

    /// 标记价格（Decimal）
    public var markPrice: Decimal? {
        p.decimal
    }

    /// 指数价格（Decimal）
    public var indexPrice: Decimal? {
        i?.decimal
    }

    /// 资金费率（Decimal）
    public var fundingRate: Decimal? {
        r?.decimal
    }

    /// 下次资金时间
    public var nextFundingTime: Date? {
        guard let T else { return nil }
        return Date(timeIntervalSince1970: Double(T) / 1000.0)
    }
}
