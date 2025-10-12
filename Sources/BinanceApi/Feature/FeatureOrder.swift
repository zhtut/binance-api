//
//  File.swift
//  
//
//  Created by zhtut on 2023/7/23.
//

import Foundation

/// 订单对象
public struct FeatureOrder: Codable, Sendable {
    
    /// 平均成交价
    public var avgPrice: String
    
    /// 用户自定义的订单号
    public var clientOrderId: String
    
    /// 成交金额
    public var cumQuote: String
    
    /// 成交量
    public var executedQty: String
    
    /// 系统订单号
    public var orderId: Int
    
    /// 原始委托数量
    public var origQty: String
    
    /// 触发前订单类型
    public var origType: String
    
    /// 委托价格
    public var price: String
    
    /// 是否仅减仓
    public var reduceOnly: Bool
    
    /// 买卖方向
    public var side: Side
    
    /// 持仓方向
    public var positionSide: String?
    
    /// 订单状态
    public var status: Status
    
    /// 触发价，对`TRAILING_STOP_MARKET`无效
    public var stopPrice: String
    
    /// 是否条件全平仓
    public var closePosition: Bool?
    
    /// 交易对
    public var symbol: String
    
    /// 订单时间
    public var time: Int
    
    /// 有效方法
    public var timeInForce: String?
    
    /// 订单类型
    public var type: String
    
    /// 跟踪止损激活价格, 仅`TRAILING_STOP_MARKET` 订单返回此字段
    public var activatePrice: String?
    
    /// 跟踪止损回调比例, 仅`TRAILING_STOP_MARKET` 订单返回此字段
    public var priceRate: String?
    
    /// 更新时间
    public var updateTime: Int
    
    /// 条件价格触发类型
    public var workingType: String
    
    /// 是否开启条件单触发保护
    public var priceProtect: Bool?
    
    /// 盘口价格下单模式
    public var priceMatch: String?
    
    /// 订单自成交保护模式
    public var selfTradePreventionMode: String?
    
    /// 订单TIF为GTD时的自动取消时间
    public var goodTillDate: Int?
    
    /// 是否还在等待成交中
    public var isWaitingFill: Bool {
        if status == .NEW ||
            status == .PARTIALLY_FILLED {
            return true
        }
        return false
    }
    
    /// 取消订单
    public func cancel() {
        Task.detached { [self] in
            let path = "DELETE /fapi/v1/order (HMAC SHA256)"
            let params = ["symbol": symbol, "orderId": orderId] as [String : Any]
            try await RestAPI.post(path: path, params: params)
        }
    }
    
    /// 取消订单
    public func cancel() async throws {
        let path = "DELETE /fapi/v1/order (HMAC SHA256)"
        let params = ["symbol": symbol, "orderId": orderId] as [String : Any]
        try await RestAPI.post(path: path, params: params)
    }
}
