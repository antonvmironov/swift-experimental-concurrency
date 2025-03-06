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
enum LockGutsState<State: ~Copyable>: ~Copyable {
  case locked
  case unlocked(State)

  @inlinable
  mutating func takeState() -> sending State {
    if case .unlocked(let unlockeState) = consume self {
      self = .locked
      return unlockeState
    } else {
      fatalError("Recursive locking is not allowed")
    }
  }

  @inlinable
  mutating func returnStateBox(
    _ boxedState: consuming UnsafeSendingBox<State>
  ) {
    if case .locked = consume self {
      self = .unlocked(boxedState.value)
    } else {
      fatalError("Recursive locking is not allowed")
    }
  }
}
