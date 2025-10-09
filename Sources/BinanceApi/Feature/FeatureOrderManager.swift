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
import LoggingKit

/// 订单管理器
public actor FeatureOrderManager {
    
    public static let shared = FeatureOrderManager()
    
    public var orders = [FeatureOrder]()
    
    public var orderPublisher = PassthroughSubject<FeatureOrder, Never>()
    
    public func updateWith(_ report: FeatureTradeOrderUpdate) {
        // 已经处理了后一条数据，这条是旧数据，直接抛弃
        if let or = orders.first(where: { $0.orderId == report.o.i }) {
            if or.updateTime > report.E {
                return
            }
        }
        
        orders.removeAll(where: { $0.orderId == report.o.i })
        
        let changedOrder = report.createOrder
        
        if report.o.X == .NEW || report.o.X == .PARTIALLY_FILLED {
            orders.append(changedOrder)
        }
        
        logInfo("收到订单变化，当前订单数量：\(orders.count)")
        
        orderPublisher.send(changedOrder)
    }
    
    /// 刷新全部订单
    public func refresh() {
        Task {
            do {
                let path = "GET /fapi/v1/openOrders (HMAC SHA256)"
                let res = try await RestAPI.post(path: path, dataClass: [FeatureOrder].self)
                if let arr = res.data as? [FeatureOrder] {
                    orders = arr
                    print("当前订单数量：\(orders.count)")
                }
            } catch {
                print("请求订单信息失败：\(error)")
            }
        }
    }
    
    /// 取消全部订单
    public static func cancelAllOrders(symbol: String) async throws {
        let path = "DELETE /fapi/v1/allOpenOrders (HMAC SHA256)"
        let res = try await RestAPI.post(path: path, params: ["symbol": symbol])
        if res.succeed {
            logInfo("取消所有订单成功")
        } else {
            logInfo("取消所有订单失败：\(res.msg ?? "")")
        }
    }
}
