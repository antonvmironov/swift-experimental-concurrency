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
