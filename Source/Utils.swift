//
//  Utils.swift
//  ResultRxExtensions
//
//  Created by Sergey Smagleev on 25.02.18.
//  Copyright © 2018 Sergey Smagleev. All rights reserved.
//

import RxSwift
import Result

internal class Utils {
    
    internal static func combiningClosure<T: ResultProtocol, U: ResultProtocol, V, W>
        (errorPolicy: ResultErrorPolicy = .throwError,
         _ f: @escaping ((T.Value, U.Value) throws -> V))
        -> ((T, U) throws -> Result<V, W>)
        where T.Error == W, T.Error == U.Error {
            return { left, right -> Result<V, W> in
                if let lval = left.value, let rval = right.value {
                    return try catchResultError(errorPolicy: errorPolicy, { () -> Result<V, W> in
                        return Result.success(try f(lval, rval))
                    })
                }
                if let error = left.error {
                    return Result.failure(error)
                }
                if let error = right.error {
                    return Result.failure(error)
                }
                throw ResultExtError.invalidResultType
            }
    }
    
    internal static func catchResultError<T, U>
        (errorPolicy: ResultErrorPolicy,
         _ f: () throws -> Observable<Result<T, U>>) rethrows
        -> Observable<Result<T, U>> {
        do {
            return try f()
        } catch (let error) {
            if let error = error as? U, errorPolicy == .convertToFailure {
                return .just(Result<T, U>.failure(error))
            }
            throw error
        }
    }
    
    internal static func catchResultError<T, U>
        (errorPolicy: ResultErrorPolicy,
         _ f: () throws -> Result<T, U>) rethrows
        -> Result<T, U> {
            do {
                return try f()
            } catch (let error) {
                if let error = error as? U, errorPolicy == .convertToFailure {
                    return Result<T, U>.failure(error)
                }
                throw error
            }
    }
    
}
