//
//  AccountUpdate.swift
//  binance-api
//
//  Created by tutuzhou on 2024/11/14.
//

import Foundation

/// Payload: 余额更新
/// 当下列情形发生时更新:
/// - 账户发生充值或提取
/// - 交易账户之间发生划转(例如 现货向杠杆账户划转)
public struct FeatureAccountUpdate: Codable {
    
    public static let key = "ACCOUNT_UPDATE"
    
    public var e: String // ": "balanceUpdate",         //Event Type
    public var T: Int // ": 1573200697068            //Clear Time
    public var E: Int // ": 1573200697110,           //Event Time
    public var a: FeatureAccountUpdate.Account // ": "ABC",                   //Asset
    
    public struct Account: Codable {
        
        /// 余额信息
        public var B: [FeatureAccountUpdate.Balance]
        
        /// 持仓
        public var P: [FeatureAccountUpdate.Position]
        
        /// "m":"ORDER",                        // 事件推出原因
        public var m: String
    }
    
    public struct Balance: Codable {
        /// "a":"USDT",                   // 资产名称
        public var a: String
        /// "wb":"122624.12345678",        // 钱包余额
        public var wb: String
        /// "cw":"100.12345678",            // 除去逐仓仓位保证金的钱包余额
        public var cw: String
        /// "bc":"50.12345678"            // 除去盈亏与交易手续费以外的钱包余额改变量
        public var bc: String
    }
    
    public struct Position: Codable {
        /// "s":"BTCUSDT",              // 交易对
        public var s: String
        /// "pa":"0",                   // 仓位
        public var pa: String
        /// "ep":"0.00000",            // 入仓价格
        public var ep: String
        /// "cr":"200",                 // (费前)累计实现损益
        public var cr: String
        /// "up":"0",                        // 持仓未实现盈亏
        public var up: String
        /// "mt":"isolated",                // 保证金模式
        public var mt: String
        /// "iw":"0.00000000",            // 若为逐仓，仓位保证金
        public var iw: String
        /// "ps":"BOTH"                    // 持仓方向
        public var ps: String
        /// "ma": "USDT",
        public var ma: String
        /// "bep":"0",                // 盈亏平衡价
        public var bep: String
    }
}
