# swift-experimental-concurrency
Experimental concurrency primitives for Swift.

## Lock

Similar to built-in `Mutex` but `Copyable` and `Sendable`.
Also has a API that helps to avoid following error

> error: sending 'value' risks causing data races

<details>
  <Summary>Example</Summary>

```swift
import struct Lock.Lock
import struct Lock.unlock

struct Input: ~Copyable { /* ... */ }

struct Consumer: ~Copyable {
  mutating func consume(input: consuming Input) { /* ... */ }
}

let lockedConsumer = Lock(Consumer())
let input = Input(content: "first")
var unlockedConsumer: unlock<Consumer>

// CRITICAL SECTION START
unlockedConsumer = unlock(lockedConsumer)
unlockedConsumer.state.consume(input: input)
_ = consume unlockedConsumer
// CRITICAL SECTION END
```

</details>
