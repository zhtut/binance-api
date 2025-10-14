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
import CommonUtils
import NIOLockedValue

/// 订单管理器
public class FeatureOrderManager: @unchecked Sendable {
    
    public static let shared = FeatureOrderManager()
    
    @NIOLocked
    public var orders = [FeatureOrder]()
    
    public var orderPublisher = PassthroughSubject<FeatureOrder, Never>()
    
    public func updateWith(_ report: FeatureTradeOrderUpdate) {
        // 已经处理了后一条数据，这条是旧数据，直接抛弃
        if let or = orders.first(where: { $0.clientOrderId == report.o.c }) {
            if or.updateTime > report.E {
                return
            }
        }
        
        orders.removeAll(where: { $0.clientOrderId == report.o.c })
        
        let changedOrder = report.createOrder
        
        if report.o.X == .NEW || report.o.X == .PARTIALLY_FILLED {
            orders.append(changedOrder)
        }
        
        logInfo("收到订单变化\(report.o.c): \(report.o.X)，当前订单数量：\(orders.count)")
        
        orderPublisher.send(changedOrder)
    }
    
    /// 刷新全部订单
    public func refresh() {
        Task {
            do {
                let orders = try await Self.getOpenOrders()
                logInfo("接口刷新订单成功：\(orders.count)个订单")
                self.setOrders(orders)
            } catch {
                print("请求订单信息失败：\(error)")
            }
        }
    }
    
    func setOrders(_ orders: [FeatureOrder]) {
        self.orders = orders
    }
    
    public static func getOpenOrders() async throws -> [FeatureOrder] {
        let path = "GET /fapi/v1/openOrders (HMAC SHA256)"
        let res = try await RestAPI.post(path: path, dataClass: [FeatureOrder].self)
        if let arr = res.data as? [FeatureOrder] {
            return arr
        }
        throw CommonError(message: "没有订单")
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
    
    /// 取消订单，少于10个
    private static func batchCancel(orders: [FeatureOrder], symbol: String) async throws -> [(Bool, String?)]  {
        if orders.count == 0 {
            return []
        }
        
        let path = "DELETE /fapi/v1/batchOrders (HMAC SHA256)"
        let selfOrders = shared.orders
        let orderIdList = orders.compactMap({ $0.clientOrderId })
            .filter({ selfOrders.compactMap({ $0.clientOrderId }).contains($0) }) // 过滤掉不包含的订单
        if orderIdList.isEmpty {
            logInfo("没有订单需要取消，退出")
            return []
        }
        let params = ["symbol": symbol, "origClientOrderIdList": orderIdList] as [String : Any]
        let response = try await RestAPI.send(path: path, params: params)
        var result = [(Bool, String?)]()
        if response.succeed,
           let data = response.data as? [[String: Any]] {
            for (index, dic) in data.enumerated() {
                if dic.stringFor("code") != nil {
                    let msg = dic.stringFor("msg")
                    result.append((false, msg))
                    let clientId = orderIdList[index]
                    logInfo("\(clientId)订单取消失败：\(msg ?? "")")
                } else {
                    result.append((true, nil))
                }
            }
        } else {
            for _ in orders {
                result.append((false, response.msg))
            }
            logInfo("取消订单失败：参数：\(params)")
        }
        return result
    }
    
    /// 取消订单，可以多于10个
    public static func cancel(orders: [FeatureOrder], batchCount: Int = 10) async throws {
        var orderInfo = [String: [FeatureOrder]]()
        for order in orders {
            var orderArr: [FeatureOrder]
            if let arr = orderInfo[order.symbol] {
                orderArr = arr
            } else {
                orderArr = [FeatureOrder]()
            }
            orderArr.append(order)
            orderInfo[order.symbol] = orderArr
        }
        for (symbol, orders) in orderInfo {
            try await cancel(orders: orders, symbol: symbol, batchCount: batchCount)
        }
    }
    
    /// 取消订单，可以多于10个
    public static func cancel(orders: [FeatureOrder], symbol: String, batchCount: Int = 10) async throws {
        var remainingOrders = orders
        while remainingOrders.count > 0 {
            let topOrders: [FeatureOrder]
            if remainingOrders.count > batchCount {
                topOrders = Array(remainingOrders.prefix(batchCount))
                remainingOrders = remainingOrders.suffix(remainingOrders.count - topOrders.count)
            } else {
                // 少于或等于10个了，一次取消
                topOrders = remainingOrders
                remainingOrders = []
            }
            
            let result = try await batchCancel(orders: topOrders, symbol: symbol)
            
            var succ = 0
            var errMsg = ""
            for (_, handler) in result.enumerated() {
                if handler.0 {
                    succ += 1
                } else {
                    errMsg = "\(errMsg)\(handler.1 ?? "")"
                }
            }
            if succ == orders.count {
                logInfo("\(succ)个订单都取消成功")
            } else {
                logInfo("\(succ)个订单取消成功， \(orders.count - succ)个订单取消失败, \(errMsg)")
            }
        }
    }
}
