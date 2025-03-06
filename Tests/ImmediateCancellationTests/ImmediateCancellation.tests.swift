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

@testable import ImmediateCancellation

private let numberOfIterations = 1_000

@Test(
  "[withImmediateCancellation] Successfully returning a value",
  arguments: SimulatedOperation.allCases
)
func success(operation: SimulatedOperation) async throws {
  await withThrowingTaskGroup { group in
    for index in 0..<numberOfIterations {
      group.addTask {
        let value = try await withImmediateCancellation {
          switch operation {
            case .none: break
            case .yield: await Task.yield()
            case .sleep:
              try await ContinuousClock().sleep(for: .milliseconds(100))
          }
          return index
        }
        #expect(value == index)
      }
    }
  }
}

@Test(
  "[withImmediateCancellation] Throwing an error",
  arguments: SimulatedOperation.allCases
)
func failure(operation: SimulatedOperation) async throws {
  await withThrowingTaskGroup { group in
    for index in 0..<numberOfIterations {
      group.addTask {
        await #expect(throws: TestFailure.self) {
          let value: Int = try await withImmediateCancellation {
            switch operation {
              case .none: break
              case .yield: await Task.yield()
              case .sleep:
                try await ContinuousClock().sleep(for: .milliseconds(100))
            }
            throw TestFailure.testCode
          }
          #expect(value == index)
        }
      }
    }
  }
}

@Test("[withImmediateCancellation] Early cancellation")
func earlyCancellation() async throws {
  await withThrowingTaskGroup { group in
    for index in 0..<numberOfIterations {
      group.addTask {
        let task: Task<Void, Error> = Task {
          try await ContinuousClock().sleep(for: .milliseconds(100))
          let value: Int = try await withImmediateCancellation {
            try await ContinuousClock().sleep(for: .milliseconds(100))
            return index
          }
          #expect(value == index)
        }
        task.cancel()
        await #expect(throws: CancellationError.self) {
          try await task.value
        }
      }
    }
  }
}


@Test("[withImmediateCancellation] Late cancellation")
func lateCancellation() async throws {
  await withThrowingTaskGroup { group in
    for index in 0..<numberOfIterations {
      group.addTask {
        let task: Task<Void, Error> = Task {
          let value: Int = try await withImmediateCancellation {
            try await ContinuousClock().sleep(for: .milliseconds(100))
            return index
          }
          #expect(value == index)
        }
        task.cancel()
        await #expect(throws: CancellationError.self) {
          try await task.value
        }
      }
    }
  }
}

// MARK: -

enum TestFailure: Error {
  case testCode
}

enum SimulatedOperation: Sendable, CaseIterable {
  case none
  case yield
  case sleep
}
