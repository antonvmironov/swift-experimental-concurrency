import struct os.os_unfair_lock
import func os.os_unfair_lock_lock
import struct os.os_unfair_lock_t
import func os.os_unfair_lock_trylock
import func os.os_unfair_lock_unlock

@usableFromInline
struct LockMechaism: Sendable, ~Copyable {
  @usableFromInline
  nonisolated(unsafe) let _lock = os_unfair_lock_t.allocate(capacity: 1)

  @inlinable
  init() {
    _lock.initialize(to: .init())
  }

  @inlinable
  func lock() {
    os_unfair_lock_lock(_lock)
  }

  @inlinable
  func tryLock() -> Bool {
    os_unfair_lock_trylock(_lock)
  }

  @inlinable
  func unlock() {
    os_unfair_lock_unlock(_lock)
  }

  deinit {
    _lock.deinitialize(count: 1)
    _lock.deallocate()
  }
}
