//
//  File.swift
//  
//
//  Created by zhtut on 2023/7/23.
//

import Foundation

/// 订单状态
public enum Status: String, Codable {
    /// 新建
    case NEW
    /// 部分成交
    case PARTIALLY_FILLED
    /// 全部成交
    case FILLED
    /// 取消了
    case CANCELED
    /// 失效了
    case EXPIRED
    ///  风险保障基金(强平)
    case NEW_INSURANCE
    /// 自动减仓序列(强平)
    case NEW_ADL
}

/// 买卖方向，买入还是卖出
public enum Side: String, Codable {
    /// 买入
    case BUY
    /// 卖出
    case SELL
}

/// 订单对象
public struct Order: Codable {
    
    public var symbol: String // ": "LTCBTC",
    public var orderId: Int // ": 1,
    public var orderListId: Int // ": -1, // OCO订单ID，否则为 -1
    public var clientOrderId: String // ": "myOrder1",
    public var price: String // ": "0.1",
    public var origQty: String // ": "1.0",
    public var executedQty: String // ": "0.0",
    public var cummulativeQuoteQty: String // ": "0.0",
    public var status: Status // ": "NEW",
    public var timeInForce: String // ": "GTC",
    public var type: String // ": "LIMIT",
    public var side: Side // ": "BUY",
    public var stopPrice: String // ": "0.0",
    public var icebergQty: String // ": "0.0",
    public var time: Int // ": 1499827319559,
    public var updateTime: Int // ": 1499827319559,
    public var isWorking: Bool // ": true,
    public var workingTime: Int // ": 1499827319559,
    public var origQuoteOrderQty: String // ": "0.000000",
    public var selfTradePreventionMode: String // ": "NONE"
    
    public init(symbol: String,
                orderId: Int,
                orderListId: Int,
                clientOrderId: String,
                price: String,
                origQty: String,
                executedQty: String,
                cummulativeQuoteQty: String,
                status: Status,
                timeInForce: String,
                type: String,
                side: Side,
                stopPrice: String,
                icebergQty: String,
                time: Int,
                updateTime: Int,
                isWorking: Bool,
                workingTime: Int,
                origQuoteOrderQty: String,
                selfTradePreventionMode: String) {
        self.symbol = symbol
        self.orderId = orderId
        self.orderListId = orderListId
        self.clientOrderId = clientOrderId
        self.price = price
        self.origQty = origQty
        self.executedQty = executedQty
        self.cummulativeQuoteQty = cummulativeQuoteQty
        self.status = status
        self.timeInForce = timeInForce
        self.type = type
        self.side = side
        self.stopPrice = stopPrice
        self.icebergQty = icebergQty
        self.time = time
        self.updateTime = updateTime
        self.isWorking = isWorking
        self.workingTime = workingTime
        self.origQuoteOrderQty = origQuoteOrderQty
        self.selfTradePreventionMode = selfTradePreventionMode
    }
    
    /// 是否还在等待成交中
    public var isWaitingFill: Bool {
        if status == .NEW ||
            status == .PARTIALLY_FILLED {
            return true
        }
        return false
    }
    
    /// 取消订单
    public func cancel() async throws {
        let path = "DELETE /api/v3/order (HMAC SHA256)"
        let params = ["symbol": symbol, "orderId": orderId] as [String : Any]
        try await RestAPI.post(path: path, params: params)
    }
}
