import Foundation
import CommonUtils

public class Setup: @unchecked Sendable  {

    public static let shared = Setup()

    private init() {
    }
    
    public func loadAllSymbols() async throws {
        try await loadSymbols()
        try await fLoadSymbols()
    }

    public var symbols: [Symbol] = []

    public func loadSymbols() async throws {
        // https://api.binance.com/api/v1/exchangeInfo
        let path = "GET /api/v3/exchangeInfo"
        let response = try await RestAPI.send(path: path, dataKey: "symbols")
        if response.succeed {
            guard let dicArr = response.data as? [[String: Any]] else {
                throw CommonError(message: "exchangeInfo接口data字段返回格式有问题")
            }
            symbols = dicArr.map { Symbol(dic: $0) }
            print("symbol请求成功，总共请求到\(symbols.count)个symbol")
        } else if let msg = response.msg {
            throw CommonError(message: msg)
        }
    }

    public var fSymbols: [Symbol] = []

    public func fLoadSymbols() async throws {
        let path = "GET /fapi/v1/exchangeInfo"
        let response = try await RestAPI.send(path: path, dataKey: "symbols")
        if response.succeed {
            guard let dicArr = response.data as? [[String: Any]] else {
                throw CommonError(message: "exchangeInfo接口data字段返回格式有问题")
            }
            fSymbols = dicArr.map { Symbol(dic: $0) }
            print("symbol请求成功，总共请求到\(fSymbols.count)个symbol")
        } else if let msg = response.msg {
            throw CommonError(message: msg)
        }
    }
}
