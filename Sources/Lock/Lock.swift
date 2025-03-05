import struct Unsafe.UnsafeSendingBox

public struct Lock<Value: ~Copyable>: Sendable {
  @usableFromInline
  let _handle: LockHandle<Value>

  public init(_ value: consuming sending Value) {
    _handle = LockHandle(value)
  }
}

extension Lock where Value: Codable {
  var value: Value {
    let unlocked = unlock(self)
    return unlocked.value
  }
}

@usableFromInline
final class LockHandle<Value: ~Copyable>: Sendable {
  @usableFromInline
  nonisolated(unsafe) var _state: State
  @usableFromInline
  let _lockMechanism = LockMechaism()

  @inlinable
  init(_ value: consuming sending Value) {
    _state = .unlocked(value)
  }

  @inlinable
  func lockAndTakeValue() -> sending Value {
    _lockMechanism.lock()
    return _state.takeValue()
  }

  @inlinable
  func tryLockAndTakeValue() throws(CancellationError) -> sending Value {
    guard _lockMechanism.tryLock() else {
      throw CancellationError()
    }
    return _state.takeValue()
  }

  @inlinable
  func returnValueAndUnlock(_ boxedValue: consuming UnsafeSendingBox<Value>) {
    _state.returnValueBox(boxedValue)
    _lockMechanism.unlock()
  }

  @usableFromInline
  enum State: ~Copyable {
    case locked
    case unlocked(Value)

    @inlinable
    mutating func takeValue() -> sending Value {
      if case .unlocked(let unlockedValue) = consume self {
        self = .locked
        return unlockedValue
      } else {
        fatalError()
      }
    }

    @inlinable
    mutating func returnValueBox(
      _ boxedValue: consuming UnsafeSendingBox<Value>
    ) {
      if case .locked = consume self {
        self = .unlocked(boxedValue.value)
      } else {
        fatalError()
      }
    }
  }
}
