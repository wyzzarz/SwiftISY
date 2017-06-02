//
//  SwiftISYObject.swift
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
import SwiftCollection

public class SwiftISYHosts: SCOrderedSet<SwiftISYHost> {
  
  public struct SortId {
    
    public static let friendlyName = SwiftISYHosts.Sort.SortId("friendlyName")!
    public static let host = SwiftISYHosts.Sort.SortId("host")!
    
  }
  
  public required init() {
    super.init()
    sorting.sortId = SortId.friendlyName
    sorting.add(SortId.friendlyName) { (h1, h2) -> Bool in
      return h1.friendlyName.compare(h2.friendlyName) == .orderedAscending
    }
    sorting.add(SortId.host) { (h1, h2) -> Bool in
      return h1.host.compare(h2.host) == .orderedAscending
    }
  }
  
  public required init(json: AnyObject) throws {
    try super.init(json: json)
  }

  override open func load(jsonObject json: AnyObject) throws -> AnyObject? {
    if let array = json as? [AnyObject] {
      for item in array {
        try add(SwiftISYHost(json: item))
      }
    }
    return json
  }
  
  /// Returns an existing host from the collection if it matches this host.  Otherwise returns
  /// the supplied host.
  ///
  /// - Parameter host: Host to be located.
  /// - Returns: Existing host from collection; or provided host if not found.
  public func existing(_ host: SwiftISYHost) -> SwiftISYHost {
    for h in self {
      if h.host == host.host && h.user == host.user { return h }
    }
    return host
  }
  
}

public class SwiftISYHost: SCDocument {
  
  /// Friendly name for the ISY series device.
  public var friendlyName = ""
  
  /// Host to connect to (e.g. "http://[host]/rest/...").  This can be a host name that can be
  /// found on your local network or Internet.  Or an IP address.
  public var host = ""
  
  /// An alternative host to connect to.  In the event that the specified host is not reachable,
  /// then an attempt will be made to the alternative host.
  ///
  /// A situation where this can be used is for a host defined in a private network.  And the same
  /// host can be accessed over the Internet via port forwarding through a firewall.
  ///
  /// - Note: This is currently not implemented in SwiftISYRequest.
  public var alternativeHost = ""
  
  /// Username for authentication.
  public var user = ""
  
  /// Returns a password for authentication.
  ///
  /// This can be:
  ///   * The password used when initializing the host object.
  ///   * A password provided from `providePassword()`.
  ///   * Or an empty string if there is no password.
  public var password: String {
    // return this password
    if _password != nil && _password!.characters.count > 0 { return _password! }
    
    // otherwise try the password provider
    guard let closure = SwiftISYHost._providePassword else { return "" }
    return closure(self)
  }
  fileprivate var _password: String?
  
  ///
  /// Allows the client to return a password to be used for a host.
  ///
  static var _providePassword: ((SwiftISYHost) -> String)?
  public static func providePassword(_ closure: ((SwiftISYHost) -> String)?) {
    _providePassword = closure
  }
  
  ///
  /// Returns a basic HTTP authorization string where the user name and password are unencrypted
  /// base64 encoded text.
  ///
  /// - Returns: `authorization` as "Basic Base64(user:pasword)" or nil if it could not be
  /// generated. `error` if authorization could not be generated; nil otherwise.
  ///
  public func authorization() -> (authorization: String?, error: SwiftISY.RequestError?) {
    let user = self.user
    if user.characters.count == 0 { return (nil, SwiftISY.RequestError(kind: .invalidUser)) }
    
    let password = self.password
    if password.characters.count == 0 { return (nil, SwiftISY.RequestError(kind: .invalidPassword)) }
    
    let userPassword = String(format: "%@:%@", user, password)
    guard let userPasswordData = userPassword.data(using: String.Encoding.utf8) else { return (nil, SwiftISY.RequestError(kind: .invalidCredential)) }
    let encoded = userPasswordData.base64EncodedString()
    return ("Basic \(encoded)", nil)
  }
  
  ///
  /// Initializes a `SwiftISYHost` object with the specified hostname, username and password.
  ///
  /// - Parameters:
  ///   - id: Optional id.
  ///   - host: A host name or IP address.
  ///   - user: A username for authentication.
  ///   - password: Optional password for authentication.
  public convenience init(id: SwiftCollection.Id = 0, host: String, user: String, password: String? = nil, friendlyName: String? = nil) {
    self.init(id: id)
    self.host = host
    self.user = user
    _password = password
    if let friendlyName = friendlyName { self.friendlyName = friendlyName }
  }
  
  open override func jsonObject(willSerializeProperty label: String, value: Any) -> (newLabel: String, newValue: Any?) {
    guard label == Keys.password else { return (label, value) }
    return (label, nil)
  }
  
  open override func load(propertyWithName name: String, currentValue: Any, potentialValue: Any, json: AnyObject) {
    super.load(propertyWithName: name, currentValue: currentValue, potentialValue: potentialValue, json: json)
    
    // get json as a dictionary
    guard let dict = json as? [String: Any] else { return }
    
    // get value for this property, ignore any non-String values
    guard let value = dict[name] as? String else { return }
    
    // apply value for property
    switch name {
    case Keys.friendlyName: friendlyName = value
    case Keys.host: host = value
    case Keys.alternativeHost: alternativeHost = value
    case Keys.user: user = value
    case Keys.password: _password = value
    default: break
    }
  }
  
}

extension SwiftISYHost.Keys {
  
  public static let friendlyName = "friendlyName"
  public static let host = "host"
  public static let alternativeHost = "alternativeHost"
  public static let user = "user"
  public static let password = "_password"
  
}
