//
//  File.swift
//  
//
//  Created by tutuzhou on 2024/1/20.
//

import Foundation

/// 账户成交记录
public struct MyTrade: Codable {
    ///    "symbol": "BNBBTC", // 交易对
    public var symbol: String
    ///    "id": 28457, // trade ID
    public var id: Int
    ///    "orderId": 100234, // 订单ID
    public var orderId: Int
    ///    "orderListId": -1, // OCO订单的ID，不然就是-1
    public var orderListId: Int
    ///    "price": "4.00000100", // 成交价格
    public var price: String
    ///    "qty": "12.00000000", // 成交量
    public var qty: String
    ///    "quoteQty": "48.000012", // 成交金额
    public var quoteQty: String
    ///    "commission": "10.10000000", // 交易费金额
    public var commission: String
    ///    "commissionAsset": "BNB", // 交易费资产类型
    public var commissionAsset: String
    ///    "time": 1499865549590, // 交易时间
    public var time: Int
    ///    "isBuyer": true, // 是否是买家
    public var isBuyer: Bool
    ///    "isMaker": false, // 是否是挂单方
    public var isMaker: Bool
    ///    "isBestMatch": true
    public var isBestMatch: Bool
}
