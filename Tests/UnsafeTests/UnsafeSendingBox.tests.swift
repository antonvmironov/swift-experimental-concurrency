import Dispatch
import Synchronization
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
