import struct Unsafe.UnsafeSendingBox

// swift-format-ignore: TypeNamesShouldBeCapitalized
public struct unlock<Value: ~Copyable>: ~Copyable, ~Escapable {
  @usableFromInline
  let _handle: LockHandle<Value>
  public var value: Value

  @inlinable
  public init(_ lock: borrowing Lock<Value>) {
    _handle = lock._handle
    value = _handle.lockAndTakeValue()
  }

  deinit {
    _handle.returnValueAndUnlock(UnsafeSendingBox(value))
  }
}
