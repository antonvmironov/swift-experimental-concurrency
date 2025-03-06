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

import struct Lock.Lock
import struct Lock.unlock
import func SafeContinuation.withSafeThrowingContinuation
import struct Unsafe.UnsafeSendingBox

/// Execute an asynchronous operation and immediately cancel when
/// the caller's context gets cancelled.
///
/// This differs from the operation cooperatively checking for cancellation
/// and reacting to it in that the cancellation error gets thrown immediately
/// on cancellation. For example, even if the operation is running code
/// that never checks for cancellation:
///
/// ```
/// await withImmediateCancellation {
///   var sum = 0
///   while condition {
///     sum += 1
///   }
///   return sum
/// } onCancel: {
///   // This onCancel closure might execute concurrently with the operation.
///   condition.cancel()
/// }
/// ```
///
/// ### Execution order and semantics
/// The `operation` closure is always invoked, even when the
/// `withImmediateCancellation(operation:isolation:)` method is called
/// from a task that was already cancelled.
public func withImmediateCancellation<Output>(
  isolation: isolated (any Actor)? = #isolation,
  operation: () async throws -> Output,
) async throws -> Output {
  let lockedState = Lock(ImmediateCancellationState<Output>.initial)
  return try await withTaskCancellationHandler(
    operation: {
      async let _ = withSafeThrowingContinuation(
        fallbackResult: .failure(CancellationError())
      ) { continuation in
        lockedState.withLock {
          $0.receiveContinuation(continuation)
        }
      }

      do {
        let output = try await operation()
        lockedState.withLock {
          $0.receiveOutput(UnsafeSendingBox(.success(output)))
        }
        return output
      } catch {
        lockedState.withLock {
          $0.receiveOutput(UnsafeSendingBox(.failure(error)))
        }
        throw error
      }
    },
    onCancel: {
      lockedState.withLock {
        $0.receivedCancellation()
      }
    },
    isolation: isolation,
  )
}
