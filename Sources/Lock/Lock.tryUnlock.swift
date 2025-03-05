import struct Unsafe.UnsafeSendingBox

// swift-format-ignore: TypeNamesShouldBeCapitalized
public struct tryUnlock<Value: ~Copyable>: ~Copyable, ~Escapable {
  @usableFromInline
  let _handle: LockHandle<Value>
  public var value: Value

  @inlinable
  public init(_ lock: borrowing Lock<Value>) throws(CancellationError) {
    _handle = lock._handle
    value = try _handle.tryLockAndTakeValue()
  }

  deinit {
    _handle.returnValueAndUnlock(UnsafeSendingBox(value))
  }
}
