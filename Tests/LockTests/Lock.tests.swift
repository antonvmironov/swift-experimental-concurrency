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

@Test("[Atomic] Atomic counter increments as expected")
func testAtomics() {
  let lockedCounter = Atomic(0)
  DispatchQueue.concurrentPerform(iterations: numberOfIterations) {
    iterationIndex in
    lockedCounter.add(1, ordering: .sequentiallyConsistent)
  }
  #expect(
    lockedCounter.load(ordering: .sequentiallyConsistent) == numberOfIterations
  )
}

@Test("[Lock] Locked counter increments as expected with `unlock`")
func testLock() {
  let lockedCounter = Lock(0)
  DispatchQueue.concurrentPerform(iterations: numberOfIterations) {
    iterationIndex in
    var unlockedCounter = unlock(lockedCounter)
    unlockedCounter.state += 1
  }
  #expect(numberOfIterations == lockedCounter.state)
}

@Test("[Lock] No async unlock works as expected")
func unavailableFromAsync() async throws {
  let lockedCounter = Lock(0)

  _ = {
    var unlockedCounter = unlock(lockedCounter)
    unlockedCounter.state += 1
  }()

  try await ContinuousClock().sleep(for: .seconds(1))
  #expect(lockedCounter.state == 1)
}

#if ENABLE_TRY_LOCK
  // compiler crashes on this one
  @Test("[Lock] Locked counter increments as expected with `tryUnlock`")
  func testTryLock() {
    let lockedCounter = Lock(0)
    DispatchQueue.concurrentPerform(
      iterations: numberOfIterations
    ) { iterationIndex in
      do {
        var unlockedCounter = try tryUnlock(lockedCounter)
        unlockedCounter.state += 1
      } catch {}
    }
    #expect(lockedCounter.state <= numberOfIterations)
  }
#endif

private let numberOfIterations = 1_000_000
