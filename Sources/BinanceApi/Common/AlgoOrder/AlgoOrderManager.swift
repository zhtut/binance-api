//
//  AlgoOrderManager.swift
//  binance-api
//
//  Created by tutuzhou on 2025/12/17.
//

import Foundation
import LoggingKit
import CommonUtils

public class AlgoOrderManager: @unchecked Sendable {
    
    public var symbol: Symbol
    
    public init(symbol: Symbol) {
        self.symbol = symbol
    }
    
    /// 下市价止损单
    public func postStopMarketOrder(isBuy: Bool,
                                    price: Decimal,
                                    clientAlgoId: String) async throws {
        let path = "POST /fapi/v1/algoOrder (HMAC SHA256)"
        var params = [
            "algoType": "CONDITIONAL",
            "symbol": symbol.symbol,
            "triggerprice": price,
            "side": isBuy ? Side.BUY.rawValue : Side.SELL.rawValue,
            "type": AlgoOrder.OrderType.STOP_MARKET.rawValue, // 市价止损单
            "closePosition": true,
            "clientAlgoId": clientAlgoId
        ] as [String : Any]
        let res = try await RestAPI.post(path: path, params: params)
    }
    
    /// 取消全部订单
    public static func cancelAllOrders(symbol: String) async throws {
        let path = "DELETE /fapi/v1/algoOpenOrders (HMAC SHA256)"
        let res = try await RestAPI.post(path: path, params: ["symbol": symbol])
        if res.succeed {
            logInfo("取消所有订单成功")
        } else {
            logInfo("取消所有订单失败：\(res.msg ?? "")")
        }
    }
    
    /// 查询所有条件单
    public func getOpenOrders() async throws -> [AlgoOrder] {
        let path = "GET /fapi/v1/openAlgoOrders (HMAC SHA256)"
        let res = try await RestAPI.post(path: path, dataClass: [AlgoOrder].self)
        print("res.json=\(res.res.bodyJson)")
        if let arr = res.data as? [AlgoOrder] {
            return arr
        }
        throw CommonError(message: "没有订单")
    }
}
