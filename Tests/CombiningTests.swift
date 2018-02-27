//
//  CombiningTests.swift
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

class CombiningTests: XCTestCase {
    
    private func getObservable1(from scheduler: TestScheduler)
        -> TestableObservable<Result<Int, RxTestOneError>> {
            return scheduler.createHotObservable([
                next(250, Result<Int, RxTestOneError>.success(200)),
                next(400, Result<Int, RxTestOneError>.success(300)),
                next(500, Result<Int, RxTestOneError>.success(400)),
                completed(560)
                ])
    }
    
    private func getObservable2(from scheduler: TestScheduler)
        -> TestableObservable<Result<Int, RxTestOneError>> {
            return scheduler.createHotObservable([
                next(300, Result<Int, RxTestOneError>.success(500)),
                next(350, Result<Int, RxTestOneError>.success(120)),
                next(550, Result<Int, RxTestOneError>.success(900)),
                completed(600)
                ])
    }
    
    func testZipResult() {
        let scheduler = TestScheduler(initialClock: 0)
        let observable1 = getObservable1(from: scheduler)
        let observable2 = getObservable2(from: scheduler)
        let res = scheduler.start { () -> Observable<Result<EquatableTuple<Int, Int>, RxTestOneError>> in
            return Observable<Any>.zipSuccess(observable1, observable2) { left, right in
                return EquatableTuple(left, right)
            }
        }
        let correctEvents: [Recorded<Event<Result<EquatableTuple<Int, Int>, RxTestOneError>>>] = [
            next(300, Result.success(EquatableTuple<Int, Int>(200, 500))),
            next(400, Result.success(EquatableTuple<Int, Int>(300, 120))),
            next(550, Result.success(EquatableTuple<Int, Int>(400, 900))),
            completed(600)
        ]
        XCTAssert(res.events == correctEvents)
    }
    
    func testCombineLatestSuccess() {
        let scheduler = TestScheduler(initialClock: 0)
        let observable1 = getObservable1(from: scheduler)
        let observable2 = getObservable2(from: scheduler)
        let res = scheduler.start { () -> Observable<Result<EquatableTuple<Int, Int>, RxTestOneError>> in
            return Observable<Any>.combineLatestSuccess(observable1, observable2) { left, right in
                return EquatableTuple(left, right)
            }
        }
        let correctEvents: [Recorded<Event<Result<EquatableTuple<Int, Int>, RxTestOneError>>>] = [
            next(300, Result.success(EquatableTuple<Int, Int>(200, 500))),
            next(350, Result.success(EquatableTuple<Int, Int>(200, 120))),
            next(400, Result.success(EquatableTuple<Int, Int>(300, 120))),
            next(500, Result.success(EquatableTuple<Int, Int>(400, 120))),
            next(550, Result.success(EquatableTuple<Int, Int>(400, 900))),
            completed(600)
        ]
        XCTAssert(res.events == correctEvents)
    }
    
    func testWithLatestFromSuccess() {
        let scheduler = TestScheduler(initialClock: 0)
        let observable1 = getObservable1(from: scheduler)
        let observable2 = getObservable2(from: scheduler)
        let res = scheduler.start { () -> Observable<Result<EquatableTuple<Int, Int>, RxTestOneError>> in
            return observable1.withLatestFromSuccess(observable2) { left, right in
                return EquatableTuple(left, right)
            }
        }
        let correctEvents: [Recorded<Event<Result<EquatableTuple<Int, Int>, RxTestOneError>>>] = [
            next(400, Result.success(EquatableTuple<Int, Int>(300, 120))),
            next(500, Result.success(EquatableTuple<Int, Int>(400, 120))),
            completed(600)
        ]
        XCTAssert(res.events == correctEvents)
    }
    
}
