//
//  OtherTests.swift
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

class OtherTests: XCTestCase {
    
    private func getTestObservable(from scheduler: TestScheduler)
        -> TestableObservable<Result<Int, RxTestOneError>> {
            return scheduler.createHotObservable([
                next(250, Result<Int, RxTestOneError>.success(200)),
                next(300, Result<Int, RxTestOneError>.failure(RxTestOneError.oneTestError)),
                next(350, Result<Int, RxTestOneError>.success(300)),
                next(400, Result<Int, RxTestOneError>.failure(RxTestOneError.oneTestError)),
                next(450, Result<Int, RxTestOneError>.failure(RxTestOneError.oneTestError)),
                next(500, Result<Int, RxTestOneError>.success(400)),
                completed(550)
                ])
    }
    
    func testUnwrapIgnoringErrors() {
        let scheduler = TestScheduler(initialClock: 0)
        let observable = getTestObservable(from: scheduler)
        let res = scheduler.start { () -> Observable<Int> in
            return observable.unwrapIgnoringErrors()
        }
        let correctEvents = [
            next(250, 200),
            next(350, 300),
            next(500, 400),
            completed(550)
        ]
        XCTAssertEqual(res.events, correctEvents)
    }
    
    func testUnwrapWithErrors() {
        let scheduler = TestScheduler(initialClock: 0)
        let observable = getTestObservable(from: scheduler)
        let res = scheduler.start { () -> Observable<Int> in
            return observable.unwrap()
        }
        let correctEvents = [
            next(250, 200),
            error(300, RxTestOneError.oneTestError)
        ]
        XCTAssertEqual(res.events, correctEvents)
    }
    
    func testFilter() {
        let scheduler = TestScheduler(initialClock: 0)
        let observable = getTestObservable(from: scheduler)
        let res = scheduler.start { () -> Observable<Result<Int, RxTestOneError>> in
            return observable.filterSuccess({ (value) -> Bool in
                return value > 250
            })
        }
        let correctEvents = [
            next(350, Result<Int, RxTestOneError>.success(300)),
            next(500, Result<Int, RxTestOneError>.success(400)),
            error(300, RxTestOneError.oneTestError)
        ]
        XCTAssert(res.events == correctEvents)
    }
    
}
