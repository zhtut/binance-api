//
//  FeatureLeverage.swift
//  binance-api
//
//  合约杠杆 / 保证金模式设置
//

import Foundation
import LoggingKit

/// 保证金模式
public enum MarginType: String, Sendable {
    /// 全仓
    case crossed = "CROSSED"
    /// 逐仓
    case isolated = "ISOLATED"
}

public struct FeatureLeverage {

    /// 调整开仓杠杆
    /// https://developers.binance.com/docs/zh-CN/derivatives/usds-margined-futures/trade/rest-api/Change-Initial-Leverage
    @discardableResult
    public static func setLeverage(symbol: String, leverage: Int) async throws -> Bool {
        let path = "POST /fapi/v1/leverage (HMAC SHA256)"
        let params: [String: Any] = ["symbol": symbol, "leverage": leverage]
        let response = try await RestAPI.send(path: path, params: params)
        if response.succeed {
            logInfo("设置\(symbol)杠杆为\(leverage)x成功")
            return true
        }
        logError("设置\(symbol)杠杆失败：\(response.msg ?? "")")
        return false
    }

    /// 变换逐仓/全仓模式
    /// 若已是目标模式，币安返回 code -4046（无需更改），此处视为成功。
    @discardableResult
    public static func setMarginType(symbol: String, marginType: MarginType) async throws -> Bool {
        let path = "POST /fapi/v1/marginType (HMAC SHA256)"
        let params: [String: Any] = ["symbol": symbol, "marginType": marginType.rawValue]
        let response = try await RestAPI.send(path: path, params: params)
        if response.succeed {
            logInfo("设置\(symbol)保证金模式为\(marginType.rawValue)成功")
            return true
        }
        // -4046: No need to change margin type.
        if response.code == -4046 {
            logInfo("\(symbol)已是\(marginType.rawValue)模式，无需更改")
            return true
        }
        logError("设置\(symbol)保证金模式失败：\(response.msg ?? "")")
        return false
    }
}
