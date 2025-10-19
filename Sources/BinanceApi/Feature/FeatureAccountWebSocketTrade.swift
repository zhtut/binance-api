//
//  FeatureAccountWebSocketTrade.swift
//  binance-api
//
//  Created by tutuzhou on 2025/10/17.
//

import Foundation
import LoggingKit

public extension FeatureAccountWebSocket {
    func postOrder() async throws {
//        {
//            "id": "3f7df6e3-2df4-44b9-9919-d2f38f90a99a",
//            "method": "order.place",
//            "params": {
//                "apiKey": "HMOchcfii9ZRZnhjp2XjGXhsOBd6msAhKz9joQaWwZ7arcJTlD2hGPHQj1lGdTjR",
//                "positionSide": "BOTH",
//                "price": 43187.00,
//                "quantity": 0.1,
//                "side": "BUY",
//                "symbol": "BTCUSDT",
//                "timeInForce": "GTC",
//                "timestamp": 1702555533821,
//                "type": "LIMIT",
//                "signature": "0f04368b2d22aafd0ggc8809ea34297eff602272917b5f01267db4efbc1c9422"
//            }
//        }
        let params: [String: Any] = [
            "apiKey": try APIConfig.shared.requireApiKey(),
            "positionSide": "BOTH",
            "price": 110187.00,
            "quantity": 0.1,
            "side": "BUY",
            "symbol": "BTCUSDT",
            "timeInForce": "GTC",
            "type": "LIMIT",
        ]
        let signParams = try params.addSignature()
        let clientId = UUID().uuidString
        let fullParams: [String: Any] = [
            "id": clientId,
            "method": "order.place",
            "params": signParams
        ]
        logInfo("准备ws登录：\(fullParams)")
        let jsonData = try JSONSerialization.data(withJSONObject: fullParams)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            try await ws.send(jsonString)
        }
    }
}
