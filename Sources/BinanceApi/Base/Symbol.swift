//
//  File.swift
//  
//
//  Created by zhtg on 2023/6/19.
//

import Foundation
import UtilCore

public struct Symbol {
    
    public var symbol: String? ///": "ETHBTC",
    public var status: String? ///": "TRADING",
    public var baseAsset: String? ///": "ETH",
    public var baseAssetPrecision: Int? ///": 8,
    public var quoteAsset: String? ///": "BTC",
    public var quotePrecision: Int? ///": 8,
    public var quoteAssetPrecision: Int? ///": 8,
    public var orderTypes: [String]? ///": [
    //    LIMIT",
    //    LIMIT_MAKER",
    //    MARKET",
    //    STOP_LOSS",
    //    STOP_LOSS_LIMIT",
    //    TAKE_PROFIT",
    //    TAKE_PROFIT_LIMIT"
    //    ],
    public var icebergAllowed: Bool? ///": true,
    public var ocoAllowed: Bool? ///": true,
    public var isSpotTradingAllowed: Bool? ///": true,
    public var isMarginTradingAllowed: Bool? ///": true,
    public var filters: [[String: Any]]?  ///": [
    //这些在"过滤器"部分中定义
    //所有限制都是可选的
    //    ],
    public var permissions: [String]? /// ": [
    //    "SPOT",
    //    "MARGIN"
    //    ]
    //    }

    public var minSz: String? {
        if let filters = filters {
            for dic in filters {
                if let filterType = dic.stringFor("filterType"),
                   filterType == "LOT_SIZE" {
                    return dic.stringFor("minQty")
                }
            }
        }
        return nil
    }

    public var lotSz: String? {
        if let filters = filters {
            for dic in filters {
                if let filterType = dic.stringFor("filterType"),
                   filterType == "LOT_SIZE" {
                    return dic.stringFor("stepSize")
                }
            }
        }
        return nil
    }

    public var tickSz: String? {
        if let filters = filters {
            for dic in filters {
                if let filterType = dic.stringFor("filterType"),
                   filterType == "PRICE_FILTER" {
                    return dic.stringFor("tickSize")
                }
            }
        }
        return nil
    }

    public init(dic: [String: Any]) {
        symbol = dic.stringFor("symbol")
        status = dic.stringFor("status")
        baseAsset = dic.stringFor("baseAsset")
        baseAssetPrecision = dic.intFor("baseAssetPrecision")
        quoteAsset = dic.stringFor("quoteAsset")
        quotePrecision = dic.intFor("quotePrecision")
        quoteAssetPrecision = dic.intFor("quoteAssetPrecision")
        orderTypes = dic.arrayFor("orderTypes") as? [String]
        icebergAllowed = dic.boolFor("icebergAllowed")
        ocoAllowed = dic.boolFor("ocoAllowed")
        isSpotTradingAllowed = dic.boolFor("isSpotTradingAllowed")
        isMarginTradingAllowed = dic.boolFor("isMarginTradingAllowed")
        filters = dic["filters"] as? [[String: Any]]
        permissions = dic.arrayFor("permissions") as? [String]
    }
}
