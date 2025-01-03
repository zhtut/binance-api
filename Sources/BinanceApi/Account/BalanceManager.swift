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
open class BalanceManager: NSObject, @unchecked Sendable {
    
    public static let shared = BalanceManager()
    
    var updatePositionTime: Int = 0
    
    /// 资产更新通知
    public var balancePublisher = PassthroughSubject<Void, Never>()
    
    /// 当前所有资产
    open var balances = [Balance]()
    
    public override init() {
        super.init()
        let timer = Timer(timeInterval: 3, repeats: true) { timer in
            self.refresh()
        }
        RunLoop.main.add(timer, forMode: .common)
        RunLoop.main.run()
    }
    
    open func updateWith(_ position: OutboundAccountPosition) {
        // 已经处理了后一条数据，这条是旧数据，直接抛弃
        if position.E < updatePositionTime {
            return
        }
        
        for assest in position.B {
            // 找到资产
            if let index = balances.firstIndex(where: { $0.asset == assest.a }) {
                // 更新资产
                var new = balances[index]
                new.free = assest.f
                new.locked = assest.l
                balances[index] = new
            } else {
                // 没找到对应的资产，加一个新的
                let new = Balance(asset: assest.a,
                                  free: assest.f,
                                  locked: assest.l,
                                  freeze: "",
                                  withdrawing: "",
                                  btcValuation: "")
                balances.append(new)
            }
        }
        
        log()
        
        updatePositionTime = position.E
        balancePublisher.send()
    }
    
    open func updateWith(_ balance: BalanceUpdate) {
        // 这里更新的信息不足，直接刷新一下好了
        refresh()
        balancePublisher.send()
    }
    
    open func refresh() {
        Task {
            let path = "GET /api/v3/account (HMAC SHA256)"
            let res = try await RestAPI.post(path: path, dataKey: "balances", dataClass: [Balance].self)
            if let arr = res.data as? [Balance] {
                balances = arr
            }
        }
    }
    
    open func log() {
        print("当前资产：")
        for bl in balances {
            if (bl.free.double ?? 0) > 0 ||
                (bl.locked.double ?? 0) > 0 {
                print("\(bl.asset)，可用：\(bl.free)，冻结：\(bl.locked)")
            }
        }
    }
}
