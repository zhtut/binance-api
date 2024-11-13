//
//  File.swift
//  
//
//  Created by zhtut on 2023/7/23.
//

import Foundation

/// Payload: 余额更新
/// 当下列情形发生时更新:
/// - 账户发生充值或提取
/// - 交易账户之间发生划转(例如 现货向杠杆账户划转)
public struct BalanceUpdate: Codable {
    
    public static let key = "balanceUpdate"
    
    public var e: String // ": "balanceUpdate",         //Event Type
    public var E: Int // ": 1573200697110,           //Event Time
    public var a: String // ": "ABC",                   //Asset
    public var d: String // ": "100.00000000",          //Balance Delta
    public var T: Int // ": 1573200697068            //Clear Time
}
