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

import struct SafeContinuation.SafeContinuation
import struct Unsafe.UnsafeSendingBox

enum ImmediateCancellationState<Output>: ~Copyable {
  typealias Continuation = SafeContinuation<Output, Error>
  typealias OutputResultBox = UnsafeSendingBox<Result<Output, Error>>
  case initial
  case receivedContinuation(Continuation)
  case receivedOutput(OutputResultBox)
  case receivedCancellation
  case complete

  mutating func receiveContinuation(
    _ continuation: consuming sending Continuation
  ) {
    let next: Self
    switch self {
      case .initial:
        next = .receivedContinuation(continuation)
      case .receivedContinuation:
        fatalError()
      case .receivedOutput(let outputBox):
        continuation.resume(with: outputBox.value)
        next = .complete
      case .receivedCancellation:
        continuation.resume(throwing: CancellationError())
        next = .complete
      case .complete:
        fatalError()
    }
    self = next
  }

  mutating func receiveOutput(
    _ outputResultBox: consuming sending OutputResultBox
  ) {
    let next: Self
    switch self {
      case .initial:
        next = .receivedOutput(outputResultBox)
      case .receivedContinuation(let continuation):
        continuation.resume(with: outputResultBox.value)
        next = .complete
      case .receivedOutput:
        fatalError()
      case .receivedCancellation:
        return
      case .complete:
        fatalError()
    }
    self = next
  }

  mutating func receivedCancellation() {
    let next: Self
    switch self {
      case .initial:
        next = .receivedCancellation
      case .receivedContinuation(let continuation):
        continuation.resume(throwing: CancellationError())
        next = .complete
      case .receivedOutput:
        return
      case .receivedCancellation:
        fatalError()
      case .complete:
        fatalError()
    }
    self = next
  }
}
