//
//  Result+Rx.swift
//  ResultRxExtensions
//
//  Created by Sergey Smagleev on 27.02.18.
//  Copyright © 2018 Sergey Smagleev. All rights reserved.
//

import RxSwift
import Result

public enum ResultExtError: Swift.Error {
    case invalidResultType
}

public enum ResultErrorPolicy {
    case throwError
    case convertToFailure
}

public extension ObservableType where E: ResultProtocol {
    
    public func handleSuccess(_ f: @escaping (E.Value) throws -> Void) -> Observable<Self.E> {
        return self.do(onNext: { (item) in
            if let value = item.value {
                try f(value)
            }
        })
    }
    
    public func handleFailure(_ f: @escaping (E.Error) throws -> Void) -> Observable<Self.E> {
        return self.do(onNext: { (item) in
            if let error = item.error {
                try f(error)
            }
        })
    }
    
    public func subscribe(onSuccess: ((E.Value) -> Void)? = nil,
                          onFailure: ((E.Error) -> Void)? = nil,
                          onError: ((Swift.Error) -> Void)? = nil,
                          onCompleted: (() -> Void)? = nil,
                          onDisposed: (() -> Void)? = nil) -> Disposable {
        return self.subscribe(onNext: { (item: E) -> Void in
            if let value = item.value {
                onSuccess?(value)
            }
            if let error = item.error {
                onFailure?(error)
            }
        }, onError: onError, onCompleted: onCompleted, onDisposed: onDisposed)
    }
    
    public func mapSuccess<T>(errorPolicy: ResultErrorPolicy = .throwError,
                              _ f: @escaping (E.Value) throws -> T)
        -> Observable<Result<T, E.Error>> {
            return self.map { (item) -> Result<T, E.Error> in
                if let value = item.value {
                    return try Utils.catchResultError(errorPolicy: errorPolicy) { () -> Result<T, E.Error> in
                        return Result<T, E.Error>.success(try f(value))
                    }
                }
                if let error = item.error {
                    return Result<T, E.Error>.failure(error)
                }
                throw ResultExtError.invalidResultType
            }
    }
    
    public func mapFailure<T>(errorPolicy: ResultErrorPolicy = .throwError,
                              _ f: @escaping (E.Error) throws -> T)
        -> Observable<Result<E.Value, T>> {
            return self.map { (item) -> Result<E.Value, T> in
                if let error = item.error {
                    return try Utils.catchResultError(errorPolicy: errorPolicy) { () -> Result<E.Value, T> in
                        return Result<E.Value, T>.failure(try f(error))
                    }
                }
                if let value = item.value {
                    return Result<E.Value, T>.success(value)
                }
                throw ResultExtError.invalidResultType
            }
    }
    
    public func flatMapSuccess<T>(errorPolicy: ResultErrorPolicy = .throwError,
                                  _ f: @escaping (E.Value) throws -> Observable<T>)
        -> Observable<Result<T, E.Error>> {
            return self.flatMap { (item) -> Observable<Result<T, E.Error>> in
                if let value = item.value {
                    return try Utils.catchResultError(errorPolicy: errorPolicy) {
                        () -> Observable<Result<T, E.Error>> in
                        return try f(value).map { Result<T, E.Error>.success($0) }
                    }
                }
                if let error = item.error {
                    return .just(Result<T, E.Error>.failure(error))
                }
                throw ResultExtError.invalidResultType
            }
    }
    
    public func flatMapFailure<T>(errorPolicy: ResultErrorPolicy = .throwError,
                                  _ f: @escaping (E.Error) throws -> Observable<T>)
        -> Observable<Result<E.Value, T>> {
            return self.flatMap { (item) -> Observable<Result<E.Value, T>> in
                if let error = item.error {
                    return try Utils.catchResultError(errorPolicy: errorPolicy) {
                        () -> Observable<Result<E.Value, T>> in
                        return try f(error).map { Result<E.Value, T>.failure($0) }
                    }
                }
                if let value = item.value {
                    return .just(Result<E.Value, T>.success(value))
                }
                throw ResultExtError.invalidResultType
            }
    }
    
    public func flatMapSuccess<T>(errorPolicy: ResultErrorPolicy = .throwError,
                                  _ f: @escaping (E.Value) throws -> Result<T, E.Error>)
        -> Observable<Result<T, E.Error>> {
            return self.flatMap { (item) -> Observable<Result<T, E.Error>> in
                if let value = item.value {
                    return try Utils.catchResultError(errorPolicy: errorPolicy) {
                        () -> Observable<Result<T, E.Error>> in
                        let innerItem = try f(value)
                        switch innerItem {
                        case .success(let innerValue):
                            return .just(Result<T, E.Error>.success(innerValue))
                        case .failure(let innerError):
                            return .just(Result<T, E.Error>.failure(innerError))
                        }
                    }
                }
                if let error = item.error {
                    return .just(Result<T, E.Error>.failure(error))
                }
                throw ResultExtError.invalidResultType
            }
    }
    
    public func flatMapFailure<T>(errorPolicy: ResultErrorPolicy = .throwError,
                                  _ f: @escaping (E.Error) throws -> Result<E.Value, T>)
        -> Observable<Result<E.Value, T>> {
            return self.flatMap { (item) -> Observable<Result<E.Value, T>> in
                if let error = item.error {
                    return try Utils.catchResultError(errorPolicy: errorPolicy) {
                        () -> Observable<Result<E.Value, T>> in
                        let innerItem = try f(error)
                        switch innerItem {
                        case .success(let innerValue):
                            return .just(Result<E.Value, T>.success(innerValue))
                        case .failure(let innerError):
                            return .just(Result<E.Value, T>.failure(innerError))
                        }
                    }
                }
                if let value = item.value {
                    return .just(Result<E.Value, T>.success(value))
                }
                throw ResultExtError.invalidResultType
            }
    }
    
    public func flatMapResultSuccess<T>(errorPolicy: ResultErrorPolicy = .throwError,
                                        _ f: @escaping (E.Value) throws -> Observable<Result<T, E.Error>>)
        -> Observable<Result<T, E.Error>> {
            return self.flatMap { (item) -> Observable<Result<T, E.Error>> in
                if let value = item.value {
                    return try Utils.catchResultError(errorPolicy: errorPolicy) {
                        () -> Observable<Result<T, E.Error>> in
                        return try f(value).map { innerItem -> Result<T, E.Error> in
                            switch innerItem {
                            case .success(let innerValue):
                                return Result<T, E.Error>.success(innerValue)
                            case .failure(let innerError):
                                return Result<T, E.Error>.failure(innerError)
                            }
                        }
                    }
                }
                if let error = item.error {
                    return .just(Result<T, E.Error>.failure(error))
                }
                throw ResultExtError.invalidResultType
            }
    }
    
    public func flatMapResultFailure<T>(errorPolicy: ResultErrorPolicy = .throwError,
                                        _ f: @escaping (E.Error) throws -> Observable<Result<E.Value, T>>)
        -> Observable<Result<E.Value, T>> {
            return self.flatMap { (item) -> Observable<Result<E.Value, T>> in
                if let error = item.error {
                    return try Utils.catchResultError(errorPolicy: errorPolicy) {
                        () -> Observable<Result<E.Value, T>> in
                        return try f(error).map { innerItem -> Result<E.Value, T> in
                            switch innerItem {
                            case .success(let innerValue):
                                return Result<E.Value, T>.success(innerValue)
                            case .failure(let innerError):
                                return Result<E.Value, T>.failure(innerError)
                            }
                        }
                    }
                }
                if let value = item.value {
                    return .just(Result<E.Value, T>.success(value))
                }
                throw ResultExtError.invalidResultType
            }
    }
    
    public func unwrapIgnoringErrors() -> Observable<E.Value> {
        return self.flatMap { (item) -> Observable<E.Value> in
            if let value = item.value {
                return Observable<E.Value>.just(value)
            }
            if let _ = item.error {
                return Observable<E.Value>.empty()
            }
            throw ResultExtError.invalidResultType
        }
    }
    
    public func unwrap() -> Observable<E.Value> {
        return self.flatMap { (item) -> Observable<E.Value> in
            if let value = item.value {
                return Observable<E.Value>.just(value)
            }
            if let error = item.error {
                return Observable<E.Value>.error(error)
            }
            throw ResultExtError.invalidResultType
        }
    }
    
    public func filterSuccess(errorPolicy: ResultErrorPolicy = .throwError,
                              _ f: @escaping (E.Value) throws -> Bool )
        -> Observable<Result<E.Value, E.Error>> {
            return self.flatMap { (item) -> Observable<Result<E.Value, E.Error>> in
                if let value = item.value {
                    do {
                        if (try f(value)) {
                            return .just(Result.success(value))
                        }
                        return .empty()
                    } catch (let error) {
                        switch errorPolicy {
                        case .convertToFailure:
                            return .empty()
                        case .throwError:
                            throw error
                        }
                    }
                }
                if let _ = item.error {
                    return .empty()
                }
                throw ResultExtError.invalidResultType
            }
    }
    
    public func withLatestFromSuccess<O2: ObservableType, T>
        (_ source2: O2,
         errorPolicy: ResultErrorPolicy = .throwError,
         _ f: @escaping ((E.Value, O2.E.Value) throws -> T))
        -> Observable<Result<T, E.Error>>
        where O2.E: ResultProtocol, E.Error == O2.E.Error {
            return self.withLatestFrom(source2,
                                       resultSelector: Utils.combiningClosure(errorPolicy: errorPolicy, f))
    }
    
}

public extension ObservableType {
    
    public static func zipSuccess<O1: ObservableType, O2: ObservableType, T>
        (_ source1: O1,
         _ source2: O2,
         errorPolicy: ResultErrorPolicy = .throwError,
         _ f: @escaping ((O1.E.Value, O2.E.Value) throws -> T))
        -> Observable<Result<T, O1.E.Error>>
        where O1.E: ResultProtocol, O2.E: ResultProtocol, O1.E.Error == O2.E.Error {
            return Observable.zip(source1,
                                  source2,
                                  resultSelector: Utils.combiningClosure(errorPolicy: errorPolicy, f))
    }
    
    public static func combineLatestSuccess<O1: ObservableType, O2: ObservableType, T>
        (_ source1: O1,
         _ source2: O2,
         errorPolicy: ResultErrorPolicy = .throwError,
         _ f: @escaping ((O1.E.Value, O2.E.Value) throws -> T))
        -> Observable<Result<T, O1.E.Error>>
        where O1.E: ResultProtocol, O2.E: ResultProtocol, O1.E.Error == O2.E.Error {
            return Observable.combineLatest(source1,
                                            source2,
                                            resultSelector: Utils.combiningClosure(errorPolicy: errorPolicy, f))
    }
    
}
