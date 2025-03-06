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

import Dispatch
import Synchronization
import Testing

@testable import Lock

@Test func lockInClass() {

  // EXAMPLE BEGIN
  typealias Key = String
  typealias Resource = String
  final class Manager: Sendable {
    private let lockedCache = Lock<[Key: Resource]>([:])

    init() {}

    func saveResource(_ resource: Resource, as key: Key) {
      var unlockedCache = unlock(lockedCache)
      unlockedCache.state[key] = resource
    }

    func loadResource(for key: Key) -> Resource? {
      let unlockedCache = unlock(lockedCache)
      return unlockedCache.state[key]
    }
  }
  // EXAMPLE END

  let manager = Manager()
  DispatchQueue.concurrentPerform(iterations: numberOfIterations) {
    iterationIndex in
    let key: Key = "key \(iterationIndex)"
    let resource: Resource = "Resource \(iterationIndex)"
    manager.saveResource(resource, as: key)
  }

  DispatchQueue.concurrentPerform(iterations: numberOfIterations) {
    iterationIndex in
    let key: Key = "key \(iterationIndex)"
    let expectedResource: Resource = "Resource \(iterationIndex)"
    let actualResource = manager.loadResource(for: key)
    #expect(expectedResource == actualResource)
  }
}

private let numberOfIterations = 1_000
