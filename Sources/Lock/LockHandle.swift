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

@usableFromInline
final class LockHandle<Value: ~Copyable>: Sendable {
  @usableFromInline
  nonisolated(unsafe) var _state: State
  @usableFromInline
  let _lockMechanism = LockMechaism()

  @inlinable
  init(_ value: consuming sending Value) {
    _state = .unlocked(value)
  }

  @inlinable
  func lockAndTakeValue() -> sending Value {
    _lockMechanism.lock()
    return _state.takeValue()
  }

  @inlinable
  func tryLockAndTakeValue() throws(CancellationError) -> sending Value {
    guard _lockMechanism.tryLock() else {
      throw CancellationError()
    }
    return _state.takeValue()
  }

  @inlinable
  func returnValueAndUnlock(_ boxedValue: consuming UnsafeSendingBox<Value>) {
    _state.returnValueBox(boxedValue)
    _lockMechanism.unlock()
  }

  @usableFromInline
  enum State: ~Copyable {
    case locked
    case unlocked(Value)

    @inlinable
    mutating func takeValue() -> sending Value {
      if case .unlocked(let unlockedValue) = consume self {
        self = .locked
        return unlockedValue
      } else {
        fatalError()
      }
    }

    @inlinable
    mutating func returnValueBox(
      _ boxedValue: consuming UnsafeSendingBox<Value>
    ) {
      if case .locked = consume self {
        self = .unlocked(boxedValue.value)
      } else {
        fatalError()
      }
    }
  }
}
