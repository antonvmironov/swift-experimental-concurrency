import Dispatch
import Synchronization
import Testing

@testable import ImmediateCancellation

private let numberOfIterations = 1_000

@Test func testImmediateOutput() async throws {
  await withThrowingTaskGroup { group in
    for index in 0..<numberOfIterations {
      group.addTask {
        let value = try await withImmediateCancellation {
          index
        }
        #expect(value == index)
      }
    }
  }
}

@Test func testImmediateFailure() async throws {
  await withThrowingTaskGroup { group in
    for index in 0..<numberOfIterations {
      group.addTask {
        await #expect(throws: TestFailure.self) {
          let value: Int = try await withImmediateCancellation {
            throw TestFailure.testCode
          }
          #expect(value == index)
        }
      }
    }
  }
}

enum TestFailure: Error {
  case testCode
}
