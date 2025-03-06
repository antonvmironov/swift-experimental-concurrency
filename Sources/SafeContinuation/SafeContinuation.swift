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

import struct Unsafe.UnsafeSendingBox
import struct Lock.Lock
import struct Lock.unlock

public struct SafeContinuation<T, E: Error>: Sendable {
  @usableFromInline
  typealias FallbackResultBox = UnsafeSendingBox<Result<T, E>>

  @usableFromInline
  let _impl: Lock<_Impl>

  @inlinable
  init(
    unsafeContinuation: consuming sending UnsafeContinuation<T, E>,
    fallbackResultBox: consuming sending FallbackResultBox,
  ) {
    let impl = _Impl(
      unsafeContinuation: unsafeContinuation,
      fallbackResultBox: fallbackResultBox,
    )
    _impl = Lock(impl)
  }

  @inlinable
  public func resume(returning value: consuming sending T) {
    var impl = unlock(_impl)
    impl.value.resume(returning: value)
  }

  @inlinable
  public func resume(throwing error: consuming E) {
    var impl = unlock(_impl)
    impl.value.resume(throwing: error)
  }

  @inlinable
  public func resume(with result: consuming sending Result<T, E>) {
    switch result {
      case .success(let value):
        resume(returning: value)
      case .failure(let failure):
        resume(throwing: failure)
    }
  }
}
