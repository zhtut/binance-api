//
//  FeatureOrderBook.swift
//  binance-api
//
//  Created by tutuzhou on 2025/9/23.
//

import Foundation
import LoggingKit
#if canImport(CombineX)
import CombineX
#else
import Combine
#endif

/// 盘口价格
public struct OrderBookPrice : Sendable{
    /// 价格
    public var p: Decimal = 0
    /// 数量
    public var v: Decimal = 0
    
    public init(array: [String]) {
        if let p = Decimal(string: array[0]) {
            self.p = p
        }
        if let v = Decimal(string: array[1]) {
            self.v = v
        }
    }
}

public extension Symbol {
    var kLinePath: String {
        switch type {
        case .spot:
            return "GET /api/v3/depth"
        case .feature:
            return "GET /fapi/v1/depth"
        }
    }
}

/// 盘口价格本 - 使用actor避免资源竞争
public actor OrderBook {
    
    public let symbol: Symbol
    
    public var bids = [OrderBookPrice]()
    public var asks = [OrderBookPrice]()
    
    public var lastUpdateId: Int = 0
    
    public var isRefreshing = false
    
    /// 是否数据正常
    @Published
    public private(set) var isReady: Bool = false
    
    /// 中间价
    public var centerPrice: Double? {
        guard let bid = bids.first?.p.double,
              let ask = asks.first?.p.double else {
            return nil
        }
        let center = (bid + ask) / 2.0
        return center
    }
    
    public init(symbol: Symbol) {
        self.symbol = symbol
    }
    
    /// 刷新订单簿
    public func refreshOrderBook() throws {
        Task {
            isRefreshing = true
            defer { isRefreshing = false }
            let path = symbol.kLinePath
            let params = ["symbol": symbol.symbol, "limit": 20] as [String: Any]
            let response = try await RestAPI.post(path: path, params: params)
            
            if let message = response.data as? [String: Any] {
                if let a = message["asks"] as? [[String]],
                   let b = message["bids"] as? [[String]] {
                    let lastUpdateId = message.intFor("lastUpdateId") ?? 0
                    updateOrderBookData(a: a, b: b, lastUpdateId: lastUpdateId, cover: true)
                }
            }
        }
    }
    
    /// 更新订单簿消息
    public func update(message: [String: Any]) async throws -> Bool {
        if isRefreshing {
            return false
        }
        
        if lastUpdateId == 0 {
            if isReady != false {
                isReady = false
            }
            logWarning("lastUpdateId为零，需要完整重刷orderBook")
            try refreshOrderBook()
            return false
        }
        
        guard let U = message.intFor("U"),
              let u = message.intFor("u") else {
            return false
        }
        
        /// 当前的u是否失效
        var uInvalid = false
        if symbol.type == .feature {
            let pu = message.intFor("pu") ?? 0
            // pu是上一个的u，如果不等，则缺失了
            uInvalid = (pu != lastUpdateId)
        } else {
            // 现货使用当前的U跟上一个的u是否相差1，没有返回pu，只能这样判断
            // U是上一个u+1
            uInvalid = (U != lastUpdateId + 1)
        }
        
        if uInvalid {
            if isReady != false {
                isReady = false
            }
            logWarning("ID不匹配，需要完整重刷orderBook")
            try refreshOrderBook()
            return false
        }
        
        
        // 更新操作
        if let a = message["a"] as? [[String]],
           let b = message["b"] as? [[String]] {
            updateOrderBookData(a: a, b: b, lastUpdateId: u)
        }
        
        if isReady != true {
            isReady = true
        }
        
        return true
    }
    
    /// 记录订单簿（非隔离方法）
    public func logOrderBook() {
        let currentBids = bids
        let currentAsks = asks
        print("OrderBook: =======")
        logPriceArray(arr: currentAsks, count: 5, reversed: true)
        print("------")
        logPriceArray(arr: currentBids, count: 5, reversed: false)
    }
    
    // MARK: - Private Methods
    
    private func updateOrderBookData(a: [[String]], b: [[String]], lastUpdateId: Int, cover: Bool = false) {
        updateAsks(a: a, cover: cover)
        updateBids(b: b, cover: cover)
        self.lastUpdateId = lastUpdateId
//        logOrderBook()
    }
    
    private func updateAsks(a: [[String]], cover: Bool = false) {
        // 转化为对象
        let priceObjs = a.compactMap({ OrderBookPrice(array: $0) })
        if cover {
            asks = priceObjs
        } else {
            // 删除其中存在的价格
            asks.removeAll(where: { priceObjs.map { $0.p }.contains($0.p) })
            // 添加数量大于0的价格
            asks += priceObjs.filter({ $0.v > 0 })
        }
        asks.sort(by: { $0.p < $1.p })
    }
    
    private func updateBids(b: [[String]], cover: Bool = false) {
        // 转化为对象
        let priceObjs = b.compactMap({ OrderBookPrice(array: $0) })
        if cover {
            bids = priceObjs
        } else {
            // 删除其中存在的价格
            bids.removeAll(where: { priceObjs.map { $0.p }.contains($0.p) })
            // 添加数量大于0的价格
            bids += priceObjs.filter({ $0.v > 0 })
        }
        bids.sort(by: { $0.p > $1.p })
    }
    
    // MARK: - Nonisolated Helpers
    
    private func logPriceArray(arr: [OrderBookPrice], count: Int, reversed: Bool) {
        let prefixIndexes = Array(0..<min(count, arr.count))
        let indices = reversed ? prefixIndexes.reversed() : prefixIndexes
        
        for index in indices {
            let price = arr[index]
            print("\(price.p) \(price.v)")
        }
    }
}
