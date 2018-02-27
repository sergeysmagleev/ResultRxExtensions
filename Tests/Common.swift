//
//  Common.swift
//  ResultRxExtensions
//
//  Created by Sergey Smagleev on 26.02.18.
//  Copyright © 2018 Sergey Smagleev. All rights reserved.
//

import XCTest
import RxSwift
import RxTest
import Result
@testable import ResultRxExtensions

internal struct EquatableTuple<T, U>: Equatable where T: Equatable, U: Equatable {
    
    let item1: T
    let item2: U
    
    init(_ item1: T, _ item2: U) {
        self.item1 = item1
        self.item2 = item2
    }
    
    init(_ tuple: (T, U)) {
        self.item1 = tuple.0
        self.item2 = tuple.1
    }
    
    internal static func ==(lhs: EquatableTuple, rhs: EquatableTuple) -> Bool {
        return lhs.item1 == rhs.item1 && lhs.item2 == rhs.item2
    }
}

internal func == <T: ResultProtocol> (left: Event<T>, right: Event<T>) -> Bool
    where T.Value: Equatable, T.Error: Equatable
{
    if let left = left.element, let right = right.element {
        return left == right
    }
    if left.element == nil && right.element == nil {
        return true
    }
    return false
}

internal func == <T: ResultProtocol> (left: Recorded<Event<T>>, right: Recorded<Event<T>>) -> Bool
    where T.Value: Equatable, T.Error: Equatable
{
    return left.value == right.value
}

internal func == <T: ResultProtocol> (left: Array<Recorded<Event<T>>>, right: Array<Recorded<Event<T>>>) -> Bool
    where T.Value: Equatable, T.Error: Equatable
{
    return left.count == right.count && zip(left, right).reduce(true) { $0 && $1.0 == $1.1 }
}

internal enum RxTestOneError: Error {
    case oneTestError
    case anotherTestError
}

internal enum RxTestAnotherError: Error {
    case oneTestError
    case anotherTestError
}
