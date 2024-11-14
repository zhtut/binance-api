//
//  File.swift
//
//
//  Created by zhtut on 2023/7/23.
//

import Foundation
import CombineWebSocket
import UtilCore
#if canImport(CombineX)
import CombineX
#else
import Combine
#endif

/// 现货账户和订单的websocket
open class FeatureAccountWebSocket: CombineBase, @unchecked Sendable {
    
    /// 设计成单例，一直存在
    public static let shared = FeatureAccountWebSocket()
    
    /// websocket连接
    public var ws = WebSocket()
    
    public override init() {
        super.init()
        
        ws.isPrintLog = true
        
        // 监听事件
        ws.onDataPublisher
            .sink { [weak self] data in
                self?.processData(data)
            }
            .store(in: &subscriptions)
        
        // 开始连接
        open()
        
        // 先请求到订单和账户数据
        BalanceManager.shared.refresh()
        OrderManager.shared.refresh()
    }
    
    /// 处理数据
    /// - Parameter data: 收到的数据
    open func processData(_ data: Data) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let e = json.stringFor("e") {
                    switch e {
                    case FeatureAccountUpdate.key:
                        let update = try JSONDecoder().decode(FeatureAccountUpdate.self, from: data)
                        didReceiveAccountUpdate(update)
                    case "listenKeyExpired":
                        reOpen()
                    default:
                        print("")
                    }
                }
            }
        } catch {
            print("处理数据错误：\(error)")
        }
    }
    
    /// Payload: 账户更新
    /// 每当帐户余额发生更改时，都会发送一个事件outboundAccountPosition，其中包含可能由生成余额变动的事件而变动的资产。
    open func didReceiveAccountUpdate(_ update: FeatureAccountUpdate) {
        FeatureBalanceManager.shared.updateWith(update)
    }
    
    /// Payload: 订单更新
    /// 订单通过executionReport事件进行更新。
    open func didReceiveOrderUpdate(_ report: ExecutionReport) {
        OrderManager.shared.updateWith(report)
    }
    
    open func reOpen() {
        Task {
            try await ws.close()
            open()
        }
    }
    
    open func open() {
        Task {
            do {
                let key = try await createListenKey()
                let baseURL = APIConfig.shared.feature.wsBaseURL
                let url = "\(baseURL)/\(key)"
                ws.url = URL(string: url)
                ws.open()
            } catch {
                print("连接失败：\(error)，尝试重连")
                open()
            }
        }
    }
    
    open func createListenKey() async throws -> String {
        let path = "POST /fapi/v1/listenKey"
        let res = try await RestAPI.post(path: path)
        if let json = await res.res.bodyJson(),
           let dict = json as? [String: Any],
           let listenKey = dict.stringFor("listenKey") {
            return listenKey
        }
        throw CommonError(message: "解析body错误")
    }
}
