//
//  MapperTests.swift
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

class MapperTests: XCTestCase {
    
    private func getTestObservable(from scheduler: TestScheduler)
        -> TestableObservable<Result<Int, RxTestOneError>> {
            return scheduler.createHotObservable([
                next(250, Result<Int, RxTestOneError>.success(200)),
                next(300, Result<Int, RxTestOneError>.success(401)),
                next(350, Result<Int, RxTestOneError>.failure(RxTestOneError.oneTestError)),
                completed(400)
                ])
    }
    
    func testMap() {
        let scheduler = TestScheduler(initialClock: 0)
        let observable = getTestObservable(from: scheduler)
        let res = scheduler.start { () -> Observable<Result<String, RxTestAnotherError>> in
            return observable.mapSuccess({ (value) -> String in
                return "Value \(value)"
            }).mapFailure({ (error) -> RxTestAnotherError in
                switch error {
                case .oneTestError:
                    return RxTestAnotherError.oneTestError
                case .anotherTestError:
                    return RxTestAnotherError.anotherTestError
                }
            })
        }
        let correctEvents = [
            next(250, Result<String, RxTestAnotherError>.success("Value 200")),
            next(300, Result<String, RxTestAnotherError>.success("Value 401")),
            next(350, Result<String, RxTestAnotherError>.failure(RxTestAnotherError.oneTestError)),
            completed(400)
        ]
        XCTAssert(res.events == correctEvents)
    }
    
    func testFailingMapWithRethrow() {
        let scheduler = TestScheduler(initialClock: 0)
        let observable = getTestObservable(from: scheduler)
        let res = scheduler.start { () -> Observable<Result<String, RxTestAnotherError>> in
            return observable.mapSuccess(errorPolicy: .throwError, { (value) -> String in
                if (value == 200) {
                    return "Value \(value)"
                }
                throw RxTestOneError.oneTestError
            }).mapFailure({ (error) -> RxTestAnotherError in
                switch error {
                case .oneTestError:
                    return RxTestAnotherError.oneTestError
                case .anotherTestError:
                    return RxTestAnotherError.anotherTestError
                }
            })
        }
        let correctEvents: [Recorded<Event<Result<String, RxTestAnotherError>>>] = [
            next(250, Result.success("Value 200")),
            error(300, RxTestOneError.oneTestError)
        ]
        XCTAssert(res.events == correctEvents)
    }
    
    func testFailingMapWithConvert() {
        let scheduler = TestScheduler(initialClock: 0)
        let observable = getTestObservable(from: scheduler)
        let res = scheduler.start { () -> Observable<Result<String, RxTestAnotherError>> in
            return observable.mapSuccess(errorPolicy: .convertToFailure, { (value) -> String in
                if (value == 200) {
                    return "Value \(value)"
                }
                throw RxTestOneError.oneTestError
            }).mapFailure({ (error) -> RxTestAnotherError in
                switch error {
                case .oneTestError:
                    return RxTestAnotherError.oneTestError
                case .anotherTestError:
                    return RxTestAnotherError.anotherTestError
                }
            })
        }
        let correctEvents = [
            next(250, Result<String, RxTestAnotherError>.success("Value 200")),
            next(300, Result<String, RxTestAnotherError>.failure(RxTestAnotherError.oneTestError)),
            next(350, Result<String, RxTestAnotherError>.failure(RxTestAnotherError.oneTestError)),
            completed(400)
        ]
        XCTAssert(res.events == correctEvents)
    }
    
    func testFailingMapWithMismatchingConvert() {
        let scheduler = TestScheduler(initialClock: 0)
        let observable = getTestObservable(from: scheduler)
        let res = scheduler.start { () -> Observable<Result<String, RxTestAnotherError>> in
            return observable.mapSuccess(errorPolicy: .convertToFailure, { (value) -> String in
                if (value == 200) {
                    return "Value \(value)"
                }
                throw RxTestAnotherError.oneTestError
            }).mapFailure({ (error) -> RxTestAnotherError in
                switch error {
                case .oneTestError:
                    return RxTestAnotherError.oneTestError
                case .anotherTestError:
                    return RxTestAnotherError.anotherTestError
                }
            })
        }
        let correctEvents: [Recorded<Event<Result<String, RxTestAnotherError>>>] = [
            next(250, Result<String, RxTestAnotherError>.success("Value 200")),
            error(300, RxTestAnotherError.oneTestError)
        ]
        XCTAssert(res.events == correctEvents)
    }
    
    func testFlatMapObservable() {
        let scheduler = TestScheduler(initialClock: 0)
        let observable = getTestObservable(from: scheduler)
        let res = scheduler.start { () -> Observable<Result<String, RxTestAnotherError>> in
            return observable.flatMapSuccess(errorPolicy: .convertToFailure, { (value) -> Observable<String> in
                if (value == 200) {
                    return .just("Value \(value)")
                }
                throw RxTestOneError.oneTestError
            }).flatMapFailure({ (error) -> Observable<RxTestAnotherError> in
                switch error {
                case .oneTestError:
                    return .just(RxTestAnotherError.oneTestError)
                case .anotherTestError:
                    return .just(RxTestAnotherError.anotherTestError)
                }
            })
        }
        
        let correctEvents = [
            next(250, Result<String, RxTestAnotherError>.success("Value 200")),
            next(300, Result<String, RxTestAnotherError>.failure(RxTestAnotherError.oneTestError)),
            next(350, Result<String, RxTestAnotherError>.failure(RxTestAnotherError.oneTestError)),
            completed(400)
        ]
        XCTAssert(res.events == correctEvents)
    }
    
    func testFlatMapResult() {
        let scheduler = TestScheduler(initialClock: 0)
        let observable = getTestObservable(from: scheduler)
        let res = scheduler.start { () -> Observable<Result<String, RxTestAnotherError>> in
            return observable.flatMapSuccess({ (value) -> Result<String, RxTestOneError> in
                if (value == 200) {
                    return .success("Success")
                }
                return .failure(RxTestOneError.anotherTestError)
            }).flatMapFailure({ (error) -> Result<String, RxTestAnotherError> in
                return .failure(RxTestAnotherError.oneTestError)
            })
        }
        let correctEvents = [
            next(250, Result<String, RxTestAnotherError>.success("Success")),
            next(300, Result<String, RxTestAnotherError>.failure(RxTestAnotherError.oneTestError)),
            next(350, Result<String, RxTestAnotherError>.failure(RxTestAnotherError.oneTestError)),
            completed(400)
        ]
        XCTAssert(res.events == correctEvents)
    }
    
    func testFlatMapResultObservable() {
        let scheduler = TestScheduler(initialClock: 0)
        let observable = getTestObservable(from: scheduler)
        let res = scheduler.start { () -> Observable<Result<String, RxTestAnotherError>> in
            return observable.flatMapResultSuccess({ (value) -> Observable<Result<String, RxTestOneError>> in
                return Observable.create({ (observer) -> Disposable in
                    if (value == 200) {
                        observer.onNext(Result.success("Value \(value)"))
                    } else {
                        observer.onNext(Result.failure(RxTestOneError.oneTestError))
                    }
                    observer.onCompleted()
                    return Disposables.create()
                })
            }).flatMapResultFailure({ (error) -> Observable<Result<String, RxTestAnotherError>> in
                return Observable.create({ (observer) -> Disposable in
                    switch error {
                    case .oneTestError:
                        observer.onNext(Result.failure(RxTestAnotherError.oneTestError))
                    case .anotherTestError:
                        observer.onNext(Result.failure(RxTestAnotherError.anotherTestError))
                    }
                    observer.onCompleted()
                    return Disposables.create()
                })
                
            })
        }
        
        let correctEvents = [
            next(250, Result<String, RxTestAnotherError>.success("Value 200")),
            next(300, Result<String, RxTestAnotherError>.failure(RxTestAnotherError.oneTestError)),
            next(350, Result<String, RxTestAnotherError>.failure(RxTestAnotherError.oneTestError)),
            completed(400)
        ]
        XCTAssert(res.events == correctEvents)
    }
    
}
