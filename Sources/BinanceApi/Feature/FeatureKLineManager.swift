//
//  FeatureKLineManager.swift
//  binance-api
//
//  Created by tutuzhou on 2025/4/10.
//

import Foundation
import CommonUtils

open class FeatureKLineManager {
    /// 请求k线
    open class func queryKLine(symbol: String,
                         interval: KLineInteval,
                         startTime: Int? = nil,
                         endTime: Int? = nil,
                         timeZone: String? = nil,
                         limit: Int = 500) async throws -> [KLine] {
        let path = "GET /fapi/v1/klines"
        var params = [String : Any]()
        params["symbol"] = symbol
        params["interval"] = interval.rawValue
        params["startTime"] = startTime
        params["endTime"] = endTime
        params["timeZone"] = timeZone
        params["limit"] = limit
        let res = try await RestAPI.get(path: path, params: params)
        if let arr = res.data as? [[Any]] {
            return arr.map({ KLine(symbol: symbol, array: $0) })
        } else {
            throw CommonError(message: "没有请求到k线")
        }
    }
}
