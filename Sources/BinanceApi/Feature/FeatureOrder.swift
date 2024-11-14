//
//  File.swift
//  
//
//  Created by zhtut on 2023/7/23.
//

import Foundation

/// 订单对象
public struct FeatureOrder: Codable {
    
    /// 平均成交价
    var avgPrice: String
    
    /// 用户自定义的订单号
    var clientOrderId: String
    
    /// 成交金额
    var cumQuote: String
    
    /// 成交量
    var executedQty: String
    
    /// 系统订单号
    var orderId: Int
    
    /// 原始委托数量
    var origQty: String
    
    /// 触发前订单类型
    var origType: String
    
    /// 委托价格
    var price: String
    
    /// 是否仅减仓
    var reduceOnly: Bool
    
    /// 买卖方向
    var side: Side
    
    /// 持仓方向
    var positionSide: String?
    
    /// 订单状态
    var status: Status
    
    /// 触发价，对`TRAILING_STOP_MARKET`无效
    var stopPrice: String
    
    /// 是否条件全平仓
    var closePosition: Bool?
    
    /// 交易对
    var symbol: String
    
    /// 订单时间
    var time: Int
    
    /// 有效方法
    var timeInForce: String?
    
    /// 订单类型
    var type: String
    
    /// 跟踪止损激活价格, 仅`TRAILING_STOP_MARKET` 订单返回此字段
    var activatePrice: String?
    
    /// 跟踪止损回调比例, 仅`TRAILING_STOP_MARKET` 订单返回此字段
    var priceRate: String?
    
    /// 更新时间
    var updateTime: Int
    
    /// 条件价格触发类型
    var workingType: String
    
    /// 是否开启条件单触发保护
    var priceProtect: Bool?
    
    /// 盘口价格下单模式
    var priceMatch: String?
    
    /// 订单自成交保护模式
    var selfTradePreventionMode: String?
    
    /// 订单TIF为GTD时的自动取消时间
    var goodTillDate: Int?
    
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
        let path = "DELETE /fapi/v1/order (HMAC SHA256)"
        let params = ["symbol": symbol, "orderId": orderId] as [String : Any]
        try await RestAPI.post(path: path, params: params)
    }
}
