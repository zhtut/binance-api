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
    public let filters: [[String: Sendable]]?  ///": [
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
        if let dic = filters?.first(where: {
            let v = $0.string(for: "filterType")
            return v == "PRICE_FILTER"
        }) {
            return dic.string(for: "minPrice")
        }
        return nil
    }
    
    /// 订单最小价格间隔
    public var tickSize: String? {
        if let dic = filters?.first(where: { $0.string(for: "filterType") == "PRICE_FILTER" }) {
            return dic.string(for: "tickSize")
        }
        return nil
    }
    
    /// 下单数量允许的最小值.
    public var minQty: String? {
        if let dic = filters?.first(where: { $0.string(for: "filterType") == "LOT_SIZE" }) {
            return dic.string(for: "minQty")
        }
        return nil
    }
    
    /// 下单数量允许的步进值。
    public var stepSize: String? {
        if let dic = filters?.first(where: { $0.string(for: "filterType") == "LOT_SIZE" }) {
            return dic.string(for: "stepSize")
        }
        return nil
    }
    
    public init(dic: [String: Any], symbolType: SymbolType) {
        self.type = symbolType
        symbol = dic.string(for: "symbol") ?? ""
        status = dic.string(for: "status")
        baseAsset = dic.string(for: "baseAsset")
        baseAssetPrecision = dic.int(for: "baseAssetPrecision")
        quoteAsset = dic.string(for: "quoteAsset")
        quotePrecision = dic.int(for: "quotePrecision")
        quoteAssetPrecision = dic.int(for: "quoteAssetPrecision")
        orderTypes = dic.array(for: "orderTypes") as? [String]
        icebergAllowed = dic.bool(for: "icebergAllowed")
        ocoAllowed = dic.bool(for: "ocoAllowed")
        isSpotTradingAllowed = dic.bool(for: "isSpotTradingAllowed")
        isMarginTradingAllowed = dic.bool(for: "isMarginTradingAllowed")
        filters = dic["filters"] as? [[String: Sendable]]
        permissions = dic.array(for: "permissions") as? [String]
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
