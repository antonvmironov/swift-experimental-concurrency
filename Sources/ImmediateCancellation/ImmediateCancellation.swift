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

public func withImmediateCancellation<Output>(
  operation: () async throws -> Output,
  isolation: isolated (any Actor)? = #isolation
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
