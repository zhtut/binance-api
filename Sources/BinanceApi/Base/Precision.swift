//
//  Util.swift
//  binance-api
//
//  Created by tutuzhou on 2024/11/19.
//

import Foundation
//
public extension String {
//    
//    var doubleValue: Double? {
//        return Double(self)
//    }
//    
//    var intValue: Int? {
//        if let doubleValue = doubleValue {
//            return Int(doubleValue)
//        }
//        return nil
//    }
//    
    var decimalValue: Decimal? {
        return Decimal(string: self)
    }
//    
//    var precision: Int {
//        var newPre = self
//        while newPre.hasSuffix("0") {
//            newPre = "\(newPre.prefix(newPre.count - 2))"
//        }
//        let arr = newPre.components(separatedBy: ".")
//        if arr.count == 1 {
//            return 0
//        }
//        if let str = arr.last {
//            return str.count
//        }
//        return 0
//    }
}
//
//public extension Double {
//    var stringValue: String? {
//        return "\(self)"
//    }
//    
//    var decimalValue: Decimal {
//        return Decimal(self)
//    }
//}
//
//public extension Int {
//    var stringValue: String? {
//        return "\(self)"
//    }
//    var doubleValue: Double {
//        return Double(self)
//    }
//    var decimalValue: Decimal {
//        return Decimal(self)
//    }
//}
//
//public extension Double {
//    /// 取精度
//    /// - Parameter count: 小数点后几位
//    /// - Returns: 获取精度后的数据
//    func precisionStringWith(count: Int) -> String {
//        let format = NumberFormatter()
//        format.minimumFractionDigits = 0
//        format.maximumFractionDigits = count
//        format.roundingMode = .halfUp
//        let str = format.string(for: self)
//        return str ?? ""
//    }
//    
//    /// 取精度
//    /// - Parameter precision: 精度字符串，如0.000001
//    /// - Returns: 获取精度后的数据
//    func precisionStringWith(precision: String) -> String {
//        let count = precision.precision
//        return precisionStringWith(count: count)
//    }
//}
