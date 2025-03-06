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

import Synchronization

public struct Lock<Value: ~Copyable>: Sendable {
  @usableFromInline
  let _handle: LockHandle<Value>

  public init(_ value: consuming sending Value) {
    _handle = LockHandle(value)
  }
}

extension Lock {
  public func withLock<Ouput: ~Copyable, Failure: Error>(
    _ body: (inout sending Value) throws(Failure) -> sending Ouput
  ) throws(Failure) -> sending Ouput {
    var unlocked = unlock(self)
    return try body(&unlocked.value)
  }

// compiler is crashing on this one
// public func withLockIfAvailable<Ouput: ~Copyable, Failure: Error>(
//   _ body: (inout sending Value) throws(Failure) -> sending Ouput
// ) throws(Failure) -> sending Ouput? {
//   guard var unlocked = try? tryUnlock(self) else { return nil }
//   return try body(&unlocked.value)
// }
}

extension Lock where Value: Copyable {
  var value: Value {
    let unlocked = unlock(self)
    return unlocked.value
  }
}
