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

///
/// Holds a collection of ISY objects returned from a request.
///
/// - responses: Array of responses (0 or more) from commands to the host.
/// - nodes: Array of nodes (0 or more) returned from the host.
/// - groups: Array of groups (0 or more) returned from the host.
/// - statuses: Array of statuses (0 or more) for nodes returned from the host.
///
public struct SwiftISYObjects {
  
  public var responses: [SwiftISYResponse] = []
  public var nodes: [SwiftISYNode] = []
  public var groups: [SwiftISYGroup] = []
  public var statuses: [String: SwiftISYStatus] = [:]
  
}

// -------------------------------------------------------------------------------------------------
// MARK: - Host
// -------------------------------------------------------------------------------------------------

public class SwiftISYHosts: SCOrderedSet<SwiftISYHost> {
  
  override open func load(jsonObject json: AnyObject) throws -> AnyObject? {
    if let array = json as? [AnyObject] {
      for item in array {
        try append(SwiftISYHost(json: item))
      }
    }
    return json
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
  public convenience init(id: SwiftCollection.Id = 0, host: String, user: String, password: String? = nil) {
    self.init(id: id)
    self.host = host
    self.user = user
    _password = password
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

// -------------------------------------------------------------------------------------------------
// MARK: - Node
// -------------------------------------------------------------------------------------------------

public class SwiftISYNodes: SCOrderedSet<SwiftISYNode> {

  override open func load(jsonObject json: AnyObject) throws -> AnyObject? {
    if let array = json as? [AnyObject] {
      for item in array {
        try append(SwiftISYNode(json: item))
      }
    }
    return json
  }

}

public class SwiftISYNode: SCDocument, SwiftISYParserProtocol {
  
  /// Flags for this node.  See NodeFlags.
  public var flags: SwiftISY.NodeFlags = []
  
  /// Address of the node.
  public var address = ""
  
  /// Friendly name.
  public var name = ""
  
  /// Address of the parent.
  public var parent = ""
  
  /// Defines device’s family (optional).
  public var family: UInt = 0
  
  /// Device type.
  public var type = ""
  
  /// `true` or `false`.
  public var enabled: Bool = false
  
  public var deviceClass: UInt = 0
  
  public var wattage: UInt = 0
  
  public var dcPeriod: UInt = 0
  
  /// Primary node address.
  public var pnode = ""
  
  public var elkId = ""
  
  public var property = ""
  
  public required convenience init(elementName: String, attributes: [String: String]) {
    self.init()
    if let flags = attributes[SwiftISY.Attributes.flag] { self.flags = SwiftISY.NodeFlags(rawValue: UInt8(flags) ?? 0) }
    if let address = attributes[SwiftISY.Attributes.id] { self.address = address }
  }

  public func update(elementName: String, attributes: [String : String], text: String = "") {
    switch elementName {
    case SwiftISY.Elements.address: address = text
    case SwiftISY.Elements.name: name = text
    case SwiftISY.Elements.parent: parent = text
    case SwiftISY.Elements.family: family = UInt(text) ?? 0
    case SwiftISY.Elements.type: type = text
    case SwiftISY.Elements.enabled: enabled = text == "true"
    case SwiftISY.Elements.deviceClass: deviceClass = UInt(text) ?? 0
    case SwiftISY.Elements.wattage: wattage = UInt(text) ?? 0
    case SwiftISY.Elements.dcPeriod: dcPeriod = UInt(text) ?? 0
    case SwiftISY.Elements.pnode: pnode = text
    case SwiftISY.Elements.elkId: elkId = text
    case SwiftISY.Elements.property: property = text
    default: break
    }
  }

  open override func load(propertyWithName name: String, currentValue: Any, potentialValue: Any, json: AnyObject) {
    super.load(propertyWithName: name, currentValue: currentValue, potentialValue: potentialValue, json: json)
    
    // get json as a dictionary
    guard let dict = json as? [String: Any] else { return }
    
    // get value for this property
    guard let value = dict[name] else { return }

    // apply value for property
    switch name {
    case Keys.flags:
      if let flagsDict = value as? [String: NSNumber] {
        flags = SwiftISY.NodeFlags(rawValue: flagsDict["rawValue"]?.uint8Value ?? 0)
      }
    case Keys.address: address = value as? String ?? ""
    case Keys.name: self.name = value as? String ?? ""
    case Keys.parent: parent = value as? String ?? ""
    case Keys.family: family = (value as? NSNumber)?.uintValue ?? 0
    case Keys.type: type = value as? String ?? ""
    case Keys.enabled: enabled = value as? Bool ?? false
    case Keys.deviceClass: deviceClass = (value as? NSNumber)?.uintValue ?? 0
    case Keys.wattage: wattage = (value as? NSNumber)?.uintValue ?? 0
    case Keys.dcPeriod: dcPeriod = (value as? NSNumber)?.uintValue ?? 0
    case Keys.pnode: pnode = value as? String ?? ""
    case Keys.elkId: elkId = value as? String ?? ""
    case Keys.property: property = value as? String ?? ""
    default: break
    }
  }

}

extension SwiftISYNode.Keys {
  
  public static let flags = "flags"
  public static let address = "address"
  public static let name = "name"
  public static let parent = "parent"
  public static let family = "family"
  public static let type = "type"
  public static let enabled = "enabled"
  public static let deviceClass = "deviceClass"
  public static let wattage = "wattage"
  public static let dcPeriod = "dcPeriod"
  public static let pnode = "pnode"
  public static let elkId = "elkId"
  public static let property = "property"
  
}

// -------------------------------------------------------------------------------------------------
// MARK: - Group
// -------------------------------------------------------------------------------------------------

public class SwiftISYGroups: SCOrderedSet<SwiftISYGroup> {
  
}

public class SwiftISYGroup: SCDocument, SwiftISYParserProtocol {
  
  /// Flags for this group.  See NodeFlags.
  public var flags: SwiftISY.NodeFlags = []
  
  /// Address of the group.
  public var address = ""
  
  /// Friendly name.
  public var name = ""
  
  /// Defines group's family (optional).
  public var family: UInt = 0
  
  public var deviceGroup: UInt = 0
  
  public var elkId = ""
  
  /// Devices (by address) that are responders in this group.
  public var responderIds: [String] = []
  
  /// Devices (by address) that are controllers in this group.
  public var controllerIds: [String] = []
  
  public required convenience init(elementName: String, attributes: [String: String]) {
    self.init()
    flags = SwiftISY.NodeFlags(rawValue: UInt8(attributes[SwiftISY.Attributes.flag] ?? "0") ?? 0)  }

  public func update(elementName: String, attributes: [String : String], text: String = "") {
    switch elementName {
    case SwiftISY.Elements.address: address = text
    case SwiftISY.Elements.name: name = text
    case SwiftISY.Elements.family: family = UInt(text) ?? 0
    case SwiftISY.Elements.deviceGroup: deviceGroup = UInt(text) ?? 0
    case SwiftISY.Elements.elkId: elkId = text
    case SwiftISY.Elements.link:
      let type = UInt(attributes[SwiftISY.Attributes.type] ?? "0")
      if type == SwiftISY.MemberTypes.controller.rawValue {
        controllerIds.append(text)
      } else {
        responderIds.append(text)
      }
    default: break
    }
  }

}

// -------------------------------------------------------------------------------------------------
// MARK: - Status
// -------------------------------------------------------------------------------------------------

public class SwiftISYStatuses: SCOrderedSet<SwiftISYStatus> {

}

public class SwiftISYStatus: SCDocument, SwiftISYParserProtocol {
  
  /// Value for this status having:
  ///
  /// * `0` for off
  /// * `255` for on
  /// * Or a value between `0` and `255`.
  public var value: UInt8 = 0
  
  /// Formatted text for the current value such as:
  ///
  /// * "On" when the value is `0`
  /// * "Off" when the value is `255`
  /// * "%" when the value is fractional
  public var formatted: String = ""
  
  /// Unit of measure for values such as:
  ///
  /// * "%/on/off" for a dimmable light source
  /// * "on/off" for a light switch
  /// * "degrees" for a thermostat
  public var unitOfMeasure: String = ""
  
  ///
  /// `canHandle` tests whether this XML element holds a status object.
  ///
  /// - Parameter elementName: Name for this XML element.  Must be "property".
  /// - Parameter attributes: Attributes for this XML element.  Must have a key "id" with a value.
  ///   "ST"
  ///
  /// - Returns: `true` if the element name and attributes requirements are satisfied; `false`
  ///   otherwise.
  ///
  static func canHandle(elementName: String, attributes: [String: String]) -> Bool {
    guard elementName == SwiftISY.Elements.property else { return false }
    guard let type = attributes[SwiftISY.Attributes.id] else { return false }
    return type == SwiftISY.PropertyTypes.status
  }

  public required convenience init(elementName: String, attributes: [String: String]) {
    self.init()
    value = UInt8(attributes[SwiftISY.Attributes.value] ?? "0") ?? 0
    if let formatted = attributes[SwiftISY.Attributes.formatted] { self.formatted = formatted }
    if let unitOfMeasure = attributes[SwiftISY.Attributes.unitsOfMeasure] { self.unitOfMeasure = unitOfMeasure }
  }
  
  public func update(elementName: String, attributes: [String : String], text: String = "") {
    switch elementName {
    default: break
    }
  }
  
}

// -------------------------------------------------------------------------------------------------
// MARK: - Response
// -------------------------------------------------------------------------------------------------

public class SwiftISYResponses: SCOrderedSet<SwiftISYResponse> {
  
}

public class SwiftISYResponse: SCDocument, SwiftISYParserProtocol {
  
  /// Whether the command was successfuly executed.
  public var succeeded = false
  
  /// Status code for the command.
  public var status: SwiftISY.HttpStatusCodes?

  public required convenience init(elementName: String, attributes: [String: String]) {
    self.init()
    succeeded = attributes[SwiftISY.Attributes.succeeded] ?? "false" == "true"
  }
  
  public func update(elementName: String, attributes: [String : String], text: String = "") {
    switch elementName {
    case SwiftISY.Elements.status: status = SwiftISY.HttpStatusCodes(rawValue: Int(text) ?? 0)
    default: break
    }
  }

}
