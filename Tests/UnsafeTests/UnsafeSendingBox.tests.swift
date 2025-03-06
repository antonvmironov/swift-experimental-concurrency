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

#if DISABLE_UNSAFE_SENDING_BOX
// ⛔️
// error: sending 'input' risks causing data races
//     await sendingRecepient(input: input)
//           ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

@Test("[UnsafeSendingBox] Do not use UnsafeSendingBox")
func notBoxed() async {
  let value = NonSendableElement(string: "input")
  let output = await sendingBoundary {
    await sendingRecepient(input: value)
  }

  _ = output
}

#endif

@Test("[UnsafeSendingBox] A scenario UnsafeSendingBox was built for")
func boxed() async {
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

private let numberOfIterations = 1_000
