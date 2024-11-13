//
//  File.swift
//  
//
//  Created by zhtut on 2023/7/23.
//

import Foundation

/// Payload: 订单更新
/// 订单通过executionReport事件进行更新。
/// 执行类型
/// - NEW - 新订单已被引擎接受。
/// - CANCELED - 订单被用户取消。
/// - REPLACED - (保留字段，当前未使用)
/// - REJECTED - 新订单被拒绝 （这信息只会在撤消挂单再下单中发生，下新订单被拒绝但撤消挂单请求成功）。
/// - TRADE - 订单有新成交。
/// - EXPIRED - 订单已根据 Time In Force 参数的规则取消（e.g. 没有成交的 LIMIT FOK 订单或部分成交的 LIMIT IOC 订单）或者被交易所取消（e.g. -  强平或维护期间取消的订单）。
/// - TRADE_PREVENTION - 订单因 STP 触发而过期。
/// 备注: 通过将Z除以z可以找到平均价格。
///
/// 如果订单是OCO，则除了显示executionReport事件外，还将显示一个名为ListStatus的事件。
/// executionReport 中的仅在满足特定条件时才会出现的字段：
/// 字段    名称    描述    示例
/// d    Trailing Delta    出现在追踪止损订单中。    "d": 4
/// D    Trailing Time    "D": 1668680518494
/// j    Strategy Id    如果在请求中添加了strategyId参数，则会出现。    "j": 1
/// J    Strategy Type    如果在请求中添加了strategyType参数，则会出现。    "J": 1000000
/// v    Prevented Match Id    只有在因为 STP 导致订单失效时可见。    "v": 3
/// A    Prevented Quantity    "A":"3.000000"
/// B    Last Prevented Quantity    "B":"3.000000"
/// u    Trade Group Id    "u":1
/// U    Counter Order Id    "U":37
public struct ExecutionReport: Codable {
    
    public static let key = "executionReport"
    
    public var e: String // ": "executionReport",        // 事件类型
    public var E: Int // ": 1499405658658,            // 事件时间
    public var s: String // ": "ETHBTC",                 // 交易对
    public var c: String // ": "mUvoqJxFIILMdfAW5iGSOW", // clientOrderId
    public var S: Side // ": "BUY",                    // 订单方向
    public var o: String // ": "LIMIT",                  // 订单类型
    public var f: String // ": "GTC",                    // 有效方式
    public var q: String // ": "1.00000000",             // 订单原始数量
    public var p: String // ": "0.10264410",             // 订单原始价格
    public var P: String // ": "0.00000000",             // 止盈止损单触发价格
    public var F: String // ": "0.00000000",             // 冰山订单数量
    public var g: Int // ": -1,                       // OCO订单 OrderListId
    public var C: String // ": "",                       // 原始订单自定义ID(原始订单，指撤单操作的对象。撤单本身被视为另一个订单)
    public var x: String // ": "NEW",                    // 本次事件的具体执行类型
    public var X: Status // ": "NEW",                    // 订单的当前状态
    public var r: String // ": "NONE",                   // 订单被拒绝的原因
    public var i: Int // ": 4293153,                  // orderId
    public var l: String // ": "0.00000000",             // 订单末次成交量
    public var z: String // ": "0.00000000",             // 订单累计已成交量
    public var L: String // ": "0.00000000",             // 订单末次成交价格
    public var n: String // ": "0",                      // 手续费数量
    public var N: String? // ": null,                     // 手续费资产类别
    public var T: Int // ": 1499405658657,            // 成交时间
    public var t: Int // ": -1,                       // 成交ID
    public var v: Int? // ": 3,                        // 被阻止撮合交易的ID; 这仅在订单因 STP 触发而过期时可见
    public var I: Int // ": 8641984,                  // 请忽略
    public var w: Bool // ": true,                     // 订单是否在订单簿上？
    public var m: Bool // ": false,                    // 该成交是作为挂单成交吗？
    public var M: Bool // ": false,                    // 请忽略
    public var O: Int // ": 1499405658657,            // 订单创建时间
    public var Z: String // ": "0.00000000",             // 订单累计已成交金额
    public var Y: String // ": "0.00000000",             // 订单末次成交金额
    public var Q: String // ": "0.00000000",             // Quote Order Quantity
    public var W: Int // ": 1499405658657,            // Working Time; 订单被添加到 order book 的时间
    public var V: String // ": "NONE"                    // SelfTradePreventionMode
    
    /// 创建订单
    public var createOrder: Order {
        let order = Order(symbol: s,
                          orderId: i,
                          orderListId: g,
                          clientOrderId: c,
                          price: p,
                          origQty: q,
                          executedQty: z,
                          cummulativeQuoteQty: l,
                          status: X,
                          timeInForce: f,
                          type: o,
                          side: S,
                          stopPrice: L,
                          icebergQty: F,
                          time: T,
                          updateTime: E,
                          isWorking: w,
                          workingTime: W,
                          origQuoteOrderQty: q,
                          selfTradePreventionMode: V)
        return order
    }
}
