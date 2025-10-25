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
        logInfo("获取orderPosSz")
        let orders = FeatureOrderManager.shared.orders
        logInfo("orders: \(orders)")
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
        logInfo("获取positionSz")
        let positions = FeatureAccountManager.shared.positions
        logInfo("positions数量：\(positions.count)")
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
        logInfo("获取canOpenSz")
        let busd = FeatureAccountManager.shared.usdcAvailable
        logInfo("busd：\(busd)")
        if let currPx = currentPrice() {
            let total = busd * lever.decimal / currPx
            return total
        }
        return 0
    }
    
    /// 最多可开多少数量
    public func maxSz() -> Decimal {
        let busd = FeatureAccountManager.shared.usdcBal
        if let currPx = currentPrice() {
            let total = busd * lever.decimal / currPx
            return total
        }
        return 0
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
            FeatureOrder(symbol: $0.stringFor("symbol") ?? "",
                         clientOrderId: $0.stringFor("newClientOrderId") ?? "",
                         price: $0.stringFor("price") ?? "",
                         origQty: $0.stringFor("quantity") ?? "",
                         side: Side(rawValue: $0.stringFor("side") ?? "") ?? .BUY)
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
                if dic.stringFor("code") != nil {
                    result.append((false, dic.stringFor("msg")))
                    let cid = batchParams[index].stringFor("newClientOrderId") ?? ""
                    removeOrderIds.append(cid)
                } else {
                    result.append((true, nil))
                }
            }
        } else {
            for p in batchParams {
                result.append((false, response.msg))
                let cid = p.stringFor("newClientOrderId") ?? ""
                removeOrderIds.append(cid)
            }
        }
        
        // 移除失败的订单
        FeatureOrderManager.shared.orders.removeAll(where: { removeOrderIds.contains($0.clientOrderId) })
        
        return result
    }
    
    @discardableResult
    public static func order(params: [String: Any]) async throws -> (succ: Bool, errMsg: String?) {
        let path = "POST /fapi/v1/order (HMAC SHA256)"
        if let side = params["side"],
           let sz = params["quantity"] {
            print("准备下单，side: \(side), 数量：\(sz)")
        }
        // 未下单先添加
        let order =
        FeatureOrder(symbol: params.stringFor("symbol") ?? "",
                     clientOrderId: params.stringFor("newClientOrderId") ?? "",
                     price: params.stringFor("price") ?? "",
                     origQty: params.stringFor("quantity") ?? "",
                     side: Side(rawValue: params.stringFor("side") ?? "") ?? .BUY)
        FeatureOrderManager.shared.orders.append(order)
        let response = try await RestAPI.send(path: path, params: params)
        if !response.succeed {
            // 失败时移除
            FeatureOrderManager.shared.orders.removeAll(where: { $0.clientOrderId == params.stringFor("newClientOrderId") })
        }
        return (response.succeed, response.msg)
    }
    
    /// 一键清仓
    public static func closePositions() async throws -> (succ: Bool, errMsg: String?) {
        let positions = FeatureAccountManager.shared.positions
        if positions.count > 0 {
            for position in positions {
                if let positionAmt = position.positionAmt.decimal {
                    let isBuy = position.isBuy
                    let symbol = position.symbol
                    let sz = dabs(positionAmt)
                    let closeParams = orderParamsWith(instId: symbol,
                                                      isBuy: !isBuy,
                                                      sz: sz)
                    return try await order(params: closeParams)
                }
            }
        }
        return (false, "没有持仓，不需要清仓")
    }
    
    /// 平掉所有持仓
    public static func closeAllPositions() async throws {
        let path = "GET /fapi/v3/account (HMAC SHA256)"
        let res = try await RestAPI.post(path: path, dataClass: FeatureAccount.self)
        if let acc = res.data as? FeatureAccount {
            let positions = acc.positions ?? []
            if positions.count > 0 {
                for position in positions {
                    if let positionAmt = position.positionAmt.decimal {
                        let isBuy = position.isBuy
                        let symbol = position.symbol
                        let sz = dabs(positionAmt)
                        let closeParams = orderParamsWith(instId: symbol,
                                                          isBuy: !isBuy,
                                                          sz: sz)
                        try await order(params: closeParams)
                    }
                }
            }
        }
    }
}
