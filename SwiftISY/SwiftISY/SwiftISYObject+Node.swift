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

public class SwiftISYNodes: SCOrderedSet<SwiftISYNode>, SwiftISYHostKeyProtocol, SwiftISYAddressesProtocol {
  
  public struct SortId {
    
    public static let address = SwiftISYNodes.Sort.SortId("address")!
    public static let name = SwiftISYNodes.Sort.SortId("name")!
    
  }
  
  public required init() {
    super.init()
    sorting.sortId = SortId.name
    sorting.add(SortId.address) { (n1, n2) -> Bool in
      return n1.address.compare(n2.address) == .orderedAscending
    }
    sorting.add(SortId.name) { (n1, n2) -> Bool in
      return n1.name.compare(n2.name) == .orderedAscending
    }
  }
  
  public required init(json: AnyObject) throws {
    try super.init(json: json)
  }
  
  override open func storageKey() -> String {
    guard let hostId = self.hostId else { return "" }
    guard hostId.isValid() else { return "" }
    return "\(super.storageKey()).\(hostId)"
  }
  
  override open func load(arrayItem item: AnyObject, atIndex i: Int, json: AnyObject) {
    try? add(SwiftISYNode(json: item))
  }

  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - SwiftISYAddressesProtocol
   * -----------------------------------------------------------------------------------------------
   */
  
  public typealias SwiftISYAddressesProtocolElement = SwiftISYNode

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
  fileprivate func existingDocument(_ document: SwiftISYNode) -> (index: Int, document: SwiftISYNode?) {
    let i = addresses.index(of: document.address)
    return (i, i == NSNotFound ? nil : self[self.index(self.startIndex, offsetBy: i)])
  }
  
  /// Registers a new document.
  ///
  /// - Parameter document: Document to register
  /// - Returns: `true` if the document can be registered; `false` if the document with the same
  ///   address already exists in the collection.
  /// - Throws: See `register()` for throws.
  fileprivate func registerNewDocument(_ document: SwiftISYNode) throws -> Bool {
    // check if this node exists
    let (_, d) = existingDocument(document)
    // cancel if this is an existing node
    if let _ = d { return false }
    // otherwise register this document and continue with the insert
    try register(document)
    return true
  }
  
  override open func willInsert(_ document: SwiftISYNode, at index: Int) throws -> Bool {
    return try registerNewDocument(document)
  }
  
  override open func didInsert(_ document: SwiftISYNode, at i: Int, success: Bool) {
    guard success else { return }
    (addresses as! NSMutableOrderedSet).insert(document.address, at: i)
  }
  
  override open func willAppend(_ document: SwiftISYNode) throws -> Bool {
    return try registerNewDocument(document)
  }
  
  override open func didAppend(_ document: SwiftISYNode, success: Bool) {
    guard success else { return }
    (addresses as! NSMutableOrderedSet).add(document.address)
  }
  
  override open func willAdd(_ document: SwiftISYNode, at i: Int) throws -> Bool {
    return try registerNewDocument(document)
  }
  
  override open func didAdd(_ document: SwiftISYNode, at i: Int, success: Bool) {
    guard success else { return }
    (addresses as! NSMutableOrderedSet).insert(document.address, at: i)
  }
  
  override open func willRemove(_ document: SwiftISYNode) -> Bool {
    return true
  }
  
  override open func didRemove(_ document: SwiftISYNode, at i: Int, success: Bool) {
    guard success else { return }
    (addresses as! NSMutableOrderedSet).removeObject(at: i)
  }
  
  override open func willRemoveAll() -> Bool {
    return true
  }
  
  override open func didRemoveAll() {
    (addresses as! NSMutableOrderedSet).removeAllObjects()
  }
  
  override open func willReplace(_ document: SwiftISYNode, with: SwiftISYNode, at i: Int) throws -> Bool {
    return true
  }
  
  override open func didReplace(_ document: SwiftISYNode, with: SwiftISYNode, at i: Int, success: Bool) {
    guard success else { return }
    (addresses as! NSMutableOrderedSet).replaceObject(at: i, with: with.address)
  }
  
}

public class SwiftISYNode: SCDocument, SwiftISYParserProtocol {
  
  /// Flags for this node.  See NodeFlags.
  public var flags: SwiftISY.NodeFlags = []
  
  /// Address of the node.  This is the primary key.
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
  
  /// Properties for this node.  Such as status of a light switch.
  public var property = ""
  
  /// Options describing this node.
  public var options: SwiftISY.OptionFlags = SwiftISY.OptionFlags(rawValue: 0)
  
  /// Returns `true` if this node controls a light; `false` otherwise.
  public var isLight: Bool { return options.contains(.light) }

  /// Returns `true` if this node controls a light switch; `false` otherwise.
  public var isOnOff: Bool { return options.contains(.onOff) }

  /// Returns `true` if this node controls a dimmable light; `false` otherwise.
  public var isDimmable: Bool { return options.contains(.dimmable) }

  public required convenience init(elementName: String, attributes: [String: String]) {
    self.init()
    if let flags = attributes[SwiftISY.Attributes.flag] { self.flags = SwiftISY.NodeFlags(rawValue: UInt8(flags) ?? 0) }
    if let address = attributes[SwiftISY.Attributes.id] { self.address = address }
  }
  
  override open var description: String {
    return String(describing: "\(String(describing: type(of: self)))(\"\(address)\":\"\(name)\")")
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
    case Keys.options:
      if let optionsDict = value as? [String: NSNumber] {
        options = SwiftISY.OptionFlags(rawValue: optionsDict["rawValue"]?.uint8Value ?? 0)
      }
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
  public static let options = "options"
  
}
