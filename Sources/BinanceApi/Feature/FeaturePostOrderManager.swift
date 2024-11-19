//
//  FeaturePostOrderManager.swift
//  binance-api
//
//  Created by tutuzhou on 2024/11/19.
//

import Foundation
import UtilCore

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

open class FeaturePostOrderManager: CombineBase {
    
    open var symbol: Symbol
    
    /// 倍率
    open var lever: Int = 5
    
    public init(symbol: Symbol) {
        self.symbol = symbol
        super.init()
    }
    
    /// 冻结在订单中的合约张数
    open class var orderPosSz: Decimal {
        let orders = FeatureOrderManager.shared.orders
        if orders.count > 0 {
            var count = Decimal(0.0)
            for or in orders {
                if let pos = or.origQty.decimalValue {
                    count += pos
                }
            }
            return count
        }
        return 0
    }
    
    /// 持仓总张数
    open class var posSz: Decimal {
        let positions = FeatureAccountManager.shared.positions
        var count: Decimal = 0.0
        for po in positions {
            if let pos = po.positionAmt.decimalValue {
                count += pos
            }
        }
        return count
    }
    
    /*
     GTC - Good Till Cancel 成交为止
     IOC - Immediate or Cancel 无法立即成交(吃单)的部分就撤销
     FOK - Fill or Kill 无法全部立即成交就撤销
     GTX - Good Till Crossing 无法成为挂单方就撤销
     */
    open class func orderParamsWith(instId: String,
                                    isBuy: Bool,
                                    price: Decimal? = nil,
                                    sz: Decimal) -> [String: Any] {
        var params = [String: Any]()
        params["symbol"] = instId
        if isBuy {
            params["side"] = BUY
        } else {
            params["side"] = SELL
        }
        if let instrument = Setup.shared.fSymbols.first(where: { $0.symbol == instId }) {
            let sz = sz.precisionStringWith(precision: instrument.lotSz ?? "")
            params["quantity"] = sz
            if let price = price {
                params["price"] = price.precisionStringWith(precision: instrument.tickSz ?? "")
                params["type"] = "LIMIT"
                params["timeInForce"] = "GTX"
            } else {
                params["type"] = "MARKET"
            }
        }
        return params
    }
    
    open class func batchOrder(batchParams: [[String: Any]], maxCount: Int = 5) async throws -> [(Bool, String?)] {
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
    open class func order(params: [String: Any]) async throws -> (succ: Bool, errMsg: String?) {
        let path = "POST /fapi/v1/order (HMAC SHA256)"
        if let side = params["side"],
           let sz = params["quantity"] {
            print("准备下单，side: \(side), 数量：\(sz)")
        }
        let response = try await RestAPI.send(path: path, params: params)
        return (response.succeed, response.msg)
    }
    
    // 一键清仓
    open class func closePosition() async throws -> (succ: Bool, errMsg: String?) {
        let positions = FeatureAccountManager.shared.positions
        if positions.count > 0 {
            for position in positions {
                if let positionAmt = position.positionAmt.decimalValue {
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
    
    
    /// 取消所有订单
    /// - Returns: 取消的结果
    @discardableResult
    open class func cancelAllOrders(symbol: String) async throws -> (succ: Bool, errMsg: String?) {
        let path = "DELETE /fapi/v1/allOpenOrders (HMAC SHA256)"
        let params = ["symbol": symbol]
        let response = try await RestAPI.send(path: path, params: params)
        return (response.succeed, response.msg)
    }
    
//    /// 取消批量的订单，可以大于10个
//    func cancelOrders(_ orders: [FeatureOrder]) async throws {
//        if orders.count > 0 {
//            var remainOrders = orders
//            while remainOrders.count > 0 {
//                let tenOrders = Array(remainOrders.prefix(10))
//                let (succ, errMsg) = await FeatureOrder.cancel(orders: tenOrders)
//                if succ {
//                    print("取消\(tenOrders.count)个订单成功")
//                } else {
//                    log("取消\(tenOrders.count)个订单失败：\(errMsg ?? "")")
//                }
//                remainOrders = remainOrders.suffix(remainOrders.count - tenOrders.count)
//            }
//        }
//    }
//    
}
