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

import struct Synchronization.Mutex
import struct Unsafe.UnsafeSendingBox

@usableFromInline
final class LockGuts<State: ~Copyable>: Sendable {
  @usableFromInline
  nonisolated(unsafe) var _impl: LockGutsState<State>
  @usableFromInline
  let _mutex = Mutex<Void>(())

  @inlinable
  init(_ state: consuming sending State) {
    _impl = .unlocked(state)
  }

  @inlinable
  func lockAndTakeState() -> sending State {
    _mutex._unsafeLock()
    return _impl.takeState()
  }

  @inlinable
  func tryLockAndTakeState() throws(CancellationError) -> sending State {
    guard _mutex._unsafeTryLock() else {
      throw CancellationError()
    }
    return _impl.takeState()
  }

  @inlinable
  func returnStateAndUnlock(_ boxedState: consuming UnsafeSendingBox<State>) {
    _impl.returnStateBox(boxedState)
    _mutex._unsafeUnlock()
  }
}
