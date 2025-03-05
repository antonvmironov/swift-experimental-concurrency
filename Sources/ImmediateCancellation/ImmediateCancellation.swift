import struct Lock.Lock
import struct Lock.unlock
import struct SafeContinuation.SafeContinuation
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
        var unlockedState = unlock(lockedState)
        unlockedState.value.receiveContinuation(continuation)
      }

      do {
        let output = try await operation()
        var unlockedState = unlock(lockedState)
        unlockedState.value.receiveOutput(UnsafeSendingBox(.success(output)))
        return output
      } catch {
        var unlockedState = unlock(lockedState)
        unlockedState.value.receiveOutput(UnsafeSendingBox(.failure(error)))
        throw error
      }
    },
    onCancel: {
      var unlockedState = unlock(lockedState)
      unlockedState.value.receivedCancellation()
    },
    isolation: isolation,
  )
}

enum ImmediateCancellationState<Output>: ~Copyable {
  typealias Continuation = SafeContinuation<Output, Error>
  typealias OutputResultBox = UnsafeSendingBox<Result<Output, Error>>
  case initial
  case receivedContinuation(Continuation)
  case receivedOutput(OutputResultBox)
  case receivedCancellation
  case complete

  mutating func receiveContinuation(_ continuation: consuming sending Continuation) {
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

  mutating func receiveOutput(_ outputResultBox: consuming sending OutputResultBox) {
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
