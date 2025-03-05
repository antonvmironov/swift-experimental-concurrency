import Dispatch
import Synchronization
import Testing

@testable import Lock

private let numberOfIterations = 1_000_000

@Test func testAtomics() {
  let lockedCounter = Atomic(0)
  DispatchQueue.concurrentPerform(iterations: numberOfIterations) {
    iterationIndex in
    lockedCounter.add(1, ordering: .sequentiallyConsistent)
  }
  #expect(
    numberOfIterations == lockedCounter.load(ordering: .sequentiallyConsistent))
}

@Test func testLock() {
  let lockedCounter = Lock(0)
  DispatchQueue.concurrentPerform(iterations: numberOfIterations) {
    iterationIndex in
    var unlockedCounter = unlock(lockedCounter)
    unlockedCounter.value += 1
  }
  #expect(numberOfIterations == lockedCounter.value)
}

// @Test func testTryLock() {
//   let lockedCounter = Lock(0)
//   DispatchQueue.concurrentPerform(iterations: numberOfIterations) { iterationIndex in
//     do {
//       var unlockedCounter = try tryUnlock(lockedCounter)
//       unlockedCounter.value += 1
//     } catch {}
//   }
//   #expect(numberOfIterations >= lockedCounter.value)
// }
