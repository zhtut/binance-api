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

/// 资产管理，这个跟品种无关
open class FeatureBalanceManager: NSObject, @unchecked Sendable {
    
    public static let shared = FeatureBalanceManager()
    
    var updatePositionTime: Int = 0
    
    /// 资产更新通知
    public var balancePublisher = PassthroughSubject<Void, Never>()
    
    /// 当前所有资产
    open var balances = [FeatureBalance]()
    
    public override init() {
        super.init()
        let timer = Timer(timeInterval: 3, repeats: true) { timer in
            self.refresh()
        }
        RunLoop.main.add(timer, forMode: .common)
        RunLoop.main.run()
    }
    
    open func updateWith(_ update: FeatureAccountUpdate) {
        // 已经处理了后一条数据，这条是旧数据，直接抛弃
        if update.E < updatePositionTime {
            return
        }
        
        for asset in update.a.B {
            // 找到资产
            if let index = balances.firstIndex(where: { $0.asset == asset.a }) {
                // 更新资产
                var new = balances[index]
                new.availableBalance = asset.cw
                new.balance = asset.a
                balances[index] = new
            } else {
                // 没找到对应的资产，加一个新的
                let new = FeatureBalance(
                    accountAlias: "",
                    asset: asset.a,
                    balance: asset.wb,
                    crossWalletBalance: "",
                    crossUnPnl: "",
                    availableBalance: asset.cw,
                    maxWithdrawAmount: "",
                    marginAvailable: true,
                    updateTime: 0
                )
                balances.append(new)
            }
        }
        
        log()
        
        updatePositionTime = update.E
        balancePublisher.send()
    }
    
//    open func updateWith(_ balance: BalanceUpdate) {
//        // 这里更新的信息不足，直接刷新一下好了
//        refresh()
//        balancePublisher.send()
//    }
    
    open func refresh() {
        Task {
            let path = "GET /fapi/v3/balance (HMAC SHA256)"
            let res = try await RestAPI.post(path: path, dataClass: [FeatureBalance].self)
            if let arr = res.data as? [FeatureBalance] {
                balances = arr
            }
        }
    }
    
    open func log() {
        print("当前资产：")
        for bl in balances {
            if (bl.availableBalance.double ?? 0) > 0 {
                print("\(bl.asset)，总额：\(bl.balance)，可用：\(bl.availableBalance)")
            }
        }
    }
}
