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

import struct Unsafe.UnsafeSendingBox

@inlinable
public func withSafeThrowingContinuation<Success>(
  isolation: isolated (any Actor)? = #isolation,
  fallbackResult: sending Result<Success, Error>,
  _ body: (SafeContinuation<Success, Error>) -> Void
) async throws -> sending Success {
  let box = UnsafeSendingBox(fallbackResult)

  let success = try await withUnsafeThrowingContinuation(
    isolation: isolation
  ) { unsafeContinuation in
    let safeContinuation = SafeContinuation(
      unsafeContinuation: unsafeContinuation,
      fallbackResultBox: UnsafeSendingBox(box.value)
    )
    body(safeContinuation)
  }

  return success
}
