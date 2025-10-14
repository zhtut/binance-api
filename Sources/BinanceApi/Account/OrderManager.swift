//
//  File.swift
//  
//
//  Created by zhtut on 2023/7/23.
//

import Foundation
import LoggingKit
import NIOLockedValue

/// 订单管理器
public class OrderManager: @unchecked Sendable {
    
    public static let shared = OrderManager()
    
    @NIOLocked
    public var orders = [Order]()
    
    public func updateWith(_ report: ExecutionReport) {
        // 已经处理了后一条数据，这条是旧数据，直接抛弃
        if let or = orders.first(where: { $0.clientOrderId == report.c }) {
            if or.updateTime > report.E {
                return
            }
        }
        
        orders.removeAll(where: { $0.clientOrderId == report.c })
        if report.X == .NEW || report.X == .PARTIALLY_FILLED {
            orders.append(report.createOrder)
        }
        
        logInfo("当前订单数量：\(orders.count)")
    }
    
    /// 刷新全部订单
    public nonisolated func refresh() {
        Task { [self] in
            let path = "GET /api/v3/openOrders (HMAC SHA256)"
            let res = try await RestAPI.post(path: path, dataClass: [Order].self)
            if let arr = res.data as? [Order] {
                self.setOrders(arr)
                logInfo("当前订单数量：\(arr.count)")
            }
        }
    }
    
    func setOrders(_ orders: [Order]) {
        self.orders = orders
    }
}
