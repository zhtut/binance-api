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
        let response = try await RestAPI.send(path: path, dataKey: "symbols", dataClass: [Symbol].self)
        if response.succeed, let ss = response.res.model as? [Symbol] {
            symbols = ss
            print("symbol请求成功，总共请求到\(symbols.count)个现货symbol")
        } else if let msg = response.msg {
            throw CommonError(message: msg)
        }
    }

    public var fSymbols: [Symbol] = []

    public func fLoadSymbols() async throws {
        let path = "GET /fapi/v1/exchangeInfo"
        let response = try await RestAPI.send(path: path, dataKey: "symbols", dataClass: [Symbol].self)
        if response.succeed, let ss = response.res.model as? [Symbol] {
            fSymbols = ss
            print("symbol请求成功，总共请求到\(fSymbols.count)个合约symbol")
        } else if let msg = response.msg {
            throw CommonError(message: msg)
        }
    }
    
    public func featureSymbol(for key: String) throws -> Symbol {
        if let s = fSymbols.first(where: { $0.symbol == key }) {
            return s
        }
        throw CommonError(message: "没有找到symbol为\(key)的对象")
    }
}
