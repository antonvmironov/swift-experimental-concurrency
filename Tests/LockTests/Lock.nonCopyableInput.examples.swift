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

import Dispatch
import Synchronization
import Testing

@testable import Lock

#if false

@Test func noncopyableInputForLock() {
  struct Input: ~Copyable {
    var content: String
  }

  struct Consumer: ~Copyable {
    var log = [String]()

    mutating func consume(input: consuming Input) {
      log.append(input.content)
      _ = consume input
    }
  }

  // EXAMPLE BEGIN
  let lockedConsumer = Lock(Consumer())
  let input = Input(content: "first")
  // error: noncopyable 'input' cannot be consumed
  // when captured by an escaping closure
  lockedConsumer.withLock { consumer in
    consumer.consume(input: input)
  }
  // EXAMPLE END

  lockedConsumer.withLock { consumer in
    #expect(consumer.log == ["first"])
  }
}

@Test func noncopyableInputForMutex() {
  struct Input: ~Copyable {
    var content: String
  }

  struct Consumer: ~Copyable {
    var log = [String]()

    mutating func consume(input: consuming Input) {
      log.append(input.content)
      _ = consume input
    }
  }

  // EXAMPLE BEGIN
  let lockedConsumer = Mutex(Consumer())
  let input = Input(content: "first")
  // error: noncopyable 'input' cannot be consumed
  // when captured by an escaping closure
  lockedConsumer.withLock { consumer in
    consumer.consume(input: input)
  }
  // EXAMPLE END

  lockedConsumer.withLock { consumer in
    #expect(consumer.log == ["first"])
  }
}

#endif

@Test func noncopyableInputForLock() {
  struct Input: ~Copyable {
    var content: String
  }

  struct Consumer: ~Copyable {
    var log = [String]()

    mutating func consume(input: consuming Input) {
      log.append(input.content)
      _ = consume input
    }
  }

  // EXAMPLE BEGIN
  let lockedConsumer = Lock(Consumer())
  let input = Input(content: "first")
  var unlockedConsumer: unlock<Consumer>

  unlockedConsumer = unlock(lockedConsumer)
  unlockedConsumer.state.consume(input: input)
  _ = consume unlockedConsumer
  // EXAMPLE END

  unlockedConsumer = unlock(lockedConsumer)
  #expect(unlockedConsumer.state.log == ["first"])
}
