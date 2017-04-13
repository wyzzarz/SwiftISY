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

public class SwiftISYGroups: SCOrderedSet<SwiftISYGroup>, SwiftISYHostKeyProtocol, SwiftISYAddressesProtocol {
  
  override open func storageKey() -> String {
    guard let hostId = self.hostId else { return "" }
    guard hostId.isValid() else { return "" }
    return "\(super.storageKey()).\(hostId)"
  }
  
  override open func load(arrayItem item: AnyObject, atIndex i: Int, json: AnyObject) {
    try? append(SwiftISYGroup(json: item))
  }
  
  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - SwiftISYAddressesProtocol
   * -----------------------------------------------------------------------------------------------
   */
  
  public typealias SwiftISYAddressesProtocolElement = SwiftISYGroup
  
  final public func document(address: String) -> SwiftISYAddressesProtocolElement? {
    let i = self.index(ofAddress: address)
    guard i != NSNotFound else { return nil }
    return self[self.index(self.startIndex, offsetBy: i)]
  }

  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - SCOrderedSetDelegate
   * -----------------------------------------------------------------------------------------------
   */
  
  /// Find document in the collection having the same address.
  ///
  /// - Parameter document: Document to be located.
  /// - Returns:
  ///   - index: Location of the document in the collection; or `NSNotFound` if it does not exist.
  ///   - document: Existing document; or `nil` if it does not exist.
  fileprivate func existingDocument(_ document: SwiftISYGroup) -> (index: Int, document: SwiftISYGroup?) {
    let i = addresses.index(of: document.address)
    return (i, i == NSNotFound ? nil : self[self.index(self.startIndex, offsetBy: i)])
  }
  
  /// Registers a new document.
  ///
  /// - Parameter document: Document to register
  /// - Returns: `true` if the document can be registered; `false` if the document with the same
  ///   address already exists in the collection.
  /// - Throws: See `register()` for throws.
  fileprivate func registerNewDocument(_ document: SwiftISYGroup) throws -> Bool {
    // check if this group exists
    let (_, d) = existingDocument(document)
    // cancel if this is an existing group
    if let _ = d { return false }
    // otherwise register this document and continue with the insert
    try register(document)
    return true
  }
  
  override open func willInsert(_ document: SwiftISYGroup, at index: Int) throws -> Bool {
    return try registerNewDocument(document)
  }
  
  override open func didInsert(_ document: SwiftISYGroup, at i: Int, success: Bool) {
    guard success else { return }
    (addresses as! NSMutableOrderedSet).insert(document.address, at: i)
  }
  
  override open func willAppend(_ document: SwiftISYGroup) throws -> Bool {
    return try registerNewDocument(document)
  }
  
  override open func didAppend(_ document: SwiftISYGroup, success: Bool) {
    guard success else { return }
    (addresses as! NSMutableOrderedSet).add(document.address)
  }
  
  override open func willRemove(_ document: SwiftISYGroup) -> Bool {
    return true
  }
  
  override open func didRemove(_ document: SwiftISYGroup, at i: Int, success: Bool) {
    guard success else { return }
    (addresses as! NSMutableOrderedSet).removeObject(at: i)
  }
  
  override open func willRemoveAll() -> Bool {
    return true
  }
  
  override open func didRemoveAll() {
    (addresses as! NSMutableOrderedSet).removeAllObjects()
  }
  
  override open func willReplace(_ document: SwiftISYGroup, with: SwiftISYGroup, at i: Int) throws -> Bool {
    return true
  }
  
  override open func didReplace(_ document: SwiftISYGroup, with: SwiftISYGroup, at i: Int, success: Bool) {
    guard success else { return }
    (addresses as! NSMutableOrderedSet).replaceObject(at: i, with: with.address)
  }

}

public class SwiftISYGroup: SCDocument, SwiftISYParserProtocol {
  
  /// Flags for this group.  See NodeFlags.
  public var flags: SwiftISY.NodeFlags = []
  
  /// Address of the group.  This is the primary key.
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
    case Keys.family: family = (value as? NSNumber)?.uintValue ?? 0
    case Keys.deviceGroup: deviceGroup = (value as? NSNumber)?.uintValue ?? 0
    case Keys.elkId: elkId = value as? String ?? ""
    case Keys.controllerIds:
      if let array = value as? [String] {
        controllerIds = array
      }
    case Keys.responderIds:
      if let array = value as? [String] {
        responderIds = array
      }
    default: break
    }
  }
  
}

extension SwiftISYGroup.Keys {
  
//  public static let flags = "flags"
//  public static let address = "address"
//  public static let name = "name"
//  public static let family = "family"
  public static let deviceGroup = "deviceGroup"
//  public static let elkId = "elkId"
  public static let responderIds = "responderIds"
  public static let controllerIds = "controllerIds"
  
}
