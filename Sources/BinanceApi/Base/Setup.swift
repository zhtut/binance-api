import Foundation
import CommonUtils
import LoggingKit

public class Setup: @unchecked Sendable  {

    public static let shared = Setup()

    private init() {
    }
    
    public func loadAllSymbols(symbols: [String] = []) async throws {
        try await loadSymbols(symbols: symbols)
        try await fLoadSymbols()
    }

    public var symbols: [Symbol] = []

    public func loadSymbols(symbols: [String] = []) async throws {
        // https://api.binance.com/api/v1/exchangeInfo
        let path = "GET /api/v3/exchangeInfo"
        logInfo("准备开始加载现货的所有符号信息")
        let response = try await RestAPI.send(path: path, params: ["symbols": symbols], dataKey: "symbols")
        if response.succeed {
            guard let dicArr = response.data as? [[String: Any]] else {
                throw CommonError(message: "exchangeInfo接口data字段返回格式有问题")
            }
            self.symbols = dicArr.map { Symbol(dic: $0, symbolType: .spot) }
            logInfo("symbol请求成功，总共请求到\(self.symbols.count)个现货symbol")
        } else if let msg = response.msg {
            throw CommonError(message: msg)
        }
    }

    public var fSymbols: [Symbol] = []

    public func fLoadSymbols() async throws {
        let path = "GET /fapi/v1/exchangeInfo"
        logInfo("准备开始加载合约的所有符号信息")
        let response = try await RestAPI.send(path: path, dataKey: "symbols")
        if response.succeed {
            guard let dicArr = response.data as? [[String: Any]] else {
                throw CommonError(message: "exchangeInfo接口data字段返回格式有问题")
            }
            fSymbols = dicArr.map { Symbol(dic: $0, symbolType: .feature) }
            logInfo("symbol请求成功，总共请求到\(fSymbols.count)个合约symbol")
        } else if let msg = response.msg {
            throw CommonError(message: msg)
        }
    }
    
    public func spotSymbol(for key: String) throws -> Symbol {
        if let s = symbols.first(where: { $0.symbol == key }) {
            return s
        }
        throw CommonError(message: "没有找到symbol为\(key)的对象")
    }
    
    public func featureSymbol(for key: String) throws -> Symbol {
        if let s = fSymbols.first(where: { $0.symbol == key }) {
            return s
        }
        throw CommonError(message: "没有找到symbol为\(key)的对象")
    }
}
