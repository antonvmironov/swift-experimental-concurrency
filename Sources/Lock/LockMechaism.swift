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

import struct os.os_unfair_lock
import func os.os_unfair_lock_lock
import struct os.os_unfair_lock_t
import func os.os_unfair_lock_trylock
import func os.os_unfair_lock_unlock

@usableFromInline
struct LockMechaism: Sendable, ~Copyable {
  @usableFromInline
  nonisolated(unsafe) let _lock = os_unfair_lock_t.allocate(capacity: 1)

  @inlinable
  init() {
    _lock.initialize(to: .init())
  }

  @inlinable
  func lock() {
    os_unfair_lock_lock(_lock)
  }

  @inlinable
  func tryLock() -> Bool {
    os_unfair_lock_trylock(_lock)
  }

  @inlinable
  func unlock() {
    os_unfair_lock_unlock(_lock)
  }

  deinit {
    _lock.deinitialize(count: 1)
    _lock.deallocate()
  }
}
