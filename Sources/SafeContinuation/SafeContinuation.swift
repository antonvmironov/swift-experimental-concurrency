//===----------------------------------------------------------------------===//
//
//  This source file is part of the swift-experimental-concurrency
//  open source project.
//
//  Copyright 2025 Anton Myronov.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//===----------------------------------------------------------------------===//

import struct Lock.Lock
import struct Lock.unlock

/// A mechanism to interface between synchronous and asynchronous code,
/// automatically handles violation of continuation invariants like:
/// * continuation is lost (deinitialized) before
///   it was resumed by resuming it with provided fallback
/// * continuation was resumed more than once
///
/// A *continuation* is an opaque representation of program state.
/// To create a continuation in asynchronous code,
/// call the `withSafeContinuation(function:_:)` or
/// `withSafeThrowingContinuation(function:_:)` function.
/// To resume the asynchronous task,
/// call the `resume(returning:)`,
/// `resume(throwing:)`,
/// `resume(with:)`,
/// or `resume()` method.
public struct SafeContinuation<Success, Failure: Error>: Sendable {
  @usableFromInline
  typealias Guts = SafeContinuationGuts<Success, Failure>

  @usableFromInline
  let _guts: Lock<Guts>

  @inlinable
  init(
    unsafeContinuation: consuming sending Guts.UnsafeContinuation,
    fallbackResultBox: consuming sending Guts.FallbackResultBox,
  ) {
    let impl = Guts(
      unsafeContinuation: unsafeContinuation,
      fallbackResultBox: fallbackResultBox,
    )
    _guts = Lock(impl)
  }

  @inlinable
  public func resume(returning value: consuming sending Success) {
    var impl = unlock(_guts)
    impl.state.resume(returning: value)
  }

  @inlinable
  public func resume(throwing error: consuming Failure) {
    var impl = unlock(_guts)
    impl.state.resume(throwing: error)
  }

  @inlinable
  public func resume(with result: consuming sending Result<Success, Failure>) {
    switch result {
      case .success(let value):
        resume(returning: value)
      case .failure(let failure):
        resume(throwing: failure)
    }
  }
}
