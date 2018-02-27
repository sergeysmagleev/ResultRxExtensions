//
//  UtilsTests.swift
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

class UtilsTests: XCTestCase {
    
    private func getTestObservable(from scheduler: TestScheduler)
        -> TestableObservable<Result<String, RxTestOneError>> {
        return scheduler.createHotObservable([
            next(250, Result<String, RxTestOneError>.success("String")),
            next(300, Result<String, RxTestOneError>.failure(RxTestOneError.oneTestError)),
            completed(350)
            ])
    }
    
    func testThrowingError() {
        let scheduler = TestScheduler(initialClock: 0)
        let observable = getTestObservable(from: scheduler)
        let correctEvents: [Recorded<Event<Result<String, RxTestOneError>>>] = [
            error(250, RxTestOneError.oneTestError)
        ]
        let res = scheduler.start { () -> Observable<Result<String, RxTestOneError>> in
            return observable.flatMap { _ -> Observable<Result<String, RxTestOneError>> in
                return try Utils.catchResultError(errorPolicy: .throwError) {
                    () -> Observable<Result<String, RxTestOneError>> in
                    throw RxTestOneError.oneTestError
                }
            }
        }
        XCTAssert(res.events == correctEvents)
    }
    
    func testCatchingError() {
        let scheduler = TestScheduler(initialClock: 0)
        let observable = getTestObservable(from: scheduler)
        let correctEvents = [
            next(250, Result<String, RxTestOneError>.failure(RxTestOneError.oneTestError)),
            next(300, Result<String, RxTestOneError>.failure(RxTestOneError.oneTestError)),
            completed(350)
        ]
        let res = scheduler.start { () -> Observable<Result<String, RxTestOneError>> in
            return observable.flatMap { _ -> Observable<Result<String, RxTestOneError>> in
                return try Utils.catchResultError(errorPolicy: .convertToFailure) {
                    () -> Observable<Result<String, RxTestOneError>> in
                    throw RxTestOneError.oneTestError
                }
            }
        }
        XCTAssert(res.events == correctEvents)
    }
    
    func testMismatchingError() {
        let scheduler = TestScheduler(initialClock: 0)
        let observable = getTestObservable(from: scheduler)
        let correctEvents: [Recorded<Event<Result<String, RxTestOneError>>>] = [
            error(250, RxTestAnotherError.oneTestError)
        ]
        let res = scheduler.start { () -> Observable<Result<String, RxTestOneError>> in
            return observable.flatMap { _ -> Observable<Result<String, RxTestOneError>> in
                return try Utils.catchResultError(errorPolicy: .convertToFailure) {
                    () -> Observable<Result<String, RxTestOneError>> in
                    throw RxTestAnotherError.oneTestError
                }
            }
        }
        XCTAssert(res.events == correctEvents)
    }
    
    func testThrowingResultError() {
        let errorExpectation = expectation(description: "error")
        do {
            _ = try Utils.catchResultError(errorPolicy: .throwError) {
                () -> Result<String, RxTestOneError> in
                throw RxTestOneError.oneTestError
            }
        } catch RxTestOneError.oneTestError {
            errorExpectation.fulfill()
        } catch {
            XCTFail()
        }
        wait(for: [errorExpectation], timeout: 1.0)
    }
    
    func testCatchingResultError() {
        let result: Result<String, RxTestOneError>
        do {
            result = try Utils.catchResultError(errorPolicy: .convertToFailure) {
                () -> Result<String, RxTestOneError> in
                throw RxTestOneError.oneTestError
            }
        } catch {
            XCTFail()
            return
        }
        XCTAssert(result == Result<String, RxTestOneError>.failure(RxTestOneError.oneTestError))
    }
    
    func testMismatchingResultError() {
        let errorExpectation = expectation(description: "error")
        do {
            _ = try Utils.catchResultError(errorPolicy: .convertToFailure) {
                () -> Result<String, RxTestOneError> in
                throw RxTestAnotherError.oneTestError
            }
        } catch RxTestAnotherError.oneTestError {
            errorExpectation.fulfill()
        } catch {
            XCTFail()
        }
        wait(for: [errorExpectation], timeout: 1.0)
    }
    
}
