//
//  File.swift
//  
//
//  Created by tutuzhou on 2024/1/20.
//

import Foundation
#if canImport(CombineX)
import CombineX
#else
import Combine
#endif

/// combine基类
open class CombineBase {
    /// 绑定的组合
    open var subscriptions = Set<AnyCancellable>()
    
    /// 单个绑定对象
    open var anyCancellable: AnyCancellable?
    
    public init() {
        
    }
}
