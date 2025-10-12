//
//  File.swift
//  
//
//  Created by zhtut on 2023/7/23.
//

import Foundation
import CombineWebSocket
import CommonUtils
#if canImport(CombineX)
import CombineX
#else
import Combine
#endif

/// 现货账户和订单的websocket
public actor SpotAccountWebSocket {
    
    /// 设计成单例，一直存在
    public static let shared = SpotAccountWebSocket()
    
    /// websocket连接
    public var ws = WebSocket()
    
    public nonisolated(unsafe) var subscriptions = Set<AnyCancellable>()
        
    public init() {
        
        // 监听事件
        ws.onDataPublisher
            .sink { [weak self] data in
                self?.processData(data)
            }
            .store(in: &subscriptions)
        Task.detached { [self] in
            // 开始连接
            await self.open()
            
            // 先请求到订单和账户数据
            BalanceManager.shared.refresh()
            OrderManager.shared.refresh()
        }
    }
    
    /// 处理数据
    /// - Parameter data: 收到的数据
    public nonisolated func processData(_ data: Data) {
        Task.detached { [self] in
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let e = json.stringFor("e") {
                        switch e {
                        case OutboundAccountPosition.key:
                            let position = try JSONDecoder().decode(OutboundAccountPosition.self, from: data)
                            await didReceiveAccountUpdate(position)
                        case BalanceUpdate.key:
                            let update = try JSONDecoder().decode(BalanceUpdate.self, from: data)
                            await didReceiveBalanceUpdate(update)
                        case ExecutionReport.key:
                            let report = try JSONDecoder().decode(ExecutionReport.self, from: data)
                            await didReceiveOrderUpdate(report)
                        default:
                            print("")
                        }
                    }
                }
            } catch {
                print("处理数据错误：\(error)")
            }
        }
    }
    
    /// Payload: 账户更新
    /// 每当帐户余额发生更改时，都会发送一个事件outboundAccountPosition，其中包含可能由生成余额变动的事件而变动的资产。
    public func didReceiveAccountUpdate(_ position: OutboundAccountPosition) async {
        await BalanceManager.shared.updateWith(position)
    }
    
    /// Payload: 余额更新
    /// 当下列情形发生时更新:
    /// - 账户发生充值或提取
    /// - 交易账户之间发生划转(例如 现货向杠杆账户划转)
    public func didReceiveBalanceUpdate(_ update: BalanceUpdate) async {
        await BalanceManager.shared.updateWith(update)
    }
    
    /// Payload: 订单更新
    /// 订单通过executionReport事件进行更新。
    public func didReceiveOrderUpdate(_ report: ExecutionReport) async {
        await OrderManager.shared.updateWith(report)
    }
    
    public func open() {
        Task.detached { [self] in
            await isolatedOpen()
        }
    }
    
    func isolatedOpen() async {
        do {
            let key = try await createListenKey()
            let baseURL = APIConfig.shared.spot.wsBaseURL
            let url = "\(baseURL)/\(key)"
            ws.url = URL(string: url)
            ws.open()
        } catch {
            print("连接失败：\(error)，尝试重连")
            open()
        }
    }
    
    public func createListenKey() async throws -> String {
        let path = "POST /api/v3/userDataStream"
        let res = try await RestAPI.post(path: path)
        if let json = await res.res.bodyJson(),
           let dict = json as? [String: Any],
           let listenKey = dict.stringFor("listenKey") {
            return listenKey
        }
        throw CommonError(message: "解析body错误")
    }
}
