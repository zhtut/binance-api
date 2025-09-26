//
//  File.swift
//  
//
//  Created by zhtg on 2023/6/19.
//

import Foundation
import CommonUtils
import DefaultCodable

public struct Symbol: Codable, Sendable {
    
    @Default
    public var symbol: String ///": "ETHBTC",
    @Default
    public var status: String ///": "TRADING",
    @Default
    public var baseAsset: String ///": "ETH",
    @Default
    public var baseAssetPrecision: Int ///": 8,
    @Default
    public var quoteAsset: String ///": "BTC",
    @Default
    public var quotePrecision: Int ///": 8,
    @Default
    public var quoteAssetPrecision: Int ///": 8,
    ///
    @Default
    public var orderTypes: [String] ///": [
    //    LIMIT",
    //    LIMIT_MAKER",
    //    MARKET",
    //    STOP_LOSS",
    //    STOP_LOSS_LIMIT",
    //    TAKE_PROFIT",
    //    TAKE_PROFIT_LIMIT"
    //    ],
    @Default
    public var icebergAllowed: Bool ///": true,
    @Default
    public var ocoAllowed: Bool ///": true,
    @Default
    public var isSpotTradingAllowed: Bool ///": true,
    @Default
    public var isMarginTradingAllowed: Bool ///": true,

    @Default
    public var filters: [[String: String]]  ///": [
    //这些在"过滤器"部分中定义
    //所有限制都是可选的
    //    ],
    @Default
    public var permissions: [String] /// ": [
    //    "SPOT",
    //    "MARGIN"
    //    ]
    //    }

    public var minSz: String? {
        for dic in filters {
            if let filterType = dic.stringFor("filterType"),
               filterType == "LOT_SIZE" {
                return dic.stringFor("minQty")
            }
        }
        return nil
    }

    public var lotSz: String? {
        for dic in filters {
            if let filterType = dic.stringFor("filterType"),
               filterType == "LOT_SIZE" {
                return dic.stringFor("stepSize")
            }
        }
        return nil
    }

    public var tickSz: String? {
        for dic in filters {
            if let filterType = dic.stringFor("filterType"),
               filterType == "PRICE_FILTER" {
                return dic.stringFor("tickSize")
            }
        }
        return nil
    }
}
