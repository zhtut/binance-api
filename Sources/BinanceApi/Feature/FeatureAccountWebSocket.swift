//
//  File.swift
//
//
//  Created by zhtut on 2023/7/23.
//

import Foundation
import CombineWebSocket
import CommonUtils
import CombineX
import LoggingKit

/// 现货账户和订单的websocket
public class FeatureAccountWebSocket: @unchecked Sendable {
    
    /// 设计成单例，一直存在
    public static let shared = FeatureAccountWebSocket()
    
    /// websocket连接
    public var ws = WebSocket()
    
    public var subscriptions = Set<AnyCancellable>()
    
    var checkTimer: Timer?
    
    public init() {
        
        logInfo("开始初始化账户WebSocket")
        
        addObserver()
        
        logInfo("开始连接账户WebSocket")
        
        // 开始连接
        open()
        
        logInfo("先请求到订单和账户数据")
        // 先请求到订单和账户数据
        refresh()
        
        // 启动定时器
        startTimer()
    }
    
    func addObserver() {
        
        // 监听事件
        ws.onDataPublisher
            .sink { [weak self] data in
                self?.processData(data)
            }
            .store(in: &subscriptions)
        
        // 监听事件
        ws.onOpenPublisher
            .sink {
                logInfo("账户WS连接成功")
            }
            .store(in: &subscriptions)
    }
    
    func startTimer() {
        // 再起个定时器，定时拉取最新的订单和资产
        let timer = Timer(timeInterval: 10, repeats: true) { [weak self] timer in
            guard let self else { return }
            self.refresh()
        }
        checkTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }
    
    nonisolated func refresh() {
        Task {
            FeatureOrderManager.shared.refresh()
            FeatureAccountManager.shared.refresh()
        }
    }
    
    /// 处理数据
    /// - Parameter data: 收到的数据
    public nonisolated func processData(_ data: Data) {
        Task { [self] in
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let e = json.stringFor("e") {
//                    logInfo("收到账户消息更新：\(json)")
                    switch e {
                    case FeatureAccountUpdate.key:
                        let update = try JSONDecoder().decode(FeatureAccountUpdate.self, from: data)
                        didReceiveAccountUpdate(update)
                    case FeatureTradeOrderUpdate.key:
                        let update = try JSONDecoder().decode(FeatureTradeOrderUpdate.self, from: data)
                        didReceiveOrderUpdate(update)
                    case "listenKeyExpired":
                        reopen()
                    default:
                        logInfo("账户ws收到其他e类型的json：\(json)")
                    }
                } else {
                    logInfo("账户ws收到其他json：\(json)")
                }
            }
        }
    }
    
    /// Payload: 账户更新
    /// 每当帐户余额发生更改时，都会发送一个事件outboundAccountPosition，其中包含可能由生成余额变动的事件而变动的资产。
    public func didReceiveAccountUpdate(_ update: FeatureAccountUpdate) {
        FeatureAccountManager.shared.updateWith(update)
    }
    
    /// Payload: 订单更新
    /// 订单通过executionReport事件进行更新。
    public func didReceiveOrderUpdate(_ report: FeatureTradeOrderUpdate) {
        FeatureOrderManager.shared.updateWith(report)
    }
    
    public func reopen() {
        Task { [self] in
            try await ws.close()
            await self.isolatedOpen()
        }
    }
    
    public func open() {
        Task { [self] in
            await isolatedOpen()
        }
    }
    
    public func login() async throws {
        let params: [String: Any] = [
            "apiKey": try APIConfig.shared.requireApiKey()
        ]
        let signParams = try params.addSignature()
        let clientId = UUID().uuidString
        let fullParams: [String: Any] = try [
            "id": clientId,
            "method": "session.logon",
            "params": signParams
        ]
        logInfo("准备ws登录：\(fullParams)")
        let jsonData = try JSONSerialization.data(withJSONObject: fullParams)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            try await ws.send(jsonString)
        }
    }
    
    func isolatedOpen() async {
        do {
            let key = try await createListenKey()
            let baseURL = APIConfig.shared.feature.wsBaseURL
            let url = "\(baseURL)/\(key)"
            logInfo("开始连接账户WS：\(url)")
            ws.url = URL(string: url)
            ws.open()
        } catch {
            logError("账户WS连接失败：\(error)，尝试重连")
            open()
        }
    }
    
    public func createListenKey() async throws -> String {
        let path = "POST /fapi/v1/listenKey"
        let res = try await RestAPI.post(path: path)
        if let json = res.res.bodyJson,
           let dict = json as? [String: Any],
           let listenKey = dict.stringFor("listenKey") {
            logInfo("请求到listenKey：\(listenKey)")
            return listenKey
        }
        throw CommonError(message: "解析body错误")
    }
}

// 开仓
//Websocket-->:收到string:{"e":"TRADE_LITE","E":1731954087444,"T":1731954087444,"s":"BTCUSDT","q":"0.002","p":"91739.90","m":false,"c":"android_MLA5BSDBdSD12WPlEyMh","S":"BUY","L":"91739.90","l":"0.002","t":5612428004,"i":482255808281}
//当前订单数量：1
//Websocket-->:收到string:{"e":"ORDER_TRADE_UPDATE","T":1731954087444,"E":1731954087444,"o":{"s":"BTCUSDT","c":"android_MLA5BSDBdSD12WPlEyMh","S":"BUY","o":"LIMIT","f":"GTC","q":"0.002","p":"91739.90","ap":"0","sp":"0","x":"NEW","X":"NEW","i":482255808281,"l":"0","z":"0","L":"0","n":"0","N":"USDT","T":1731954087444,"t":0,"b":"183.66307","a":"0","m":false,"R":false,"wt":"CONTRACT_PRICE","ot":"LIMIT","ps":"BOTH","cp":false,"rp":"0","pP":false,"si":0,"ss":0,"V":"NONE","pm":"OPPONENT","gtd":0}}
//处理数据错误：keyNotFound(CodingKeys(stringValue: "d", intValue: nil), Swift.DecodingError.Context(codingPath: [], debugDescription: "No value associated with key CodingKeys(stringValue: \"d\", intValue: nil) (\"d\").", underlyingError: nil))
//Websocket-->:收到string:{"e":"ACCOUNT_UPDATE","T":1731954087444,"E":1731954087444,"a":{"B":[{"a":"USDT","wb":"642.76097079","cw":"642.76097079","bc":"0"}],"P":[{"s":"BTCUSDT","pa":"0.002","ep":"91739.9","cr":"0","up":"-0.03508665","mt":"cross","iw":"0","ps":"BOTH","ma":"USDT","bep":"91785.76995"}],"m":"ORDER"}}
//当前订单数量：0
//Websocket-->:收到string:{"e":"ORDER_TRADE_UPDATE","T":1731954087444,"E":1731954087444,"o":{"s":"BTCUSDT","c":"android_MLA5BSDBdSD12WPlEyMh","S":"BUY","o":"LIMIT","f":"GTC","q":"0.002","p":"91739.90","ap":"91739.90000","sp":"0","x":"TRADE","X":"FILLED","i":482255808281,"l":"0.002","z":"0.002","L":"91739.90","n":"0.09173990","N":"USDT","T":1731954087444,"t":5612428004,"b":"0","a":"0","m":false,"R":false,"wt":"CONTRACT_PRICE","ot":"LIMIT","ps":"BOTH","cp":false,"rp":"0","pP":false,"si":0,"ss":0,"V":"NONE","pm":"OPPONENT","gtd":0}}

// 平仓
//Websocket-->:收到string:{"e":"TRADE_LITE","E":1731955175166,"T":1731955175166,"s":"BTCUSDT","q":"0.002","p":"0.00","m":false,"c":"android_WrDCjqlzTWlU9FGcNp1Q","S":"SELL","L":"90853.20","l":"0.002","t":5612520599,"i":482277363667}
//当前订单数量：1
//Websocket-->:收到string:{"e":"ORDER_TRADE_UPDATE","T":1731955175166,"E":1731955175166,"o":{"s":"BTCUSDT","c":"android_WrDCjqlzTWlU9FGcNp1Q","S":"SELL","o":"MARKET","f":"GTC","q":"0.002","p":"0","ap":"0","sp":"0","x":"NEW","X":"NEW","i":482277363667,"l":"0","z":"0","L":"0","n":"0","N":"USDT","T":1731955175166,"t":0,"b":"0","a":"0","m":false,"R":true,"wt":"CONTRACT_PRICE","ot":"MARKET","ps":"BOTH","cp":false,"rp":"0","pP":false,"si":0,"ss":0,"V":"NONE","pm":"NONE","gtd":0}}
//当前资产：
//USDT，总额：640.89671759，可用：631.88167158
//当前无持仓
//Websocket-->:收到string:{"e":"ACCOUNT_UPDATE","T":1731955175166,"E":1731955175166,"a":{"B":[{"a":"USDT","wb":"640.89671759","cw":"640.89671759","bc":"0"}],"P":[{"s":"BTCUSDT","pa":"0","ep":"0","cr":"-1.77340000","up":"0","mt":"cross","iw":"0","ps":"BOTH","ma":"USDT","bep":"0"}],"m":"ORDER"}}
//当前订单数量：0
//Websocket-->:收到string:{"e":"ORDER_TRADE_UPDATE","T":1731955175166,"E":1731955175166,"o":{"s":"BTCUSDT","c":"android_WrDCjqlzTWlU9FGcNp1Q","S":"SELL","o":"MARKET","f":"GTC","q":"0.002","p":"0","ap":"90853.20000","sp":"0","x":"TRADE","X":"FILLED","i":482277363667,"l":"0.002","z":"0.002","L":"90853.20","n":"0.09085320","N":"USDT","T":1731955175166,"t":5612520599,"b":"0","a":"0","m":false,"R":true,"wt":"CONTRACT_PRICE","ot":"MARKET","ps":"BOTH","cp":false,"rp":"-1.77340000","pP":false,"si":0,"ss":0,"V":"NONE","pm":"NONE","gtd":0}}
