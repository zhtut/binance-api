//
//  File.swift
//  
//
//  Created by zhtg on 2023/6/19.
//

import Foundation
import CommonUtils
import DefaultCodable

/// 产品类型
public enum SymbolType: Sendable {
    /// 现货
    case spot
    /// 合约
    case feature
}


public struct Symbol: Sendable {
    
    public var type: SymbolType
    
    public var symbol: String ///": "ETHBTC",
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
    public var filters: [[String: String]]?  ///": [
    //这些在"过滤器"部分中定义
    //所有限制都是可选的
    //    ],
    public var permissions: [String]? /// ": [
    //    "SPOT",
    //    "MARGIN"
    //    ]
    //    }
    
    /// 价格下限, 最小价格
    public var minPrice: String? {
        if let dic = filters?.first(where: { $0.stringFor("filterType") == "PRICE_FILTER" }) {
            return dic.stringFor("minPrice")
        }
        return nil
    }
    
    /// 订单最小价格间隔
    public var tickSize: String? {
        if let dic = filters?.first(where: { $0.stringFor("filterType") == "PRICE_FILTER" }) {
            return dic.stringFor("tickSize")
        }
        return nil
    }
    
    /// 下单数量允许的最小值.
    public var minQty: String? {
        if let dic = filters?.first(where: { $0.stringFor("filterType") == "LOT_SIZE" }) {
            return dic.stringFor("minQty")
        }
        return nil
    }
    
    /// 下单数量允许的步进值。
    public var stepSize: String? {
        if let dic = filters?.first(where: { $0.stringFor("filterType") == "LOT_SIZE" }) {
            return dic.stringFor("stepSize")
        }
        return nil
    }
    
    public init(dic: [String: Any], symbolType: SymbolType) {
        self.type = symbolType
        symbol = dic.stringFor("symbol") ?? ""
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
        filters = dic["filters"] as? [[String: String]]
        permissions = dic.arrayFor("permissions") as? [String]
    }
}

public extension Symbol {
    /// wss使用的baseURL
    var wssBaseURL: String {
        switch type {
        case .spot:
            return APIConfig.shared.spot.wsBaseURL
        case .feature:
            return APIConfig.shared.feature.wsBaseURL
        }
    }
}
