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
import Testing

@testable import SafeContinuation

private let numberOfIterations = 1_000

@Test func testNormalResumeOfSafeContinuation() async {
  await withTaskGroup { group in
    for index in 0..<numberOfIterations {
      group.addTask {
        let value: Int = await withSafeContinuation(fallback: -1) {
          continuation in
          for _ in 0..<10 {
            continuation.resume(returning: index)
          }
        }
        #expect(value == index)
      }
    }
  }
}
