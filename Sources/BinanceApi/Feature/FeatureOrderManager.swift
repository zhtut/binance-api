//
//  File.swift
//  
//
//  Created by zhtut on 2023/7/23.
//

import Foundation
import CombineX
import LoggingKit
import CommonUtils
import NIOLockedValue

/// 订单管理器，管理所有订单状态
public class FeatureOrderManager: @unchecked Sendable {
    
    public static let shared = FeatureOrderManager()
    
    @NIOLocked
    public var orders = [FeatureOrder]()
    
    public var orderPublisher = PassthroughSubject<FeatureOrder, Never>()
    
    public func updateWith(_ report: FeatureTradeOrderUpdate) {
        // 已经处理了后一条数据，这条是旧数据，直接抛弃
        if let or = orders.first(where: { $0.clientOrderId == report.o.c }) {
            if or.updateTime ?? 0 > report.E {
                return
            }
        }
        
        orders.removeAll(where: { $0.clientOrderId == report.o.c })
        
        let changedOrder = report.createOrder
        
        if report.o.X == .NEW || report.o.X == .PARTIALLY_FILLED {
            orders.append(changedOrder)
        }
        
        logInfo("收到订单变化\(report.o.c): \(report.o.X), \(report.o.p)，当前订单数量：\(orders.count)")
        
        orderPublisher.send(changedOrder)
    }
    
    /// 刷新全部订单
    public func refresh() {
        logInfo("准备用接口刷新所有订单")
        Task {
            do {
                let orders = try await Self.getOpenOrders()
                logInfo("接口刷新订单成功：\(orders.count)个订单")
                self.setOrders(orders)
            } catch {
                print("刷新所有订单失败：\(error)")
            }
        }
    }
    
    func setOrders(_ orders: [FeatureOrder]) {
        self.orders = orders
    }
    
    public static func getOpenOrders(symbol: String? = nil) async throws -> [FeatureOrder] {
        let path = "GET /fapi/v1/openOrders (HMAC SHA256)"
        var params = [String: Any]()
        if let symbol {
            params["symbol"] = symbol
        }
        let res = try await RestAPI.post(path: path, dataClass: [FeatureOrder].self)
        if let arr = res.data as? [FeatureOrder] {
            return arr
        }
        throw CommonError(message: "没有订单")
    }
}
