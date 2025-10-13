//
//  FeaturePostOrderManager.swift
//  binance-api
//
//  Created by tutuzhou on 2024/11/19.
//

import Foundation
import CommonUtils
import LoggingKit

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
    public var lever: Int = 5
    
    public init(symbol: Symbol) {
        self.symbol = symbol
    }
    
    public var currentIndexPrice: Decimal?
    
    public func setCurrentPrice(_ currentPrice: Decimal?) async {
        currentIndexPrice = currentPrice
    }
    
    /// 冻结在订单中的合约张数
    public func orderPosSz() async -> Decimal {
        logInfo("获取orderPosSz")
        let orders = await FeatureOrderManager.shared.orders
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
    public func positionSz() async -> Decimal {
        logInfo("获取positionSz")
        let positions = await FeatureAccountManager.shared.positions
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
    public func canOpenSz() async ->  Decimal {
        logInfo("获取canOpenSz")
        let busd = await FeatureAccountManager.shared.usdcAvailable
        logInfo("busd：\(busd)")
        if let currPx = currentIndexPrice {
            let total = busd * lever.decimal / currPx
            return total
        }
        return 0
    }
    
    /// 最低可开多少数量
    public func baseSz() async -> Decimal {
        var minSz = symbol.minQty?.decimal ?? 0.0
        let lotSz = symbol.stepSize?.decimal ?? 0.0
        let currPx = currentIndexPrice ?? 0.0
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
        if response.succeed,
           let data = response.data as? [[String: Any]] {
            var result = [(Bool, String?)]()
            for (_, dic) in data.enumerated() {
                if dic.stringFor("code") != nil {
                    result.append((false, dic.stringFor("msg")))
                } else {
                    result.append((true, nil))
                }
            }
            return result
        } else {
            var result = [(Bool, String?)]()
            for _ in batchParams {
                result.append((false, response.msg))
            }
            return result
        }
    }
    
    @discardableResult
    public static func order(params: [String: Any]) async throws -> (succ: Bool, errMsg: String?) {
        let path = "POST /fapi/v1/order (HMAC SHA256)"
        if let side = params["side"],
           let sz = params["quantity"] {
            print("准备下单，side: \(side), 数量：\(sz)")
        }
        let response = try await RestAPI.send(path: path, params: params)
        return (response.succeed, response.msg)
    }
    
    /// 一键清仓
    public static func closePositions() async throws -> (succ: Bool, errMsg: String?) {
        let positions = await FeatureAccountManager.shared.positions
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
