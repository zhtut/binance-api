//
//  File.swift
//  
//
//  Created by zhtut on 2023/7/23.
//

import Foundation

/// 账户
public struct FeatureAccount: Codable {
    /// "totalInitialMargin": "0.00000000",            // 当前所需起始保证金总额(存在逐仓请忽略), 仅计算usdt资产positions), only for USDT asset
    public var totalInitialMargin: String
    /// "totalMaintMargin": "0.00000000",                 // 维持保证金总额, 仅计算usdt资产
    public var totalMaintMargin: String
    /// "totalWalletBalance": "103.12345678",          // 账户总余额, 仅计算usdt资产
    public var totalWalletBalance: String
    /// "totalUnrealizedProfit": "0.00000000",         // 持仓未实现盈亏总额, 仅计算usdt资产
    public var totalUnrealizedProfit: String
    /// "totalMarginBalance": "103.12345678",          // 保证金总余额, 仅计算usdt资产
    public var totalMarginBalance: String
    /// "totalPositionInitialMargin": "0.00000000",    // 持仓所需起始保证金(基于最新标记价格), 仅计算usdt资产
    public var totalPositionInitialMargin: String
    /// "totalOpenOrderInitialMargin": "0.00000000",   // 当前挂单所需起始保证金(基于最新标记价格), 仅计算usdt资产
    public var totalOpenOrderInitialMargin: String
    /// "totalCrossWalletBalance": "103.12345678",     // 全仓账户余额, 仅计算usdt资产
    public var totalCrossWalletBalance: String
    /// "totalCrossUnPnl": "0.00000000",               // 全仓持仓未实现盈亏总额, 仅计算usdt资产
    public var totalCrossUnPnl: String
    /// "availableBalance": "103.12345678",            // 可用余额, 仅计算usdt资产
    public var availableBalance: String
    /// "maxWithdrawAmount": "103.12345678"            // 最大可转出余额, 仅计算usdt资产
    public var maxWithdrawAmount: String
    
    public struct Asset: Codable {
        /// "asset": "USDT",                        // 资产
        public var asset: String
        /// "walletBalance": "23.72469206",         // 余额
        public var walletBalance: String
        /// "unrealizedProfit": "0.00000000",       // 未实现盈亏
        public var unrealizedProfit: String
        /// "marginBalance": "23.72469206",         // 保证金余额
        public var marginBalance: String
        /// "maintMargin": "0.00000000",            // 维持保证金
        public var maintMargin: String
        /// "initialMargin": "0.00000000",          // 当前所需起始保证金
        public var initialMargin: String
        /// "positionInitialMargin": "0.00000000",  // 持仓所需起始保证金(基于最新标记价格)
        public var positionInitialMargin: String
        /// "openOrderInitialMargin": "0.00000000", // 当前挂单所需起始保证金(基于最新标记价格)
        public var openOrderInitialMargin: String
        /// "crossWalletBalance": "23.72469206",    // 全仓账户余额
        public var crossWalletBalance: String
        /// "crossUnPnl": "0.00000000"              // 全仓持仓未实现盈亏
        public var crossUnPnl: String
        /// "availableBalance": "23.72469206",      // 可用余额
        public var availableBalance: String
        /// "maxWithdrawAmount": "23.72469206",     // 最大可转出余额
        public var maxWithdrawAmount: String
        /// "updateTime": 1625474304765             // 更新时间
        public var updateTime: Int
    }
    
    public var assets: [Asset]
    
    public struct Position: Codable {
        /// "symbol": "BTCUSDT",               // 交易对
        public var symbol: String
        /// "positionSide": "BOTH",            // 持仓方向
        public var positionSide: String
        /// "positionAmt": "1.000",            // 持仓数量
        public var positionAmt: String
        /// "unrealizedProfit": "0.00000000",  // 持仓未实现盈亏
        public var unrealizedProfit: String
        /// "isolatedMargin": "0.00000000",
        public var isolatedMargin: String
        /// "notional": "0",
        public var notional: String
        /// "isolatedWallet": "0",
        public var isolatedWallet: String
        /// "initialMargin": "0",              // 持仓所需起始保证金(基于最新标记价格)
        public var initialMargin: String
        /// "maintMargin": "0",                // 当前杠杆下用户可用的最大名义价值
        public var maintMargin: String
        /// "updateTime": 0                    // 更新时间
        public var updateTime: Int
        
        public var isBuy: Bool {
            positionAmt.double ?? 0 > 0
        }
    }
    
    public var positions: [Position]?
}
