//
//  File.swift
//  
//
//  Created by zhtut on 2023/7/23.
//

import Foundation

/// 资产
public struct FeatureBalance: Codable {
    /// "accountAlias": "SgsR",              // 账户唯一识别码
    public var accountAlias: String
    /// "asset": "USDT",                      // 资产
    public var asset: String
    /// "balance": "122607.35137903",        // 总余额
    public var balance: String
    /// "crossWalletBalance": "23.72469206", // 全仓余额
    public var crossWalletBalance: String
    /// "crossUnPnl": "0.00000000"           // 全仓持仓未实现盈亏
    public var crossUnPnl: String
    /// "availableBalance": "23.72469206",   // 下单可用余额
    public var availableBalance: String
    /// "maxWithdrawAmount": "23.72469206",  // 最大可转出余额
    public var maxWithdrawAmount: String
    /// "marginAvailable": true,            // 是否可用作联合保证金
    public var marginAvailable: Bool
    /// "updateTime": 1617939110373
    public var updateTime: Int
}
