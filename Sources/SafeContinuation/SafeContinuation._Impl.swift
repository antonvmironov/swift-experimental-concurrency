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

extension SafeContinuation {
  @usableFromInline
  struct _Impl: ~Copyable {
    @usableFromInline
    var _state: _State

    @usableFromInline
    let _fallbackResultBox: FallbackResultBox

    @inlinable
    init(
      unsafeContinuation: consuming sending UnsafeContinuation<T, E>,
      fallbackResultBox: consuming sending FallbackResultBox
    ) {
      _state = .suspended(unsafeContinuation)
      _fallbackResultBox = fallbackResultBox
    }

    deinit {
      if case .suspended(let continuation) = _state {
        continuation.resume(with: _fallbackResultBox.value)
      }
    }

    @inlinable
    mutating func resume(returning value: consuming sending T) {
      if case .suspended(let continuation) = _state {
        continuation.resume(returning: consume value)
        _state = .resumed
      }
    }

    @inlinable
    mutating func resume(throwing error: consuming E) {
      if case .suspended(let continuation) = _state {
        continuation.resume(throwing: consume error)
        _state = .resumed
      }
    }
  }

  @usableFromInline
  enum _State {
    case suspended(UnsafeContinuation<T, E>)
    case resumed
  }
}
