//
//  TradeOrderUpdate.swift
//  binance-api
//
//  Created by tutuzhou on 2024/11/14.
//

import Foundation

/// 定义TradeOrderUpdate结构体，用于表示交易订单更新相关信息，并遵循Codable协议用于数据解析
public struct FeatureTradeOrderUpdate: Codable {
    
    public static let key = "ORDER_TRADE_UPDATE"
    
    /// 事件类型
    public let e: String
    /// 撮合时间
    public let T: Int
    /// 事件时间
    public let E: Int
    
    /// 定义内部结构体用于存放订单详细信息，遵循Codable协议
    public struct OrderDetails: Codable {
        /// 交易对
        public let s: String
        /// 客户端自定订单ID
        public let c: String
        /// 订单方向（例如：SELL、BUY）
        public let S: Side
        /// 订单类型（例如：TRAILING_STOP_MARKET等）
        public let o: String
        /// 有效方式（例如：GTC等）
        public let f: String
        /// 订单原始数量
        public let q: String
        /// 订单原始价格
        public let p: String
        /// 订单平均价格
        public let ap: String
        /// 条件订单触发价格，对追踪止损单无效
        public let sp: String
        /// 本次事件的具体执行类型
        public let x: String
        /// 订单的当前状态
        public let X: Status
        /// 订单ID
        public let i: Int
        /// 订单末次成交量
        public let l: String
        /// 订单累计已成交量
        public let z: String
        /// 订单末次成交价格
        public let L: String
        /// 手续费资产类型
        public let N: String
        /// 手续费数量
        public let n: String
        /// 成交时间
        public let T: Int
        /// 成交ID
        public let t: Int
        /// 买单净值
        public let b: String
        /// 卖单净值
        public let a: String
        /// 该成交是作为挂单成交吗？
        public let m: Bool
        /// 是否是只减仓单
        public let R: Bool
        /// 触发价类型
        public let wt: String
        /// 原始订单类型
        public let ot: String
        /// 持仓方向（例如：LONG、SHORT）
        public let ps: String
        /// 是否为触发平仓单; 仅在条件订单情况下会推送此字段
        public let cp: Bool?
        /// 该交易实现盈亏
        public let rp: String?
        /// 是否开启条件单触发保护
        public let pP: Bool?
        /// 追踪止损回调比例, 仅在追踪止损单时会推送此字段
        public let cr: String?
        /// 追踪止损激活价格, 仅在追踪止损单时会推送此字段
        public let AP: String?
        /// 忽略（此处暂未明确用途，按照接口文档原样保留属性名）
        public let si: Int?
        /// 忽略（此处暂未明确用途，按照接口文档原样保留属性名）
        public let ss: Int?
        /// 自成交防止模式
        public let V: String?
        /// 价格匹配模式
        public let pm: String?
        /// TIF为GTD的订单自动取消时间
        public let gtd: Int?
    }
    
    /// 包含订单详细信息的内部结构体
    public let o: OrderDetails
    
    /// 创建订单
    public var createOrder: FeatureOrder {
        let order = FeatureOrder(
            avgPrice: o.ap,
            clientOrderId: o.c,
            cumQuote: o.b,
            executedQty: o.z,
            orderId: o.i,
            origQty: o.q,
            origType: o.ot,
            price: o.p,
            reduceOnly: o.R,
            side: o.S,
            positionSide: o.ps,
            status: o.X,
            stopPrice: o.sp,
            closePosition: o.cp,
            symbol: o.s,
            time: o.T,
            timeInForce: nil,
            type: o.o,
            updateTime: E,
            workingType: o.wt,
            priceProtect: o.pP,
            priceMatch: o.pm,
            selfTradePreventionMode: o.V
        )
        
        return order
    }
}
