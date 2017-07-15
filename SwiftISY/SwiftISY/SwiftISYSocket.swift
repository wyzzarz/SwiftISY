//
//  SwiftISYSocket.swift
//
//  Copyright 2017 Warner Zee
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import Starscream

///
/// `SwiftISYSocket` utilizes WebSockets to listen to events from a host.
///
/// Receive messages by setting a handler with `setDidReceiveMessage()`.
///
public class SwiftISYSocket: WebSocketDelegate {
  
  /// Host to be connected to for this socket.
  public var host: SwiftISYHost? {
    return _host
  }
  fileprivate var _host: SwiftISYHost?
  
  /// Network connection to the host.
  fileprivate var _socket: WebSocket?

  /// Subscription id for the current connection.
  fileprivate var _subscriptionId: String = ""
  
  /// Message received from the WebSocket.
  public struct Message {
    
    /// Message position.
    public var sequence: Int = 0
    
    /// Time message was received from the host.  Since 1970.
    public var timestamp: TimeInterval = 0

    /// Address of node/group.
    public var address: String = ""
    
    /// Property being reported.
    public var control: String = ""
    
    /// Value for property.
    public var value: Int = 0
    
    /// Description for this message
    public var description: String {
      return String(describing: "SwiftISYSocket.Message(\(sequence)@\(timestamp),\"\(address)\",\"\(control)\"=\(value))")
    }
    
  }
  
  /// Set handler when receiving a message.
  ///
  /// - Parameter handler: Handler for message.
  public func setDidReceiveMessage(_ handler: @escaping (_ message: Message) -> Void) {
    _didReceiveMessage = handler
  }
  fileprivate var _didReceiveMessage: ((_ message: Message) -> Void)?
  
  /// Returns `true` if there is an open connection to the host.  `false` otherwise.
  public var isConnected: Bool {
    guard let socket = _socket else { return false }
    return socket.isConnected
  }
  fileprivate var isConnecting: Bool = false
  
  /// Creates an instance of `SwiftISYSocket` for this host.
  ///
  /// - Parameter host: Host to be connected.
  public init(_ host: SwiftISYHost) {
    // add host
    _host = host
  }
  
  /// Opens a web socket to the host.
  ///
  /// - Throws: `invalidHost` if there is no host or an address for the host.
  public func open(_ completion: ((_ success: Bool, _ error: Error?) -> Void)?) throws {
    // exit if we are already connecting to this host
    guard isConnecting == false else { return }

    // exit if we are already connected to this host
    guard _socket?.isConnected ?? false == false else { return }
    
    // ensure there is a host
    guard let host = _host else {
      let error = SwiftISY.RequestError(kind: .invalidHost)
      if let completion = completion { completion(false, error) }
      throw error
    }
    
    // get address for this host
    let address = host.host
    if address.characters.count == 0 {
      let error = SwiftISY.RequestError(kind: .invalidHost)
      if let completion = completion { completion(false, error) }
      throw error
    }

    // create socket - if necessary
    if _socket == nil {
      let socket = WebSocket(url: URL(string: "http://\(address)/rest/subscribe")!, protocols: ["ISYSUB"])
      socket.delegate = self
      _socket = socket
      
      // override settings for handshake
      socket.headers[SwiftISY.Headers.socketVersion] = "13"
      socket.headers[SwiftISY.Headers.origin] = "com.universal-devices.websockets.isy"
      
      // add authorization
      let (authorization, error) = host.authorization()
      if error != nil { throw error! }
      socket.headers[SwiftISY.Headers.authorization] = authorization
      
      socket.onConnect = {
        if let completion = completion { completion(true, nil) }
        self.isConnecting = false
      }
      
      socket.onDisconnect = { error in
        guard self.isConnecting else { return }
        if let completion = completion { completion(false, error) }
        self.isConnecting = false
      }
    }
    
    // connect to the host
    isConnecting = true
    _socket!.connect()
  }
  
  /// Disconnects WebSocket from the host.
  public func close() {
    guard let socket = _socket else { return }
    socket.disconnect()
    _socket = nil
    _subscriptionId = ""
    isConnecting = false
  }

  // -------------------------------------------------------------------------------------------------
  // MARK: - WebSocketDelegate
  // -------------------------------------------------------------------------------------------------
  
  public func websocketDidConnect(socket: WebSocket) {
    // nothing to do
  }
  
  public func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
    guard let error = error else { return }
    print("disconnected: (\(error.code))\(error.localizedDescription)")
  }
  
  public func websocketDidReceiveData(socket: WebSocket, data: Data) {
    // nothing to do
  }
  
  public func websocketDidReceiveMessage(socket: WebSocket, text: String) {
    // try event message
    if let message = Event(text) {
      // skip if we're not handling messages
      guard let handler = _didReceiveMessage else { return }
      // ensure this is for the current subscription
      guard message.subscriptionId == _subscriptionId else { return }
      // only hande messages for a node
      guard message.node.characters.count > 0 else { return }
      
      // send this message
      var msg = Message()
      msg.address = message.node
      msg.control = message.control
      msg.value = message.action
      msg.sequence = message.sequenceNumber
      msg.timestamp = message.timestamp
      handler(msg)
      
      return
    }
    
    // try initial subscription message
    if let message = Subscription(text) {
      _subscriptionId = message.subscriptionId
      return
    }
    
    // otherwise unhandled
    print("Unhandled Socket Message: \"\(text)\"")
  }
  
}

// -------------------------------------------------------------------------------------------------
// MARK: - Message
// -------------------------------------------------------------------------------------------------

/// `SocketMessage` parses XML messages sent from the host.
fileprivate class SocketMessage: NSObject, XMLParserDelegate {

  var parser: XMLParser?
  
  var attributes: [[String: String]] = []
  
  var texts: [String] = []
  
  var timestamp: TimeInterval = 0
  
  init?(_ text: String) {
    guard let data = text.data(using: .utf8) else { return nil }
    super.init()
    timestamp = Date().timeIntervalSince1970
    parser = XMLParser(data: data)
    parser!.delegate = self
    parser!.parse()
  }
  
  func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
    attributes.append(attributeDict)
    texts.append("")
  }
  
  func parser(_ parser: XMLParser, foundCharacters string: String) {
    guard var text = texts.popLast() else { return }
    text += string
    texts.append(text)
  }
  
  func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
    let attributes = self.attributes.popLast() ?? [:]
    let text = texts.popLast() ?? ""
    self.parser(parser, didEndElement: elementName, attributes: attributes, text: text)
  }

  func parser(_ parser: XMLParser, didEndElement elementName: String, attributes: [String : String], text: String) {
    // nothing to do
  }
  
}

/// Subscription response message from the host.
fileprivate class Subscription: SocketMessage {
  
  var subscriptionId: String = ""
  
  var duration: Int = 0
  
  override init?(_ text: String) {
    guard text.hasPrefix("<?xml version=\"1.0\" encoding=\"UTF-8\"?><SubscriptionResponse>") else { return nil }
    super.init(text)
  }
  
  override func parser(_ parser: XMLParser, didEndElement elementName: String, attributes: [String : String], text: String) {
    switch elementName {
    case SwiftISY.Elements.subscriptionId: subscriptionId = text
    case SwiftISY.Elements.duration: duration = Int(text) ?? 0
    default: break
    }
  }
  
  override var description: String {
    return String(describing: "Subscription(SID:\"\(subscriptionId)\", Duration:\(duration))")
  }
  
}

/// Event message from the host.
fileprivate class Event: SocketMessage {
  
  var sequenceNumber: Int = 0
  
  var subscriptionId: String = ""
  
  var control: String = ""
  
  var action: Int = 0
  
  var node: String = ""
  
  var info: String = ""
  
  var status: Int = 0
 
  override init?(_ text: String) {
    guard text.hasPrefix("<?xml version=\"1.0\"?><Event ") else { return nil }
    super.init(text)
  }
  
  override func parser(_ parser: XMLParser, didEndElement elementName: String, attributes: [String : String], text: String) {
    switch elementName {
    case SwiftISY.Elements.event:
      sequenceNumber = Int(attributes[SwiftISY.Attributes.sequenceNumber] ?? "") ?? 0
      subscriptionId = attributes[SwiftISY.Attributes.subscriptionId] ?? ""
    case SwiftISY.Elements.control: control = text
    case SwiftISY.Elements.action: action = Int(text) ?? 0
    case SwiftISY.Elements.node: node = text
    default: break
    }
  }
  
  override var description: String {
    return String(describing: "Event(Node:\"\(node)\", Action:\"\(action)\", Control:\"\(control)\")")
  }

}
