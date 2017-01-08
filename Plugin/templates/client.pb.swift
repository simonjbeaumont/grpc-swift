/*
 * DO NOT EDIT.
 *
 * Generated by the protocol buffer compiler.
 * Source: {{ protoFile.name }}
 *
 */

/*
 *
 * Copyright 2016, Google Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

import Foundation
import gRPC
//-{% for service in protoFile.service %}

/// Type for errors thrown from generated client code.
public enum {{ .|clienterror:protoFile,service }} : Error {
  case endOfStream
  case invalidMessageReceived
  case error(c: CallResult)
}
//-{% for method in service.method %}
//-{% if not method.clientStreaming and not method.serverStreaming %}
//-{% include "client-call-unary.swift" %}
//-{% endif %}
//-{% if not method.clientStreaming and method.serverStreaming %}
//-{% include "client-call-serverstreaming.swift" %}
//-{% endif %}
//-{% if method.clientStreaming and not method.serverStreaming %}
//-{% include "client-call-clientstreaming.swift" %}
//-{% endif %}
//-{% if method.clientStreaming and method.serverStreaming %}
//-{% include "client-call-bidistreaming.swift" %}
//-{% endif %}
//-{% endfor %}

// Call methods of this class to make API calls.
public class {{ protoFile.package|capitalize }}_{{ service.name }}Service {
  private var channel: Channel

  /// This metadata will be sent with all requests.
  public var metadata : Metadata

  /// This property allows the service host name to be overridden.
  /// For example, it can be used to make calls to "localhost:8080" 
  /// appear to be to "example.com".
  public var host : String {
    get {
      return self.channel.host
    }
    set {
      self.channel.host = newValue
    }
  }

  /// Create a client that makes insecure connections.
  public init(address: String) {
    gRPC.initialize()
    channel = Channel(address:address)
    metadata = Metadata()
  }

  /// Create a client that makes secure connections.
  public init(address: String, certificates: String?, host: String?) {
    gRPC.initialize()
    channel = Channel(address:address, certificates:certificates, host:host)
    metadata = Metadata()
  }

  //-{% for method in service.method %}
  //-{% if not method.clientStreaming and not method.serverStreaming %}
  // Synchronous. Unary.
  public func {{ method.name|lowercase }}(_ request: {{ method|input }}) throws -> {{ method|output }} {
    return try {{ .|call:protoFile,service,method }}(channel).run(request:request, metadata:metadata)
  }
  //-{% endif %}
  //-{% if not method.clientStreaming and method.serverStreaming %}
  // Asynchronous. Server-streaming.
  // Send the initial message.
  // Use methods on the returned object to get streamed responses.
  public func {{ method.name|lowercase }}(_ request: {{ method|input }}) throws -> {{ .|call:protoFile,service,method }} {
    return try {{ .|call:protoFile,service,method }}(channel).run(request:request, metadata:metadata)
  }
  //-{% endif %}
  //-{% if method.clientStreaming and not method.serverStreaming %}
  // Asynchronous. Client-streaming.
  // Use methods on the returned object to stream messages and
  // to close the connection and wait for a final response.
  public func {{ method.name|lowercase }}() throws -> {{ .|call:protoFile,service,method }} {
    return try {{ .|call:protoFile,service,method }}(channel).run(metadata:metadata)
  }
  //-{% endif %}
  //-{% if method.clientStreaming and method.serverStreaming %}
  // Asynchronous. Bidirectional-streaming.
  // Use methods on the returned object to stream messages,
  // to wait for replies, and to close the connection.
  public func {{ method.name|lowercase }}() throws -> {{ .|call:protoFile,service,method }} {
    return try {{ .|call:protoFile,service,method }}(channel).run(metadata:metadata)
  }
  //-{% endif %}
  //-{% endfor %}
}
//-{% endfor %}