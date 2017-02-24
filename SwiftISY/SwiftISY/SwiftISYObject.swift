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

///
/// Base class for ISY objects.
///
/// Supports XML functions used to parse results returned from the ISY host.  Supports JSON
/// functions for local storage.
///
public class SwiftISYObject {
  
  public enum PersistentStorage {
    case userDefaults
  }
  
  fileprivate init() {
    // nothing to do
  }
  
  ///
  /// Checks for valid values in an instance of this class.
  ///
  /// - Returns: `success` - `true` if the object has valid properties; `false` otherwise. `errors` - Array of `ValidationError` objects; or `nil`.
  public func validate() -> (success: Bool, errors: [ValidationError]?) {
    return (true, nil)
  }

  /*
   * XML Server Functions
   */
  
  ///
  /// Creates an instance of this class from an XML parser when an element is encountered.
  ///
  /// - Parameter elementName: Name for this XML element.
  /// - Parameter attributes: Attributes for this XML element.
  ///
  public init(elementName: String, attributes: [String: String]) {
    // nothing to do
  }
  
  ///
  /// Updates this object once the XML parser completes processing an element.
  ///
  /// - Parameter elementName: Name for this XML element.
  /// - Parameter attributes: Attributes for this XML element.
  /// - Parameter text: Text for this XML element.  Maybe be an empty string.
  ///
  public func update(elementName: String, attributes: [String: String], text: String) {
    // nothing to do
  }
  
  /*
   * JSON Local Storage
   */
  
  ///
  /// Creates an instance of this class from a JSON encoded string.
  ///
  /// - Parameter json: Json string to be loaded.
  ///
  public init(json: String) {
    load(json: json)
  }

  ///
  /// Creates an instance of this class from a Foundation object.
  ///
  /// - Parameter object: Foundation object to be loaded.
  ///
  public init(object: [String: Any]) {
    load(object: object)
  }

  ///
  /// Returns a dictionary object that can be used to convert to a JSON string.
  ///
  public var jsonObject: [String: Any] {
    get {
      return [:]
    }
  }
  
  ///
  /// Returns a JSON string using the dictionary object returned from jsonObject. Or an
  /// empty string if the object could not be converted.
  ///
  public var jsonString: String {
    get {
      let object = self.jsonObject
      if let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]) {
        if let str = String(data: data, encoding: .utf8) { return str }
      }
      return String()
    }
  }

  ///
  /// Loads an instance of this class from a JSON string.
  ///
  /// - Parameter json: JSON string to load
  ///
  public func load(json: String) {
    guard let data = json.data(using: .utf8) else { return }
    guard let obj = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any] else { return }
    load(object: obj)
  }
  
  ///
  /// Loads an instance of this class from a Foundation object.
  ///
  /// - Parameter object: Foundation object to be loaded.
  ///
  public func load(object: [String: Any]) {
    // nothing to do
  }

  ///
  /// Saves an instance of this class to persistent storage.
  ///
  /// - Parameter persistentStorage: Where to store this object.
  ///
  /// - Note: Currently not implemented
  public func save(persistentStorage: PersistentStorage) {
    // nothing to do
  }
  
}

///
/// The SwiftISYHost class holds the information required to connect to an ISY series device
/// using HTTP GET.
///
public class SwiftISYHost: SwiftISYObject {
  
  public enum Fields {
    
    case hosts
    case id
    case friendlyName
    case host
    case alternativeHost
    case user
    case password
    
    var key: String {
      get {
        switch self {
        case .hosts: return "hosts"
        case .id: return "id"
        case .friendlyName: return "friendlyName"
        case .host: return "host"
        case .alternativeHost: return "alternativeHost"
        case .user: return "user"
        case .password: return "password"
        }
      }
    }

    var localizedString: String {
      get {
        switch self {
        case .hosts: return "Hosts"
        case .id: return "Id"
        case .friendlyName: return "Friendly Name"
        case .host: return "Host"
        case .alternativeHost: return "Alternative Host"
        case .user: return "User"
        case .password: return "Password"
        }
      }
    }
    
  }
  
  /// Unique identifier for this host.  Or the host name if an id was not supplied.
  fileprivate var _id: String?
  public var id: String {
    get {
      if let id = _id { return id }
      return host
    }
  }

  /// Whether there is an id for this host.
  public var hasId: Bool {
    get {
      guard let id = _id else { return false }
      return id.lengthOfBytes(using: .utf8) > 0
    }
  }
  
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
  
  /// Password for authentication.
  fileprivate var _password: String?
  public var password: String {
    get {
      if let password = _password {
        if password.lengthOfBytes(using: .utf8) > 0 { return password }
      }
      guard let closure = SwiftISYHost._providePassword else { return "" }
      _password = closure(self)
      return _password ?? ""
    }
  }
  
  ///
  /// Allows the client to return a password to be used for a host.
  ///
  static var _providePassword: ((SwiftISYHost) -> String)?
  public static func providePassword(closure: @escaping (SwiftISYHost) -> String) {
    _providePassword = closure
  }

  ///
  /// Loads all hosts from the specified persistent storage.
  ///
  /// - Parameter persistentStorage: Where to retrieve hosts from.
  ///
  /// - Returns: Array of `SwiftISYHost` objects.
  ///
  public static func get(persistentStorage: PersistentStorage) -> [SwiftISYHost] {
    var hosts: [SwiftISYHost] = []

    // get array of hosts from persistent storage
    var array: [[String: Any]]?
    switch persistentStorage {
    case .userDefaults:
      array = UserDefaults.standard.array(forKey: Fields.hosts.key) as? [[String: Any]]
    }
    
    // process hosts in array
    if let array = array {
      for item in array {
        hosts.append(SwiftISYHost(object: item))
      }
    }
    
    return hosts
  }
  
  ///
  /// Add/update host into persistent storage.
  ///
  /// - Parameter persistentStorage: Where to retrieve hosts from.
  /// - Parameter hosts: Hosts to add/update.
  ///
  public static func add(persistentStorage: PersistentStorage, hosts: [SwiftISYHost]) {
    var array: [[String: Any]] = []

    // get hosts from persistent storage
    var existing: [SwiftISYHost]?
    switch persistentStorage {
    case .userDefaults: existing = get(persistentStorage: persistentStorage)
    }

    // add existing hosts
    if let existing = existing {
      var ids = Set<String>()
      for host in hosts {
        if host.id.lengthOfBytes(using: .utf8) > 0 { ids.insert(host.id) }
        if host.host.lengthOfBytes(using: .utf8) > 0 { ids.insert(host.host) }
      }
      for host in existing {
        if ids.contains(where: { (id) -> Bool in
          return id.caseInsensitiveCompare(host.id) == .orderedSame || id.caseInsensitiveCompare(host.host) == .orderedSame
        }) { continue }
        array.append(host.jsonObject)
      }
    }
    
    // add this host
    for host in hosts {
      array.append(host.jsonObject)
    }
    
    // save to persistent storage
    switch persistentStorage {
    case .userDefaults:
      let ud = UserDefaults.standard
      ud.set(array, forKey: Fields.hosts.key)
      ud.synchronize()
    }
  }
  
  ///
  /// Initializes a `SwiftISYHost` object with the specified hostname, username and password.
  ///
  /// - Parameter id: A unique identifier for this host.
  /// - Parameter host: A host name or IP address.
  /// - Parameter user: A username for authentication.
  /// - Parameter password: Optional password for authentication.
  ///
  public convenience init(id: String, host: String, user: String, password: String?) {
    self.init()
    _id = id
    self.host = host
    self.user = user
    _password = password
  }
  
  ///
  /// Initializes a `SwiftISYHost` object with the specified hostname, username and password.
  ///
  /// - Parameter id: A unique identifier for this host.
  /// - Parameter host: A host name or IP address.
  /// - Parameter user: A username for authentication.
  ///
  public convenience init(id: String, host: String, user: String) {
    self.init()
    _id = id
    self.host = host
    self.user = user
  }

  ///
  /// Initializes a `SwiftISYHost` object with the specified hostname and username.
  ///
  /// - Note: `provideHostPassword()` should be set and return a value for the password.
  ///
  /// - Parameter host: A host name or IP address.
  /// - Parameter user: A username for authentication.
  ///
  public convenience init(host: String, user: String) {
    self.init()
    self.host = host
    self.user = user
  }

  ///
  /// Loads this `SwiftISYHost` object with a JSON string composed of a dictionary with the
  /// folowing keys:
  ///
  /// * friendlyName
  /// * host
  /// * alternativeHost (optional)
  /// * user
  /// * password
  ///
  /// - Note: The `password` field is not included as it should be stored secure and encrypted.
  ///
  /// - Parameter json: JSON string to load.
  ///
  override public func load(json: String) {
    super.load(json: json)
  }
  
  override public func load(object: [String: Any]) {
    _id = object[Fields.id.key] as? String
    friendlyName = object[Fields.friendlyName.key] as? String ?? ""
    host = object[Fields.host.key] as? String ?? ""
    alternativeHost = object[Fields.alternativeHost.key] as? String ?? ""
    user = object[Fields.user.key] as? String ?? ""
  }
  
  ///
  /// Returns a dictionary object that can be used to convert to a JSON string.
  ///
  /// - Note: The `password` field is not included as it should be stored secure and encrypted.
  ///
  override public var jsonObject: [String: Any] {
    get {
      return [Fields.id.key:id,
              Fields.friendlyName.key:friendlyName,
              Fields.host.key:host,
              Fields.alternativeHost.key:alternativeHost,
              Fields.user.key:user]
    }
  }

  ///
  /// Returns a basic HTTP authorization string where the user name and password are unencrypted
  /// base64 encoded text.
  ///
  /// - Returns: `authorization` as "Basic Base64(user:pasword)" or nil if it could not be
  /// generated. `error` if authorization could not be generated; nil otherwise.
  ///
  public func authorization() -> (authorization: String?, error: SwiftISYError?) {
    let user = self.user
    if user.lengthOfBytes(using: .utf8) == 0 { return (nil, SwiftISYError(kind: .invalidUser)) }
    
    let password = self.password
    if password.lengthOfBytes(using: .utf8) == 0 { return (nil, SwiftISYError(kind: .invalidPassword)) }
    
    let userPassword = String(format: "%@:%@", user, password)
    guard let userPasswordData = userPassword.data(using: String.Encoding.utf8) else { return (nil, SwiftISYError(kind: .invalidCredential)) }
    let encoded = userPasswordData.base64EncodedString()
    return ("Basic \(encoded)", nil)
  }

  override public func validate() -> (success: Bool, errors: [ValidationError]?) {
    var errors: [ValidationError] = []
    if friendlyName.lengthOfBytes(using: .utf8) == 0 { errors.append(ValidationError(kind: .required, field: Fields.friendlyName.key, friendlyName: Fields.friendlyName.localizedString)) }
    else if host.lengthOfBytes(using: .utf8) == 0 { errors.append(ValidationError(kind: .required, field: Fields.host.key, friendlyName: Fields.host.localizedString)) }
    else if user.lengthOfBytes(using: .utf8) == 0 { errors.append(ValidationError(kind: .required, field: Fields.user.key, friendlyName: Fields.user.localizedString)) }
    else if password.lengthOfBytes(using: .utf8) == 0 { errors.append(ValidationError(kind: .required, field: Fields.password.key, friendlyName: Fields.password.localizedString)) }
    return (true, nil)
  }
  
}

///
/// The `SwiftISYGroup` class represents a scene that includes one or more `SwiftISYNode` nodes as
/// either controller or responder.
///
/// Commands can be sent to a group (e.g. on or off).
///
public class SwiftISYGroup: SwiftISYObject {
  
  /// Flags for this group.  See NodeFlags.
  public var flags: SwiftISYConstants.NodeFlags = []
  
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
  
  override init(elementName: String, attributes: [String: String]) {
    super.init(elementName: elementName, attributes: attributes)
    flags = SwiftISYConstants.NodeFlags(rawValue: UInt8(attributes[SwiftISYConstants.Attributes.flag] ?? "0") ?? 0)
  }
  
  public override func update(elementName: String, attributes: [String : String], text: String) {
    if elementName == SwiftISYConstants.Elements.address {
      address = text
    } else if elementName == SwiftISYConstants.Elements.name {
      name = text
    } else if elementName == SwiftISYConstants.Elements.family {
      family = UInt(text) ?? 0
    } else if elementName == SwiftISYConstants.Elements.deviceGroup {
      deviceGroup = UInt(text) ?? 0
    } else if elementName == SwiftISYConstants.Elements.elkId {
      elkId = text
    } else if elementName == SwiftISYConstants.Elements.link {
      let type = UInt(attributes[SwiftISYConstants.Attributes.type] ?? "0")
      if type == SwiftISYConstants.MemberTypes.controller.rawValue {
        controllerIds.append(text)
      } else {
        responderIds.append(text)
      }
    }
  }
  
  public override var jsonObject: [String : Any] {
    let object = [SwiftISYConstants.Attributes.flag:String(flags.rawValue),
                  SwiftISYConstants.Elements.address:address,
                  SwiftISYConstants.Elements.name:name,
                  SwiftISYConstants.Elements.family:String(family),
                  SwiftISYConstants.Elements.deviceGroup:String(deviceGroup),
                  SwiftISYConstants.Elements.elkId:elkId,
                  SwiftISYConstants.Elements.controllerIds:controllerIds.joined(separator:","),
                  SwiftISYConstants.Elements.responderIds:responderIds.joined(separator:",")]
    return object
  }
  
}

///
/// The `SwiftISYNode` class represents a device.  It can be a light switch that directly or remotely
/// controls a light source.
///
/// Commands can be sent to a group (e.g. on or off).
///
public class SwiftISYNode: SwiftISYObject {
  
  /// Flags for this node.  See NodeFlags.
  public var flags: SwiftISYConstants.NodeFlags = []
  
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
  
  override init(elementName: String, attributes: [String: String]) {
    super.init(elementName: elementName, attributes: attributes)
    if let flags = attributes[SwiftISYConstants.Attributes.flag] {
      self.flags = SwiftISYConstants.NodeFlags(rawValue: UInt8(flags) ?? 0)
    }
    if let address = attributes[SwiftISYConstants.Attributes.id] {
      self.address = address
    }
  }

  public override func update(elementName: String, attributes: [String : String], text: String) {
    if elementName == SwiftISYConstants.Elements.address {
      address = text
    } else if elementName == SwiftISYConstants.Elements.name {
      name = text
    } else if elementName == SwiftISYConstants.Elements.parent {
      parent = text
    } else if elementName == SwiftISYConstants.Elements.family {
      family = UInt(text) ?? 0
    } else if elementName == SwiftISYConstants.Elements.type {
      type = text
    } else if elementName == SwiftISYConstants.Elements.enabled {
      enabled = text == "true"
    } else if elementName == SwiftISYConstants.Elements.deviceClass {
      deviceClass = UInt(text) ?? 0
    } else if elementName == SwiftISYConstants.Elements.wattage {
      wattage = UInt(text) ?? 0
    } else if elementName == SwiftISYConstants.Elements.dcPeriod {
      dcPeriod = UInt(text) ?? 0
    } else if elementName == SwiftISYConstants.Elements.pnode {
      pnode = text
    } else if elementName == SwiftISYConstants.Elements.elkId {
      elkId = text
    } else if elementName == SwiftISYConstants.Elements.property {
      property = text
    }
  }
  
  public override var jsonObject: [String : Any] {
    return [SwiftISYConstants.Attributes.flag:String(flags.rawValue),
            SwiftISYConstants.Elements.address:address,
            SwiftISYConstants.Elements.name:name,
            SwiftISYConstants.Elements.parent:parent,
            SwiftISYConstants.Elements.family:String(family),
            SwiftISYConstants.Elements.type:type,
            SwiftISYConstants.Elements.enabled:(enabled ? "true" : "false"),
            SwiftISYConstants.Elements.deviceClass:String(deviceClass),
            SwiftISYConstants.Elements.wattage:String(wattage),
            SwiftISYConstants.Elements.dcPeriod:String(dcPeriod),
            SwiftISYConstants.Elements.pnode:pnode,
            SwiftISYConstants.Elements.elkId:elkId,
            SwiftISYConstants.Elements.property:property]
  }

}

///
/// The `SwiftISYStatus` class represents the status of a device.  For a light switch, its 
/// properties include whether it is on, off or dimmed to some level.
///
public class SwiftISYStatus: SwiftISYObject {
  
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
    if elementName != SwiftISYConstants.Elements.property { return false }
    if let type = attributes[SwiftISYConstants.Attributes.id] {
      return type == SwiftISYConstants.PropertyTypes.status
    }
    return false
  }
  
  override init(elementName: String, attributes: [String: String]) {
    super.init(elementName: elementName, attributes: attributes)
    value = UInt8(attributes[SwiftISYConstants.Attributes.value] ?? "0") ?? 0
    if let formatted = attributes[SwiftISYConstants.Attributes.formatted] { self.formatted = formatted }
    if let unitOfMeasure = attributes[SwiftISYConstants.Attributes.unitsOfMeasure] { self.unitOfMeasure = unitOfMeasure }
  }
  
  override public var jsonObject: [String : Any] {
    return [SwiftISYConstants.Attributes.value: String(value),
            SwiftISYConstants.Attributes.formatted: formatted,
            SwiftISYConstants.Attributes.unitsOfMeasure: unitOfMeasure];
  }

}

///
/// The `SwiftISYResponse` class represents the response from a command to a ISY host.
///
public class SwiftISYResponse: SwiftISYObject {

  /// Whether the command was successfuly executed.
  public var succeeded = false
  
  /// Status code for the command.
  public var status: UInt = 0
  
  override init(elementName: String, attributes: [String: String]) {
    super.init(elementName: elementName, attributes: attributes)
    succeeded = attributes[SwiftISYConstants.Attributes.succeeded] == "true"
  }
 
  public override func update(elementName: String, attributes: [String : String], text: String) {
    if elementName == SwiftISYConstants.Elements.status {
      status = UInt(text) ?? 0
    }
  }
  
}
