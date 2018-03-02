# ResultRxExtensions

ResultRxExtensions is a set of operators written on top of `RxSwift` to streamline the use of values wrapped inside `Result`.
The intention is to simplify handling of `Observable<Result<T, Error>>` by providing the same experience as if working directly with `Observable<T>`. 
For instance, instead of writing this
```swift
let result = networking.getData()
    .map { (result) -> Result<TransformedObject, InternalError> in
        switch result {
        case .success(let object):
            guard let transformedObject = transform(object) else {
                return Result.failure(InternalError.someError)
            }
            return Result.success(transformedObject)
        case .failure(let error):
            return Result.failure(error)
        }       
}
```
you can now simply write this
```swift
let result = networking.getData()
    .mapSuccess(errorPolicy: .convertToFailure) { object -> TransformedObject in
        guard let transformedObject = transform(object) else {
            throw InternalError.someError
        }
        return transformedObject
}
```
ResultRxExtensions is doing all the wrapping and unwrapping for you, saving you from writing lots of boilerplate code.

## Methods
**handleSuccess**

Performs `.do` operator on success.

**handleFailure**

Performs `.do` operator on failure.

**subscribe *(onSuccess:onFailure:...)***

Just a regular `subscribe` method, but with individual closures for success and failure.

**mapSuccess**

Maps a successful result `Result<Value, Error>` to a result of a type `Result<T, Error>` by transforming a value using a transformation function `(Value) -> T`.

**mapFailure**

Maps a failed result `Result<Value, Error>` to a result of type `Result<Value, T>` by transforming an error using a transformation function `(Error) -> T`.

**flatMapSuccess**

Maps a successful result `Result<Value, Error>` to a result of type `Result<T, Error>` by transforming a value using a transformation function with one of the following signatures:
1.  `(Value) -> Result<T, Error>`
2. `(Value) -> Observable<T>`

**flatMapFailure**

Maps a successful result `Result<Value, Error>` to a result of type `Result<T, Error>` by transforming a value using a transformation function with one of the following signatures:
1.  `(Error) -> Result<Value, T>`
2. `(Error) -> Observable<T>`

**flatMapResultSuccess**

Maps a successful result `Result<Value, Error>` to a result of a type `Result<T, Error>` by transforming a value using a transformation function `(Value) -> Observable<Result<T, Error>>`.

**flatMapResultFailure**

Maps a failed result `Result<Value, Error>` to a result of type `Result<Value, T>` by transforming an error using a transformation function `(Error) -> Observable<Result<Value, T>>`.

**unwrap**

Unwraps the Observable from `Result<Value, Error>` domain to a simple `Observable<Value>`. For each successful result this method emits a `next(Value)` event and for a failed result it emits an `error(Error)`.

**unwrapIgnoringErrors**

Same method as `unwrap`, but ignores failed results and only returns `next` events.

**filterSuccess**

Perform filtering based on a clause which takes `Value` as a parameter `(Value) -> Bool`. Any failed result is ignored. If `ErrorPolicy.convertToFailure` is provided (see below), all errors converted to `Result.failure` are also ignored.

**withLatestFromSuccess**

Performs `.withLatestFrom` operator on two `Observable<Result>` using a combining function `(O1.Value, O2.Value) -> T`.

**zipSuccess**

Performs a `.zip` operator on two `Observable<Result>` using a combining function `(O1.Value, O2.Value) -> T`.

**combineLatestSuccess**

Performs a `.combineLatest` operator on two `Observable<Result>` using a combining function `(O1.Value, O2.Value) -> T`.

## Error Handling Policies

Normally, when an exception arises, it propagates all the way into internal RxSwift classes and results in `error(T)` being emitted. However, in some cases you might want to catch an error and return it as a failed `Result` instead. To customize desired behavior you can provide `ErrorPolicy` enum when calling an operator from ResultRxExtensions. There are two options:
- `throwsError` to not handle an exception and end up with `error(T)`;
- `convertToFailure` to try and convert the error to `Result.failure(T)` first and throw it forward if it's not possible.

If neither is specified `throwsError` is used by default.

## Usage with Moya

ResultRxExtensions works with `Moya/RxSwift` out of the box. It's built on top `Result` library so you can use it with `MoyaProvider<T>.rx.request()` straight away.

## Installation

- **Cocoapods**
Add `pod 'ResultRxExtensions', '0.1.0'` to your Podfile and run `pod install`

## To Do
- add flatMapLatest
- add more examples
