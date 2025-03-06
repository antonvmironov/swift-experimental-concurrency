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

@inlinable public func withSafeThrowingContinuation<Output>(
  isolation: isolated (any Actor)? = #isolation,
  fallbackResult: sending Result<Output, Error> = .failure(CancellationError()),
  _ body: (SafeContinuation<Output, Error>) -> Void
) async throws -> sending Output {
  let box = UnsafeSendingBox(fallbackResult)

  let output = try await withUnsafeThrowingContinuation(
    isolation: isolation
  ) { unsafeContinuation in
    let safeContinuation = SafeContinuation(
      unsafeContinuation: unsafeContinuation,
      fallbackResultBox: UnsafeSendingBox(box.value)
    )
    body(safeContinuation)
  }

  return output
}
