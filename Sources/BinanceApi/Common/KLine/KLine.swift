//
//  FeatureKLine.swift
//  binance-api
//
//  Created by tutuzhou on 2025/4/10.
//

import Foundation

/// seconds -> 秒    1s
/// minutes -> 分钟    1m， 3m， 5m， 15m， 30m
/// hours -> 小时    1h， 2h， 4h， 6h， 8h， 12h
/// days -> 天    1d， 3d
/// weeks -> 周    1w
/// months -> 月    1M
public enum KLineInteval: String, Codable, Sendable {

    case _1s = "1s"
    
    case _1m = "1m"
    case _3m = "3m"
    case _5m = "5m"
    case _15m = "15m"
    case _30m = "30m"
    
    case _1h = "1h"
    case _2h = "2h"
    case _4h = "4h"
    case _6h = "6h"
    case _8h = "8h"
    case _12h = "12h"
    
    case _1d = "1d"
    case _3d = "3d"
    
    case _1w = "1w"
    case _1M = "1M"
    
    public var millseconds: Int {
        seconds * 1000
    }
    
    public var seconds: Int {
        switch self {
        case ._1s:
            1
        case ._1m:
            60
        case ._3m:
            180
        case ._5m:
            300
        case ._15m:
            900
        case ._30m:
            1800
        case ._1h:
            3600
        case ._2h:
            7200
        case ._4h:
            14400
        case ._6h:
            6 * 3600
        case ._8h:
            8 * 3600
        case ._12h:
            12 * 3600
        case ._1d:
           24 * 3600
        case ._3d:
            3 * 24 * 3600
        case ._1w:
            7 * 24 * 3600
        case ._1M:
            30 * 24 * 3600 // 这个不准，一个月的时间不固定
        }
    }
}

/// [
///     1499040000000,      // 开盘时间
///     "0.01634790",       // 开盘价
///     "0.80000000",       // 最高价
///     "0.01575800",       // 最低价
///     "0.01577100",       // 收盘价(当前K线未结束的即为最新价)
///     "148976.11427815",  // 成交量
///     1499644799999,      // 收盘时间
///     "2434.19055334",    // 成交额
///     308,                // 成交笔数
///     "1756.87402397",    // 主动买入成交量
///     "28.46694368",      // 主动买入成交额
///     "17928899.62484339" // 请忽略该参数
/// ]
public struct KLine {
    public var symbol: String
    
    /// K线开盘时间
    public var openTime: Int
    
    /// 开盘价
    public var openPrice: String
    
    /// 最高价
    public var highestPrice: String
    
    /// 最低价
    public var lowestPrice: String
    
    /// 收盘价(当前K线未结束的即为最新价)
    public var closePrice: String
    
    /// 成交量
    public var volume: String
    
    /// K线收盘时间
    public var closeTime: Int
    
    /// 成交额
    public var tradingAmount: String
    
    /// 成交笔数
    public var numberOfTrades: Int
    
    /// 主动买入成交量
    public var activeBuyVolume: String
    
    /// 主动买入成交额
    public var activeBuyAmount: String
    
    /// 初始化方法，接受一个字符串数组
    public init(symbol: String, array: [Any]) {
        self.symbol = symbol
        self.openTime = array[0] as? Int ?? 0
        self.openPrice = array[1] as? String ?? ""
        self.highestPrice = array[2] as? String ?? ""
        self.lowestPrice = array[3] as? String ?? ""
        self.closePrice = array[4] as? String ?? ""
        self.volume = array[5] as? String ?? ""
        self.closeTime = array[6] as? Int ?? 0
        self.tradingAmount = array[7] as? String ?? ""
        self.numberOfTrades = array[8] as? Int ?? 0
        self.activeBuyVolume = array[9] as? String ?? ""
        self.activeBuyAmount = array[10] as? String ?? ""
        // 请忽略该参数
    }
    
    /// 是否上涨
    public var isRise: Bool {
        return closePrice.double ?? 0.0 > openPrice.double ?? 0.0
    }
    
    /// 涨跌幅，百分比
    public var pricePercent: Double {
        guard let open = openPrice.double, let close = closePrice.double else {
            return 0
        }
        return ((close - open) / open) * 100.0
    }
}
