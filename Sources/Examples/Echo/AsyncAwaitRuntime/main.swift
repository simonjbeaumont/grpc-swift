/*
 * Copyright 2021, gRPC Authors All rights reserved.
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
import ArgumentParser
import EchoImplementation
import EchoModel
import GRPC
import GRPCSampleData
import NIO

// MARK: - Argument parsing

enum RPC: String, ExpressibleByArgument {
  case get
  case collect
  case expand
  case update
}

struct Echo: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "An example to run and call a simple gRPC service for echoing messages.",
    subcommands: [Server.self, Client.self]
  )

  struct Server: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Start a gRPC server providing the Echo service."
    )

    @Option(help: "The port to listen on for new connections")
    var port = 1234

    @Flag(help: "Whether TLS should be used or not")
    var tls = false

    func runAsync() async throws {
      let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
      defer {
        try! group.syncShutdownGracefully()
      }
      do {
        try await startEchoServer(group: group, port: self.port, useTLS: self.tls)
      } catch {
        print("Error running server: \(error)")
      }
    }
  }

  struct Client: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Calls an RPC on the Echo server woo."
    )

    @Option(help: "The port to connect to")
    var port = 1234

    @Flag(help: "Whether TLS should be used or not")
    var tls = false

    @Flag(help: "Whether interceptors should be used, see 'docs/interceptors-tutorial.md'.")
    var intercept = false

    @Option(help: "RPC to call ('get', 'collect', 'expand', 'update').")
    var rpc: RPC = .get

    @Option(help: "How many RPCs to do.")
    var iterations: Int = 1

    @Argument(help: "Message to echo")
    var message: String

    func runAsync() async throws {
      let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
      defer {
        try! group.syncShutdownGracefully()
      }

      let client = makeClient(
        group: group,
        port: self.port,
        useTLS: self.tls,
        useInterceptor: self.intercept
      )
      defer {
        try! client.channel.close().wait()
      }

      for _ in 0 ..< self.iterations {
        await callRPC(self.rpc, using: client, message: self.message)
      }
    }
  }
}

// MARK: - Server

func startEchoServer(group: EventLoopGroup, port: Int, useTLS: Bool) async throws {
  let builder: Server.Builder

  if useTLS {
    // We're using some self-signed certs here: check they aren't expired.
    let caCert = SampleCertificate.ca
    let serverCert = SampleCertificate.server
    precondition(
      !caCert.isExpired && !serverCert.isExpired,
      "SSL certificates are expired. Please submit an issue at https://github.com/grpc/grpc-swift."
    )

    builder = Server.secure(
      group: group,
      certificateChain: [serverCert.certificate],
      privateKey: SamplePrivateKey.server
    )
    .withTLS(trustRoots: .certificates([caCert.certificate]))
    print("starting secure server")
  } else {
    print("starting insecure server")
    builder = Server.insecure(group: group)
  }

  let server = try await builder.withServiceProviders([EchoAsyncProvider()])
    .bind(host: "localhost", port: port)
    .get()

  print("started server: \(server.channel.localAddress!)")

  // This blocks to keep the main thread from finishing while the server runs,
  // but the server never exits. Kill the process to stop it.
  try await server.onClose.get()
}

// MARK: - Client

func makeClient(
  group: EventLoopGroup,
  port: Int,
  useTLS: Bool,
  useInterceptor: Bool
) -> Echo_AsyncEchoClient {
  let builder: ClientConnection.Builder

  if useTLS {
    // We're using some self-signed certs here: check they aren't expired.
    let caCert = SampleCertificate.ca
    let clientCert = SampleCertificate.client
    precondition(
      !caCert.isExpired && !clientCert.isExpired,
      "SSL certificates are expired. Please submit an issue at https://github.com/grpc/grpc-swift."
    )

    builder = ClientConnection.secure(group: group)
      .withTLS(certificateChain: [clientCert.certificate])
      .withTLS(privateKey: SamplePrivateKey.client)
      .withTLS(trustRoots: .certificates([caCert.certificate]))
  } else {
    builder = ClientConnection.insecure(group: group)
  }

  // Start the connection and create the client:
  let connection = builder.connect(host: "localhost", port: port)

  return Echo_AsyncEchoClient(
    channel: connection,
    interceptors: useInterceptor ? ExampleClientInterceptorFactory() : nil
  )
}

func callRPC(_ rpc: RPC, using client: Echo_AsyncEchoClient, message: String) async {
  do {
    switch rpc {
    case .get:
      try await echoGet(client: client, message: message)
    case .collect:
      try await echoCollect(client: client, message: message)
    case .expand:
      try await echoExpand(client: client, message: message)
    case .update:
      try await echoUpdate(client: client, message: message)
    }
  } catch {
    print("\(rpc) RPC failed: \(error)")
  }
}

func echoGet(client: Echo_AsyncEchoClient, message: String) async throws {
  // Get is a unary call.
  let get = client.makeGetCall(.with { $0.text = message })
  print("get received: \(try await get.response.text)")
  print("status: \(await get.status)")
}

func echoCollect(client: Echo_AsyncEchoClient, message: String) async throws {
  // Split the messages and map them into requests
  let messages = message.components(separatedBy: " ").map { part in
    Echo_EchoRequest.with { $0.text = part }
  }

  let collect = client.makeCollectCall()

  // Spin off a task to send the requests...
  Task {
    for message in messages {
      try await Task.sleep(nanoseconds: 1_000_000_000)
      try await collect.sendMessage(message)
    }
    try await collect.sendEnd()
  }

  print("collect received: \(try await collect.response.text)")
  print("status: \(await collect.status)")
}

func echoCollectUsingAsyncSequenceOfRequests(client: Echo_AsyncEchoClient, message: String) async throws {
  // Create an AsyncSequence that yields messages
  let messageStream = AsyncStream(Echo_EchoRequest.self) { continuation in
    for part in message.components(separatedBy: " ") {
      continuation.yield(Echo_EchoRequest.with { $0.text = part })
    }
    continuation.finish()
  }

  // Collect is a client streaming call
  async let response = client.collect(requests: messageStream)
  print("collect received: \(try await response.text)")
}

func echoExpand(client: Echo_AsyncEchoClient, message: String) async throws {
  let expand = client.makeExpandCall(.with { $0.text = message })
  for try await response in expand.responseStream {
    print("expand received: \(response.text)")
  }
  print("status: \(await expand.status)")
}

func echoUpdate(client: Echo_AsyncEchoClient, message: String) async throws {
  // Split the messages and map them into requests
  let messages = message.components(separatedBy: " ").map { part in
    Echo_EchoRequest.with { $0.text = part }
  }

  let update = client.makeUpdateCall()

  // Here's an example of using async-let (even getting the response before the request was sent)
  print("** Getting response as async-let binding...")
  async let response = try await update.responseStream.first()!
  print("** Sending request using try-await...")
  try await update.sendMessage(.with { $0.text = "test" })
  print("-> request sent: test")
  print("<- update received: \(try await response.text)")

  // Here we spin up a task that sends requests after a delay...
  print("** Spawning task to send requests...")
  Task {
    for message in messages {
      try await Task.sleep(nanoseconds: 1_000_000_000)
      try await update.sendMessage(message)
      print("-> request sent: \(message.text)")
    }
    try await Task.sleep(nanoseconds: 1_000_000_000)
    try await update.sendEnd()
    print("-> sent end")
  }
  // ...and then wait on the responses...
  print("** Waiting on response stream...")
  for try await response in update.responseStream {
    print("<- update received: \(response.text)")
  }

  // Now let's end the call...
  print("<- update completed with status: \(await update.status.code)")
}

func echoUpdateUsingAsyncSequenceOfRequests(client: Echo_AsyncEchoClient, message: String) async throws {
  // Create an AsyncSequence that yields messages
  let messageStream = AsyncStream(Echo_EchoRequest.self) { continuation in
    for part in message.components(separatedBy: " ") {
      continuation.yield(Echo_EchoRequest.with { $0.text = part })
    }
    continuation.finish()
  }

  for try await response in client.update(requests: messageStream) {
    print("update received: \(response.text)")
  }
}

@main
struct MainApp {
    static func main() async {
        await Echo.main()
    }
}
