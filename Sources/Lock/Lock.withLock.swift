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

extension Lock where State: ~Copyable {
  /// Calls the given closure after acquiring the lock and then releases
  /// ownership.
  ///
  /// This method is equivalent to the following sequence of code:
  ///
  ///     lock.lock()
  ///     defer {
  ///       lock.unlock()
  ///     }
  ///     return try body(&value)
  ///
  /// - Warning: Recursive calls to `withLock` within the
  ///   closure parameter will cause a fatal error.
  ///
  /// - Parameter body: A closure with a parameter of `State`
  ///   that has exclusive mutating access to the value being stored within
  ///   this `Lock`. This closure is considered the critical section
  ///   as it will only be executed once the calling thread has
  ///   acquired the lock.
  ///
  /// - Returns: The return value, if any, of the `body` closure parameter.
  public func withLock<Ouput: ~Copyable, Failure: Error>(
    _ body: (inout sending State) throws(Failure) -> sending Ouput
  ) throws(Failure) -> sending Ouput {
    var unlocked = unlock(self)
    return try body(&unlocked.state)
  }

  #if ENABLE_TRY_LOCK

  // compiler is crashing on this one
  public func withLockIfAvailable<Ouput: ~Copyable, Failure: Error>(
    _ body: (inout sending State) throws(Failure) -> sending Ouput
  ) throws(Failure) -> sending Ouput? {
    guard var unlocked = try? tryUnlock(self) else { return nil }
    return try body(&unlocked.state)
  }

  #endif
}
