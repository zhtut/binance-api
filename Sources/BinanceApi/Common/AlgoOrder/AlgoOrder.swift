//
//  AlgoOrder.swift
//  binance-api
//
//  Created by tutuzhou on 2025/12/11.
//

import Foundation
import DefaultCodable

//actualOrderId = "";
//actualPrice = "0.00000";
//algoId = 4000000055631905;
//algoStatus = NEW;
//algoType = CONDITIONAL;
//clientAlgoId = cmLXppuAOm8Zd9J5VKkQCg;
//closePosition = 1;
//createTime = 1765906028682;
//goodTillDate = 0;
//icebergQuantity = "<null>";
//orderType = "STOP_MARKET";
//positionSide = BOTH;
//price = "0.00";
//priceMatch = NONE;
//priceProtect = 0;
//quantity = "0.000";
//reduceOnly = 1;
//selfTradePreventionMode = "EXPIRE_MAKER";
//side = SELL;
//symbol = ETHUSDC;
//timeInForce = "GTE_GTC";
//tpOrderType = "";
//triggerPrice = "2900.00";
//triggerTime = 0;
//updateTime = 1765906028682;
//workingType = "CONTRACT_PRICE";

/// 条件单
public struct AlgoOrder: Codable, Sendable {
    
    public enum OrderType: String, Codable, Sendable {
        case STOP, TAKE_PROFIT, STOP_MARKET, TAKE_PROFIT_MARKET, TRAILING_STOP_MARKET
    }
    
    /// "algoId": 2146760,
    @Default
    public var algoId: Int
    /// "clientAlgoId": "6B2I9XVcJpCjqPAJ4YoFX7",
    @Default
    public var clientAlgoId: String
    /// "algoType": "CONDITIONAL",
    @Default
    public var algoType: String
    /// "orderType": "TAKE_PROFIT",
    public var orderType: OrderType
    /// "symbol": "BNBUSDT",
    @Default
    public var symbol: String
    /// "side": "SELL",
    public var side: Side
    /// "positionSide": "BOTH",
    @Default
    public var positionSide: String
    /// "timeInForce": "GTC",
    @Default
    public var timeInForce: String
    /// "quantity": "0.01",
    @Default
    public var quantity: String
    /// "algoStatus": "CANCELED",
    public var algoStatus: Status
    /// "actualOrderId": "",
    @Default
    public var actualOrderId: String
    /// "actualPrice": "0.00000",
    @Default
    public var actualPrice: String
    /// "triggerPrice": "750.000",
    @Default
    public var triggerPrice: String
    /// "price": "750.000",
    @Default
    public var price: String
    /// "icebergQuantity": null,
    @Default
    public var icebergQuantity: String
    /// "tpTriggerPrice": "0.000",
    @Default
    public var tpTriggerPrice: String
    /// "tpPrice": "0.000",
    @Default
    public var tpPrice: String
    /// "slTriggerPrice": "0.000",
    @Default
    public var slTriggerPrice: String
    /// "slPrice": "0.000",
    @Default
    public var slPrice: String
    /// "tpOrderType": "",
    @Default
    public var tpOrderType: String
    /// "selfTradePreventionMode": "EXPIRE_MAKER",
    @Default
    public var selfTradePreventionMode: String
    /// "workingType": "CONTRACT_PRICE",
    @Default
    public var workingType: String
    /// "priceMatch": "NONE",
    @Default
    public var priceMatch: String
    /// "closePosition": false,
    @Default
    public var closePosition: Bool
    /// "priceProtect": false,
    @Default
    public var priceProtect: Bool
    /// "reduceOnly": false,
    @Default
    public var reduceOnly: Bool
    /// "createTime": 1750485492076,
    @Default
    public var createTime: Int
    /// "updateTime": 1750514545091,
    @Default
    public var updateTime: Int
    /// "triggerTime": 0,
    @Default
    public var triggerTime: Int
    /// "goodTillDate": 0
    @Default
    public var goodTillDate: Int
}

public extension AlgoOrder {
    /// 取消订单
    public func cancel() {
        Task {
            let path = "DELETE /fapi/v1/algoOrder (HMAC SHA256)"
            let params = ["symbol": symbol, "algoid": algoId] as [String : Any]
            try await RestAPI.post(path: path, params: params)
        }
    }
}
