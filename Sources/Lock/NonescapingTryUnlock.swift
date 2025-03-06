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

// swift-format-ignore: TypeNamesShouldBeCapitalized
public typealias tryUnlock = NonescapingTryUnlock

@available(*, noasync)
public struct NonescapingTryUnlock<
  State: ~Copyable
>: ~Copyable, ~Escapable {
  @usableFromInline
  let _guts: LockGuts<State>
  public var state: State

  @available(*, noasync)
  @inlinable
  public init(_ lock: borrowing Lock<State>) throws(CancellationError) {
    _guts = lock._guts
    state = try _guts.tryLockAndTakeState()
  }

  deinit {
    _guts.returnStateAndUnlock(UnsafeSendingBox(state))
  }
}
