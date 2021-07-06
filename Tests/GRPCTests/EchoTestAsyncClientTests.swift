/*
 * Copyright 2020, gRPC Authors All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import EchoImplementation
import EchoModel
import GRPC
import NIO
import XCTest

class EchoTestAsyncClientTests: GRPCTestCase {
  private var group: MultiThreadedEventLoopGroup?
  private var server: Server?
  private var channel: ClientConnection?

  private func setUpServerAndChannel() throws -> ClientConnection {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    self.group = group

    let server = try Server.insecure(group: group)
      .withServiceProviders([EchoProvider()])
      .withLogger(self.serverLogger)
      .bind(host: "127.0.0.1", port: 0)
      .wait()

    self.server = server

    let channel = ClientConnection.insecure(group: group)
      .withBackgroundActivityLogger(self.clientLogger)
      .connect(host: "127.0.0.1", port: server.channel.localAddress!.port!)

    self.channel = channel

    return channel
  }

  override func tearDown() {
    if let channel = self.channel {
      XCTAssertNoThrow(try channel.close().wait())
    }
    if let server = self.server {
      XCTAssertNoThrow(try server.close().wait())
    }
    if let group = self.group {
      XCTAssertNoThrow(try group.syncShutdownGracefully())
    }

    super.tearDown()
  }

  // TODO: Add XCTAssertEqual helper that takes an async autoclosure...
  func testGetCall() throws { XCTAsyncTest {
    let channel = try self.setUpServerAndChannel()
    let client = Echo_AsyncEchoClient(channel: channel, defaultCallOptions: self.callOptionsWithLogger)

    let get = client.makeGetCall(.with { $0.text = "Hello" })

    let response = try await get.response
    XCTAssertEqual(response.text, "Swift echo get: Hello")
    let status = await get.status
    XCTAssert(status.isOk)
  } }

  func testGetCall_AsyncLetStatusBeforeRequest() throws { XCTAsyncTest {
    let channel = try self.setUpServerAndChannel()
    let client = Echo_AsyncEchoClient(channel: channel, defaultCallOptions: self.callOptionsWithLogger)

    let get = client.makeGetCall(.with { $0.text = "Hello" })
    async let status = get.status

    let response = try await get.response
    XCTAssertEqual(response.text, "Swift echo get: Hello")
    let status_ = await status
    XCTAssert(status_.isOk)
  } }

  func testCollectCall() throws { XCTAsyncTest {
    let channel = try self.setUpServerAndChannel()
    let client = Echo_AsyncEchoClient(channel: channel, defaultCallOptions: self.callOptionsWithLogger)

    let collect = client.makeCollectCall()

    for word in ["foo", "bar", "baz"] {
      try await collect.sendMessage(.with { $0.text = word })
    }
    try await collect.sendEnd()

    let response = try await collect.response
    XCTAssertEqual(response.text, "Swift echo collect: foo bar baz")
    let status = await collect.status
    XCTAssert(status.isOk)
  } }

  func testCollectCall_AsyncLetResponseAndStatusBeforeRequest() throws { XCTAsyncTest {
    let channel = try self.setUpServerAndChannel()
    let client = Echo_AsyncEchoClient(channel: channel, defaultCallOptions: self.callOptionsWithLogger)

    let collect = client.makeCollectCall()

    async let response = collect.response
    async let status = collect.status

    for word in ["foo", "bar", "baz"] {
      try await collect.sendMessage(.with { $0.text = word })
    }
    try await collect.sendEnd()

    let response_ = try await response
    XCTAssertEqual(response_.text, "Swift echo collect: foo bar baz")
    let status_ = await status
    XCTAssert(status_.isOk)
  } }

  func testExpandCall() throws { XCTAsyncTest {
    let channel = try self.setUpServerAndChannel()
    let client = Echo_AsyncEchoClient(channel: channel, defaultCallOptions: self.callOptionsWithLogger)

    let expand = client.makeExpandCall(.with { $0.text = "foo bar baz" })

    var numResponses = 0
    for try await response in expand.responseStream {
      XCTAssert(response.text.hasPrefix("Swift echo expand"))
      numResponses += 1
    }
    XCTAssertEqual(numResponses, 3)

    let status = await expand.status
    XCTAssert(status.isOk)
  } }

  func testUpdateCall_RequestsThenResponses() throws { XCTAsyncTest {
    let channel = try self.setUpServerAndChannel()
    let client = Echo_AsyncEchoClient(channel: channel, defaultCallOptions: self.callOptionsWithLogger)

    let update = client.makeUpdateCall()

    for word in ["foo", "bar", "baz"] {
      try await update.sendMessage(.with { $0.text = word })
    }
    try await update.sendEnd()

    var numResponses = 0
    for try await response in update.responseStream {
      XCTAssert(response.text.hasPrefix("Swift echo update"))
      numResponses += 1
    }

    let status = await update.status
    XCTAssert(status.isOk)
  } }

  func testUpdateCall_InterleavedRequestsAndResponses() throws { XCTAsyncTest {
    let channel = try self.setUpServerAndChannel()
    let client = Echo_AsyncEchoClient(channel: channel, defaultCallOptions: self.callOptionsWithLogger)

    let update = client.makeUpdateCall()

    // Spin up a task to send the requests with a delay before each one
    Task {
      let delay = TimeAmount.milliseconds(500)
      for word in ["foo", "bar", "baz"] {
        try await Task.sleep(nanoseconds: UInt64(delay.nanoseconds))
        try await update.sendMessage(.with { $0.text = word })
      }
        try await Task.sleep(nanoseconds: UInt64(delay.nanoseconds))
      try await update.sendEnd()
    }

    // ...and then wait on the responses...
    var numResponses = 0
    for try await response in update.responseStream {
      XCTAssert(response.text.hasPrefix("Swift echo update"))
      numResponses += 1
    }

    let status = await update.status
    XCTAssert(status.isOk)
  } }

  func testUpdateCall_ConcurrentTasksForRequestsAndResponses() throws { XCTAsyncTest {
    let channel = try self.setUpServerAndChannel()
    let client = Echo_AsyncEchoClient(channel: channel, defaultCallOptions: self.callOptionsWithLogger)

    let update = client.makeUpdateCall()

    actor TestResults {
      static var numResponses = 0
      static var numRequests = 0
    }

    // Send the requests and get responses in separate concurrent tasks and await the group.
    let _ = await withThrowingTaskGroup(of: Void.self) { taskGroup in
      // Send requests in a task, sleeping in between, then send end.
      taskGroup.addTask {
        let delay = TimeAmount.milliseconds(500)
        for word in ["foo", "bar", "baz"] {
          try await Task.sleep(nanoseconds: UInt64(delay.nanoseconds))
          try await update.sendMessage(.with { $0.text = word })
          print("Sent request: \(word)")
          TestResults.numRequests += 1
        }
        try await Task.sleep(nanoseconds: UInt64(delay.nanoseconds))
        print("Sending end")
        try await update.sendEnd()
      }
      // Get responses in a separate task.
      taskGroup.addTask {
        for try await response in update.responseStream {
          print("Got response: \(response.text)")
          TestResults.numResponses += 1
        }
      }
    }
    XCTAssertEqual(TestResults.numRequests, 3)
    XCTAssertEqual(TestResults.numResponses, 3)
  } }

  // MARK:- Test for the simple/safe wrappers

  func testGet() throws { XCTAsyncTest {
    let channel = try self.setUpServerAndChannel()
    let client = Echo_AsyncEchoClient(channel: channel, defaultCallOptions: self.callOptionsWithLogger)

    let response = try await client.get(.with { $0.text = "Hello" })
    XCTAssertEqual(response.text, "Swift echo get: Hello")
  } }

  func testCollect() throws { XCTAsyncTest {
    let channel = try self.setUpServerAndChannel()
    let client = Echo_AsyncEchoClient(channel: channel, defaultCallOptions: self.callOptionsWithLogger)

    // Artificially construct an AsyncSequence of requests.
    let requestStream = AsyncStream(Echo_EchoRequest.self) { continuation in
      for word in ["foo", "bar", "baz"] {
        continuation.yield(.with { $0.text = word })
      }
      continuation.finish()
    }

    let response = try await client.collect(requests: requestStream)
    XCTAssertEqual(response.text, "Swift echo collect: foo bar baz")
  } }

  func testExpand() throws { XCTAsyncTest {
    let channel = try self.setUpServerAndChannel()
    let client = Echo_AsyncEchoClient(channel: channel, defaultCallOptions: self.callOptionsWithLogger)

    var numResponses = 0
    for try await response in client.expand(.with { $0.text = "foo bar baz" }) {
      XCTAssert(response.text.hasPrefix("Swift echo expand"))
      numResponses += 1
    }

    XCTAssertEqual(numResponses, 3)
  } }

  func testUpdate() throws { XCTAsyncTest {
    let channel = try self.setUpServerAndChannel()
    let client = Echo_AsyncEchoClient(channel: channel, defaultCallOptions: self.callOptionsWithLogger)

    // Artificially construct an AsyncSequence of requests.
    let requestStream = AsyncStream(Echo_EchoRequest.self) { continuation in
      for word in ["foo", "bar", "baz"] {
        continuation.yield(.with { $0.text = word })
      }
      continuation.finish()
    }

    var numResponses = 0
    for try await response in client.update(requests: requestStream) {
      XCTAssert(response.text.hasPrefix("Swift echo update"))
      numResponses += 1
    }

    XCTAssertEqual(numResponses, 3)
  } }
}

public extension XCTestCase {
  /// Until we have an implementation for https://bugs.swift.org/browse/SR-14403
  func XCTAsyncTest(
    expectationDescription: String = "Async operation",
    timeout: TimeInterval = 3,
    file: StaticString = #file,
    line: Int = #line,
    operation: @escaping () async throws -> ()
  ) {
    let expectation = self.expectation(description: expectationDescription)
    Task {
      do { try await operation() }
      catch {
        XCTFail("Error thrown while executing async function @ \(file):\(line): \(error)")
        Thread.callStackSymbols.forEach{print($0)}
      }
      expectation.fulfill()
    }
    self.wait(for: [expectation], timeout: timeout)
  }
}
