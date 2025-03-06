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

@testable import Unsafe

private let numberOfIterations = 1_000

// ⛔️
// error: sending 'input' risks causing data races
//     await sendingRecepient(input: input)
//           ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// @Test func testScenarioUnboxed() async {
//   let input = NonSendableElement(string: "input")
//   let output = await sendingBoundary() {
//     await sendingRecepient(input: input)
//   }

//   _ = output
// }

@Test func testScenarioBoxed() async {
  let inputBox = UnsafeSendingBox(NonSendableElement(string: "input"))
  let output = await sendingBoundary {
    await sendingRecepient(input: inputBox.value)
  }

  _ = output
}

private class NonSendableElement {
  let string: StaticString

  init(string: StaticString) {
    self.string = string
  }
}

private func sendingRecepient(
  input: consuming sending NonSendableElement
) async -> sending NonSendableElement {
  return NonSendableElement(string: "output")
}

private func sendingBoundary(
  operation: () async -> sending NonSendableElement
) async -> sending NonSendableElement {
  await operation()
}
