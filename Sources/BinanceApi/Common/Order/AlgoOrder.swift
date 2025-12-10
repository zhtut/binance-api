//
//  AlgoOrder.swift
//  binance-api
//
//  Created by tutuzhou on 2025/12/11.
//

import Foundation

public struct AlgoOrder: Codable, Sendable {
/// "algoId": 2146760,
    var algoId: Int
/// "clientAlgoId": "6B2I9XVcJpCjqPAJ4YoFX7",
    var clientAlgoId: String
/// "algoType": "CONDITIONAL",
    var algoType: String
/// "orderType": "TAKE_PROFIT",
    var orderType: String
/// "symbol": "BNBUSDT",
    var symbol: String
/// "side": "SELL",
    var side: String
/// "positionSide": "BOTH",
    var positionSide: String
/// "timeInForce": "GTC",
    var timeInForce: String
/// "quantity": "0.01",
    var quantity: String
/// "algoStatus": "CANCELED",
    var algoStatus: String
/// "actualOrderId": "",
    var actualOrderId: String
/// "actualPrice": "0.00000",
    var actualPrice: String
/// "triggerPrice": "750.000",
    var triggerPrice: String
/// "price": "750.000",
    var price: String
/// "icebergQuantity": null,
    var icebergQuantity: String
/// "tpTriggerPrice": "0.000",
    var tpTriggerPrice: String
/// "tpPrice": "0.000",
    var tpPrice: String
/// "slTriggerPrice": "0.000",
    var slTriggerPrice: String
/// "slPrice": "0.000",
    var slPrice: String
/// "tpOrderType": "",
    var tpOrderType: String
/// "selfTradePreventionMode": "EXPIRE_MAKER",
    var selfTradePreventionMode: String
/// "workingType": "CONTRACT_PRICE",
    var workingType: String
/// "priceMatch": "NONE",
    var priceMatch: String
/// "closePosition": false,
    var closePosition: Bool
/// "priceProtect": false,
    var priceProtect: Bool
/// "reduceOnly": false,
    var reduceOnly: Bool
/// "createTime": 1750485492076,
    var createTime: Int
/// "updateTime": 1750514545091,
    var updateTime: Int
/// "triggerTime": 0,
    var triggerTime: Int
/// "goodTillDate": 0
    var goodTillDate: Int
}
