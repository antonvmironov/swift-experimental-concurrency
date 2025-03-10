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

/// A synchronization primitive that protects shared mutable state.
///
/// The `Lock` type offers non-recursive exclusive access to the state
/// it is protecting by blocking threads attempting to acquire the lock.
/// Only one execution context at a time has access to the value stored
/// within the `Lock` allowing for exclusive access.
///
/// - Warning: Recursive calls to `withLock` within the
///   closure parameter will cause a fatal error.
///
///
/// An example use of `Lock` in a class used simultaneously by many
/// threads protecting a `Dictionary` value:
///
///     class Manager {
///       let lockedCache = Lock<[Key: Resource]>([:])
///
///       func saveResource(_ resource: Resource, as key: Key) {
///         var unlockedCache = unlock(lockedCache)
///         unlockedCache.state[key] = resource
///       }
///     }
///
public struct Lock<State: ~Copyable>: Sendable {
  @usableFromInline
  let _guts: LockGuts<State>

  public init(_ state: consuming sending State) {
    _guts = LockGuts(state)
  }
}

extension Lock where State: Copyable {
  /// A convenience readonly property that returns a copy of a `State`.
  public var state: State {
    let unlocked = unlock(self)
    return unlocked.state
  }
}
