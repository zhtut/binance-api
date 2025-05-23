//
//  File.swift
//  
//
//  Created by zhtut on 2023/7/23.
//

import Foundation

/// 订单管理器
open class OrderManager: NSObject, @unchecked Sendable {
    
    public static let shared = OrderManager()
    
    open var orders = [Order]()
    
    public override init() {
        super.init()
    }
    
    open func updateWith(_ report: ExecutionReport) {
        // 已经处理了后一条数据，这条是旧数据，直接抛弃
        if let or = orders.first(where: { $0.orderId == report.i }) {
            if or.updateTime > report.E {
                return
            }
        }
        
        orders.removeAll(where: { $0.orderId == report.i })
        if report.X == .NEW || report.X == .PARTIALLY_FILLED {
            orders.append(report.createOrder)
        }
        
        print("当前订单数量：\(orders.count)")
    }
    
    /// 刷新全部订单
    open func refresh() {
        let path = "GET /api/v3/openOrders (HMAC SHA256)"
        Task {
            let res = try await RestAPI.post(path: path, dataClass: [Order].self)
            if let arr = res.data as? [Order] {
                orders = arr
                print("当前订单数量：\(orders.count)")
            }
        }
    }
}
