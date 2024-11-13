//
//  File.swift
//  
//
//  Created by zhtut on 2023/7/23.
//

import Foundation

/// 资产
public struct Balance: Codable {
    public var asset: String  // ": "USDT",
    public var free: String  // ": "1",    // 可用余额
    public var locked: String  // ": "0",  // 锁定资金
    public var freeze: String?  // ": "0",  //冻结资金
    public var withdrawing: String?  // ": "0",  // 提币
    public var btcValuation: String?  // ": "0.00000091"  // btc估值
    
    public init(asset: String,
                free: String,
                locked: String,
                freeze: String?,
                withdrawing: String?,
                btcValuation: String?) {
        self.asset = asset
        self.free = free
        self.locked = locked
        self.freeze = freeze
        self.withdrawing = withdrawing
        self.btcValuation = btcValuation
    }
}
