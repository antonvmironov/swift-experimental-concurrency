
@frozen
@usableFromInline
package struct UnsafeSendingBox<Value: ~Copyable>: ~Copyable, Sendable {
  @usableFromInline
  package nonisolated(unsafe) let value: Value

  @inlinable
  package init(_ value: consuming Value) {
    self.value = value
  }
}
