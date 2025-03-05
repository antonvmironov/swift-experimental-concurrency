import struct Unsafe.UnsafeSendingBox
import struct Lock.Lock
import struct Lock.unlock

@inlinable public func withSafeContinuation<T>(
  isolation: isolated (any Actor)? = #isolation,
  fallback: sending T,
  _ body: (SafeContinuation<T, Never>) -> Void
) async -> sending T {
  let box = UnsafeSendingBox(Result<T, Never>.success(fallback))
  return await withUnsafeContinuation(isolation: isolation) { unsafeContinuation in
    let safeContinuation = SafeContinuation(
      unsafeContinuation: unsafeContinuation,
      fallbackResultBox: UnsafeSendingBox(box.value)
    )
    body(safeContinuation)
  }
}

@inlinable public func withSafeThrowingContinuation<T>(
  isolation: isolated (any Actor)? = #isolation,
  fallbackResult: sending Result<T, Error> = .failure(CancellationError()),
  _ body: (SafeContinuation<T, Error>) -> Void
) async throws -> sending T {
  let box = UnsafeSendingBox(fallbackResult)
  return try await withUnsafeThrowingContinuation(isolation: isolation) { unsafeContinuation in
    let safeContinuation = SafeContinuation(
      unsafeContinuation: unsafeContinuation,
      fallbackResultBox: UnsafeSendingBox(box.value)
    )
    body(safeContinuation)
  }
}

public struct SafeContinuation<T, E: Error>: Sendable {
  @usableFromInline
  let _impl: Lock<_Impl>

  @inlinable
  init(
    unsafeContinuation: consuming sending UnsafeContinuation<T, E>,
    fallbackResultBox: consuming sending FallbackResultBox,
  ) {
    let impl = _Impl(
      unsafeContinuation: unsafeContinuation,
      fallbackResultBox: fallbackResultBox,
    )
    _impl = Lock(impl)
  }

  @inlinable
  public func resume(returning value: consuming sending T) {
    var impl = unlock(_impl)
    impl.value.resume(returning: value)
  }

  @inlinable
  public func resume(throwing error: consuming E) {
    var impl = unlock(_impl)
    impl.value.resume(throwing: error)
  }

  @inlinable
  public func resume(with result: consuming sending Result<T, E>) {
    switch result {
      case .success(let value):
        resume(returning: value)
      case .failure(let failure):
        resume(throwing: failure)
    }
  }
}

extension SafeContinuation {
  @usableFromInline
  typealias FallbackResultBox = UnsafeSendingBox<Result<T, E>>

  @usableFromInline
  struct _Impl: ~Copyable {
    @usableFromInline
    var _state: _State

    @usableFromInline
    let _fallbackResultBox: FallbackResultBox

    @inlinable
    init(
      unsafeContinuation: consuming sending UnsafeContinuation<T, E>,
      fallbackResultBox: consuming sending FallbackResultBox
    ) {
      _state = .suspended(unsafeContinuation)
      _fallbackResultBox = fallbackResultBox
    }

    deinit {
      if case .suspended(let continuation) = _state {
        continuation.resume(with: _fallbackResultBox.value)
      }
    }

    @inlinable
    mutating func resume(returning value: consuming sending T) {
      if case .suspended(let continuation) = _state {
        continuation.resume(returning: consume value)
        _state = .resumed
      }
    }

    @inlinable
    mutating func resume(throwing error: consuming E) {
      if case .suspended(let continuation) = _state {
        continuation.resume(throwing: consume error)
        _state = .resumed
      }
    }
  }

  @usableFromInline
  enum _State {
    case suspended(UnsafeContinuation<T, E>)
    case resumed
  }
}
