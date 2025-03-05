import Dispatch
import Synchronization
import Testing

@testable import SafeContinuation

private let numberOfIterations = 1_000

@Test func testNormalResumeOfSafeContinuation() async {
  await withTaskGroup { group in
    for index in 0..<numberOfIterations {
      group.addTask {
        let value: Int = await withSafeContinuation(fallback: -1) { continuation in
          for _ in 0..<10 {
            continuation.resume(returning: index)
          }
        }
        #expect(value == index)
      }
    }
  }
}
