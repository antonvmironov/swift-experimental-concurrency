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

/// Invokes the passed in closure with a safe continuation for the current task.
///
/// The body of the closure executes synchronously on the calling task,
/// and once it returns the calling task is suspended.
/// It is possible to immediately resume the task, or escape the continuation
/// in order to complete it afterwards, which will then resume
/// the suspended task.
///
/// You SHOULD invoke the continuation's `resume` method exactly once.
@inlinable
public func withSafeContinuation<Success>(
  isolation: isolated (any Actor)? = #isolation,
  fallback: sending Success,
  _ body: (SafeContinuation<Success, Never>) -> Void
) async -> sending Success {
  let box = UnsafeSendingBox(Result<Success, Never>.success(fallback))

  let success = await withUnsafeContinuation(
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
