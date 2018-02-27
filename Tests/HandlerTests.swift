//
//  HandlerTests.swift
//  ResultRxExtensions
//
//  Created by Sergey Smagleev on 27.02.18.
//  Copyright © 2018 Sergey Smagleev. All rights reserved.
//

import XCTest
import RxSwift
import RxTest
import Result
@testable import ResultRxExtensions

class HandlerTests: XCTestCase {
    
    private var disposeBag: DisposeBag?
    
    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
    }
    
    override func tearDown() {
        super.tearDown()
        disposeBag = nil
    }
    
    func testHandlers() {
        let scheduler = TestScheduler(initialClock: 0)
        let successExpectation = expectation(description: "success")
        let failureExpectation = expectation(description: "failure")
        let observable = scheduler.createHotObservable([
            next(250, Result<Int, RxTestOneError>.success(200)),
            next(300, Result<Int, RxTestOneError>.failure(RxTestOneError.oneTestError)),
            completed(350)
            ])
        _ = scheduler.start { () -> Observable<Result<Int, RxTestOneError>> in
            return observable.handleSuccess({ (value) in
                XCTAssertEqual(value, 200)
                successExpectation.fulfill()
            }).handleFailure({ (error) in
                switch error {
                case .oneTestError:
                    failureExpectation.fulfill()
                case .anotherTestError:
                    XCTFail("wrong error")
                }
            })
        }
        wait(for: [successExpectation, failureExpectation], timeout: 1.0)
    }
    
    func testSubscribe() {
        guard let disposeBag = disposeBag else {
            XCTFail()
            return
        }
        let scheduler = TestScheduler(initialClock: 0)
        let observable = scheduler.createHotObservable([
            next(250, Result<Int, RxTestOneError>.success(200)),
            next(300, Result<Int, RxTestOneError>.failure(RxTestOneError.oneTestError)),
            completed(400)
            ])
        let successExpectation = expectation(description: "success")
        let failureExpectation = expectation(description: "failure")
        observable.subscribe(onSuccess: { (value) in
            XCTAssertEqual(value, 200)
            successExpectation.fulfill()
        }, onFailure: { (error) in
            XCTAssertEqual(error, RxTestOneError.oneTestError)
            failureExpectation.fulfill()
        }).disposed(by: disposeBag)
        scheduler.start()
        wait(for: [successExpectation, failureExpectation], timeout: 1.0)
    }
    
}
