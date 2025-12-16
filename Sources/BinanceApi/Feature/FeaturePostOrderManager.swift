//
//  FeaturePostOrderManager.swift
//  binance-api
//
//  Created by tutuzhou on 2024/11/19.
//

import Foundation
import CommonUtils
import LoggingKit
import NIOLockedValue

public let BUY = "BUY"
public let SELL = "SELL"
//public let LONG = "LONG"
//public let SHORT = "SHORT"

public let NEW = "NEW"
public let PARTIALLY_FILLED = "PARTIALLY_FILLED"
public let FILLED = "FILLED"
public let CANCELED = "CANCELED"
public let EXPIRED = "EXPIRED"
public let NEW_INSURANCE = "NEW_INSURANCE" //  风险保障基金(强平)
public let NEW_ADL = "NEW_ADL" // 自动减仓序列(强平)

public class FeaturePostOrderManager: @unchecked Sendable {
    
    public var symbol: Symbol
    
    /// 倍率
    public var lever: Int = 10
    
    public var getCurrentPrice: (() -> Decimal?)?
    
    public init(symbol: Symbol, getCurrentPrice: (() -> Decimal?)? = nil) {
        self.symbol = symbol
        self.getCurrentPrice = getCurrentPrice
    }
    
    @NIOLocked
    public var currentIndexPrice: Decimal?
    
    public func setCurrentPrice(_ currentPrice: Decimal?) {
        currentIndexPrice = currentPrice
    }
    
    func currentPrice() -> Decimal? {
        if let getCurrentPrice {
            return getCurrentPrice()
        }
        return currentIndexPrice
    }
    
    /// 冻结在订单中的合约张数
    public func orderPosSz() -> Decimal {
        let orders = FeatureOrderManager.shared.orders
        let filters = orders.filter({ $0.symbol == symbol.symbol })
        if filters.count > 0 {
            var count = Decimal(0.0)
            for or in filters {
                if let pos = or.origQty.decimal {
                    count += pos
                }
            }
            return count
        }
        return 0
    }
    
    /// 持仓总数量，买入大于0，卖出小于0
    public func positionSz() -> Decimal {
        let positions = FeatureAccountManager.shared.positions
        let filters = positions.filter({ $0.symbol == symbol.symbol })
        var count: Decimal = 0.0
        for po in filters {
            if let pos = po.positionAmt.decimal {
                count += pos
            }
        }
        return count
    }
    
    /// 可开张数
    public func canOpenSz() ->  Decimal {
        let busd = FeatureAccountManager.shared.usdcAvailable
        if let currPx = currentPrice() {
            let total = busd * lever.decimal / currPx
            return total
        }
        return 0
    }
    
    /// 可开张数
    public func canBuySz() ->  Decimal {
        let busd = FeatureAccountManager.shared.usdcAvailable
        if let currPx = currentPrice() {
            let total = busd * lever.decimal / currPx
            let pos = positionSz()
            if pos < 0 {
                return total - 2 * positionSz() // 有卖出时，要乘以2的持仓方向
            } else {
                return total
            }
        }
        return 0
    }
    
    /// 可开张数
    public func canSellSz() ->  Decimal {
        let busd = FeatureAccountManager.shared.usdcAvailable
        if let currPx = currentPrice() {
            let total = busd * lever.decimal / currPx
            let pos = positionSz()
            if pos > 0 {
                return total + 2 * positionSz()
            } else {
                return total
            }
        }
        return 0
    }
    
    /// 最多可开多少数量
    public func maxSz() -> Decimal {
        return canOpenSz() + dabs(positionSz())
    }
    
    /// 最低可开多少数量
    public func baseSz() -> Decimal {
        var minSz = symbol.minQty?.decimal ?? 0.0
        let lotSz = symbol.stepSize?.decimal ?? 0.0
        let currPx = currentPrice() ?? 0.0
        while minSz * currPx < 20 { // 最低20美元
            minSz += lotSz
        }
        return minSz
    }
    
    public static func createClientOrderId() -> String {
        let uuidString = UUID().uuidString.split("-").first ?? ""
        return "\(Date.timestamp)_\(uuidString)"
    }
    
    /*
     GTC - Good Till Cancel 成交为止
     IOC - Immediate or Cancel 无法立即成交(吃单)的部分就撤销
     FOK - Fill or Kill 无法全部立即成交就撤销
     GTX - Good Till Crossing 无法成为挂单方就撤销
     */
    public static func orderParamsWith(instId: String,
                                       isBuy: Bool,
                                       price: Decimal? = nil,
                                       sz: Decimal,
                                       newClientOrderId: String? = nil) -> [String: Any] {
        var params = [String: Any]()
        params["symbol"] = instId
        if isBuy {
            params["side"] = BUY
        } else {
            params["side"] = SELL
        }
        if let instrument = Setup.shared.fSymbols.first(where: { $0.symbol == instId }) {
            let sz = sz.precisionStringWith(precision: instrument.stepSize ?? "")
            params["quantity"] = sz
            if let price = price {
                params["price"] = price.precisionStringWith(precision: instrument.tickSize ?? "")
                params["type"] = "LIMIT"
                params["timeInForce"] = "GTX"
            } else {
                params["type"] = "MARKET"
            }
        }
        let cid = newClientOrderId ?? createClientOrderId()
        params["newClientOrderId"] = cid
        return params
    }
    
    public static func batchOrder(batchParams: [[String: Any]], maxCount: Int = 5) async throws -> [(Bool, String?)] {
        
        let orders = batchParams.compactMap({
            FeatureOrder(symbol: $0.string(for: "symbol") ?? "",
                         clientOrderId: $0.string(for: "newClientOrderId") ?? "",
                         price: $0.string(for: "price") ?? "",
                         origQty: $0.string(for: "quantity") ?? "",
                         side: Side(rawValue: $0.string(for: "side") ?? "") ?? .BUY)
        })
        FeatureOrderManager.shared.orders += orders
        
        if batchParams.count == 0 {
            return [(Bool, String?)]()
        }
        let originParams = batchParams
        if batchParams.count > maxCount {
            var batchParams1 = batchParams
            var completions = [(Bool, String?)]()
            while batchParams1.count > 0 {
                let top = Array(batchParams1.prefix(maxCount))
                let result = try await batchOrder(batchParams: top)
                completions += result
                if completions.count == originParams.count {
                    return completions
                }
                batchParams1 = batchParams1.suffix(batchParams1.count - top.count)
            }
            return [(Bool, String?)]()
        }
        
        let path = "POST /fapi/v1/batchOrders (HMAC SHA256)"
        let params = ["batchOrders": batchParams]
        let response = try await RestAPI.send(path: path, params: params)
        
        var removeOrderIds = [String]()
        
        var result = [(Bool, String?)]()
        if response.succeed,
           let data = response.data as? [[String: Any]] {
            for (index, dic) in data.enumerated() {
                if dic.string(for: "code") != nil {
                    result.append((false, dic.string(for: "msg")))
                    let cid = batchParams[index].string(for: "newClientOrderId") ?? ""
                    removeOrderIds.append(cid)
                } else {
                    result.append((true, nil))
                }
            }
        } else {
            for p in batchParams {
                result.append((false, response.msg))
                let cid = p.string(for: "newClientOrderId") ?? ""
                removeOrderIds.append(cid)
            }
        }
        
        // 移除失败的订单
        FeatureOrderManager.shared.orders.removeAll(where: { removeOrderIds.contains($0.clientOrderId) })
        
        return result
    }
    
    @discardableResult
    public static func postOrder(params: [String: Any],
                                 path: String = "POST /fapi/v1/order (HMAC SHA256)") async throws -> (
        succ: Bool,
        errMsg: String?
    ) {
        if let side = params["side"],
           let sz = params["quantity"] {
            logInfo("准备下单，side: \(side), 数量：\(sz)")
        }
        // 未下单先添加
        let order =
        FeatureOrder(symbol: params.string(for: "symbol") ?? "",
                     clientOrderId: params.string(for: "newClientOrderId") ?? "",
                     price: params.string(for: "price") ?? "",
                     origQty: params.string(for: "quantity") ?? "",
                     side: Side(rawValue: params.string(for: "side") ?? "") ?? .BUY)
        FeatureOrderManager.shared.orders.append(order)
        let response = try await RestAPI.send(path: path, params: params)
        if !response.succeed {
            // 失败时移除
            FeatureOrderManager.shared.orders.removeAll(where: { $0.clientOrderId == params.string(for: "newClientOrderId") })
        }
        return (response.succeed, response.msg)
    }
    
    /// 一键清仓
    public static func closeAllPositions() async throws -> (succ: Bool, errMsg: String?) {
        let positions = FeatureAccountManager.shared.positions
        if positions.count > 0 {
            for position in positions {
                try await position.closePositionNow()
            }
            return (true, "清仓完成：\(positions.count)")
        } else {
            return (true, "没有持仓，不需要清仓")
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
    
    /// 查询历史成交订单
    public static func queryHistoryOrders(symbol: String, orderId: String? = nil, limit: Int = 20) async throws -> [FeatureOrder] {
        let path = "/fapi/v1/allOrders (HMAC SHA256)"
        let res = try await RestAPI.post(path: path, params: ["symbol": symbol])
        if res.succeed, let models = res.data as? [FeatureOrder] {
            logInfo("取消所有订单成功")
            return models
        } else {
            logInfo("取消所有订单失败：\(res.msg ?? "")")
            throw CommonError(message: res.msg ?? "")
        }
    }
    
    /// 取消订单，少于10个
    private static func batchCancel(orders: [FeatureOrder], symbol: String) async throws -> [(Bool, String?)]  {
        if orders.count == 0 {
            return []
        }
        
        let path = "DELETE /fapi/v1/batchOrders (HMAC SHA256)"
        let selfOrders = FeatureOrderManager.shared.orders
        let orderIdList = orders.compactMap({ $0.clientOrderId })
            .filter({ selfOrders.compactMap({ $0.clientOrderId }).contains($0) }) // 过滤掉不包含的订单
        if orderIdList.isEmpty {
            logInfo("没有订单需要取消，退出")
            return []
        }
        // 删除准备取消的订单
        FeatureOrderManager.shared.orders.removeAll(where: { orderIdList.contains($0.clientOrderId) })
        let params = ["symbol": symbol, "origClientOrderIdList": orderIdList] as [String : Any]
        let response = try await RestAPI.send(path: path, params: params)
        var result = [(Bool, String?)]()
        if response.succeed,
           let data = response.data as? [[String: Any]] {
            for (index, dic) in data.enumerated() {
                if dic.string(for: "code") != nil {
                    let msg = dic.string(for: "msg")
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
