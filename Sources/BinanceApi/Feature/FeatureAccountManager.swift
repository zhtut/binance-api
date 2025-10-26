//
//  File.swift
//
//
//  Created by zhtut on 2023/7/23.
//

import Foundation
import LoggingKit
import NIOLockedValue
import CombineX

/// 账户信息
public class FeatureAccountManager: @unchecked Sendable {
    
    public static let shared = FeatureAccountManager()
    
    @NIOLocked
    var updatePositionTime: Int = 0
    
    /// 账户更新通知
    public var accountPublisher = PassthroughSubject<Void, Never>()
    
    /// 账户对象
    @NIOLocked
    public var account: FeatureAccount?
    
    /// 当前所有资产
    @NIOLocked
    public var assets = [FeatureAccount.Asset]()

    /// usdt的余额
    public var usdtAvailable: Decimal {
        if let usdt = assets.first(where: { $0.asset == "USDT" }) {
            return usdt.availableBalance.defaultDecimal()
        }
        return 0.0
    }
    
    /// usdt的余额
    public var usdtBal: Decimal {
        if let usdt = assets.first(where: { $0.asset == "USDT" }) {
            return usdt.walletBalance.defaultDecimal()
        }
        return 0.0
    }
    
    /// usdc的余额
    public var usdcAvailable: Decimal {
        if let usdt = assets.first(where: { $0.asset == "USDC" }) {
            return usdt.availableBalance.defaultDecimal()
        }
        return 0.0
    }
    
    /// usdc的余额
    public var usdcBal: Decimal {
        if let usdt = assets.first(where: { $0.asset == "USDC" }) {
            return usdt.walletBalance.defaultDecimal()
        }
        return 0.0
    }
    
    /// 当前所有持仓
    @NIOLocked
    public var positions = [FeatureAccount.Position]()
    
    public func updateWith(_ update: FeatureAccountUpdate) {
        // 已经处理了后一条数据，这条是旧数据，直接抛弃
        if update.E < updatePositionTime {
            return
        }
        
        for asset in update.a.B {
            // 找到资产
            if let index = assets.firstIndex(where: { $0.asset == asset.a }) {
                // 更新资产
                var new = assets[index]
                new.crossWalletBalance = asset.cw
                new.walletBalance = asset.wb
                assets[index] = new
            } else {
                // 没找到对应的资产，加一个新的
                let new = FeatureAccount.Asset(
                    asset: asset.a,
                    walletBalance: asset.wb,
                    unrealizedProfit: "",
                    marginBalance: "",
                    maintMargin: "",
                    initialMargin: "",
                    positionInitialMargin: "",
                    openOrderInitialMargin: "",
                    crossWalletBalance: asset.cw,
                    crossUnPnl: "",
                    availableBalance: asset.wb,
                    maxWithdrawAmount: "",
                    updateTime: update.E
                )
                assets.append(new)
            }
        }
        
        for position in update.a.P {
            if let pa = position.pa.double, pa != 0 {
                // 找到持仓
                if let index = positions.firstIndex(where: { $0.symbol == position.s }) {
                    // 更新资产
                    var new = positions[index]
                    new.positionAmt = position.pa
                    new.unrealizedProfit = position.up
                    new.positionSide = position.ps
                    new.isolatedWallet = position.iw
                    positions[index] = new
                } else {
                    // 没找到对应的资产，加一个新的
                    let new = FeatureAccount.Position(
                        symbol: position.s,
                        positionSide: position.ps,
                        positionAmt: position.pa,
                        unrealizedProfit: position.up,
                        isolatedMargin: "",
                        notional: "",
                        isolatedWallet: position.iw,
                        initialMargin: "",
                        maintMargin: "",
                        updateTime: update.E
                    )
                    positions.append(new)
                }
            } else {
                // 没有持仓，移除先前的
                positions.removeAll(where: { $0.symbol ==  position.s })
            }
        }
        
        log()
        
        updatePositionTime = update.E
        accountPublisher.send()
    }
    
    //    public func updateWith(_ balance: BalanceUpdate) {
    //        // 这里更新的信息不足，直接刷新一下好了
    //        refresh()
    //        balancePublisher.send()
    //    }
    
    public func refresh() {
        Task { [self] in
            do {
                let path = "GET /fapi/v3/account (HMAC SHA256)"
                let res = try await RestAPI.post(path: path, dataClass: FeatureAccount.self)
                if let acc = res.data as? FeatureAccount {
                    setAccount(acc)
                }
            } catch {
                logError("请求账户信息失败：\(error)")
            }
        }
    }
    
    func setAccount(_ acc: FeatureAccount) {
        account = acc
        assets = acc.assets
        positions = acc.positions ?? []
        log(isRefresh: true)
    }
    
    public func log(isRefresh: Bool = false) {
        if isRefresh {
            logInfo("接口刷新到当前资产：")
        } else {
            logInfo("当前资产：")
        }
        for bl in assets {
            if (bl.availableBalance.double ?? 0) > 0 {
                logInfo("\(bl.asset)，总额：\(bl.walletBalance)，可用：\(bl.availableBalance)")
            }
        }
        
        if !positions.isEmpty {
            logInfo("当前持仓：")
            for p in positions {
                logInfo("持仓\(p.symbol)，持仓数量：\(p.positionAmt)，方向：\(p.positionSide)")
            }
        } else {
            logInfo("当前无持仓")
        }
    }
    
    /// 清除全部仓位
    public func closeAllPosition() async throws {
        for p in positions {
            try await p.closePositionNow()
        }
    }
}
