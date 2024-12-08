//
//  File.swift
//
//
//  Created by zhtut on 2023/7/23.
//

import Foundation
#if canImport(CombineX)
import CombineX
#else
import Combine
#endif

/// 账户信息
open class FeatureAccountManager: NSObject, @unchecked Sendable {
    
    public static let shared = FeatureAccountManager()
    
    var updatePositionTime: Int = 0
    
    /// 账户更新通知
    public var accountPublisher = PassthroughSubject<Void, Never>()
    
    private var _account = NIOLockedValueBox<FeatureAccount?>(nil)
    
    /// 账户对象
    open var account: FeatureAccount? {
        get {
            _account.withLockedValue({ $0 })
        }
        set {
            _account.withLockedValue({ $0 = newValue })
        }
    }
    
    private var _assets = NIOLockedValueBox([FeatureAccount.Asset]())
    
    /// 当前所有资产
    open var assets: [FeatureAccount.Asset] {
        get {
            _assets.withLockedValue({ $0 })
        }
        set {
            _assets.withLockedValue({ $0 = newValue })
        }
    }

    /// usdt的余额
    open var usdtBal: Decimal {
        if let usdt = assets.first(where: { $0.asset == "USDT" }) {
            return usdt.availableBalance.defaultDecimal()
        }
        return 0.0
    }
    
    private var _positions = NIOLockedValueBox([FeatureAccount.Position]())
    
    /// 当前所有持仓
    open var positions: [FeatureAccount.Position] {
        get {
            _positions.withLockedValue({ $0 })
        }
        set {
            _positions.withLockedValue({ $0 = newValue })
        }
    }
    
    public override init() {
        super.init()
    }
    
    open func updateWith(_ update: FeatureAccountUpdate) async {
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
            if let pa = position.pa.double, pa > 0 {
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
    
    //    open func updateWith(_ balance: BalanceUpdate) {
    //        // 这里更新的信息不足，直接刷新一下好了
    //        refresh()
    //        balancePublisher.send()
    //    }
    
    open func refresh() {
        Task {
            do {
                let path = "GET /fapi/v3/account (HMAC SHA256)"
                let res = try await RestAPI.post(path: path, dataClass: FeatureAccount.self)
                if let acc = res.data as? FeatureAccount {
                    account = acc
                    assets = acc.assets
                    positions = acc.positions ?? []
                    log()
                }
            } catch {
                print("请求账户信息失败：\(error)")
            }
        }
    }
    
    open func log() {
        print("当前资产：")
        for bl in assets {
            if (bl.availableBalance.double ?? 0) > 0 {
                print("\(bl.asset)，总额：\(bl.walletBalance)，可用：\(bl.availableBalance)")
            }
        }
        
        if !positions.isEmpty {
            print("当前持仓：")
            for p in positions {
                print("持仓\(p.symbol)，持仓数量：\(p.positionAmt)，方向：\(p.positionSide)")
            }
        } else {
            print("当前无持仓")
        }
    }
}
