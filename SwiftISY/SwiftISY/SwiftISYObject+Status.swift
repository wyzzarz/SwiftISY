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

public class SwiftISYStatuses: SCOrderedSet<SwiftISYStatus>, SwiftISYHostKeyProtocol, SwiftISYAddressesProtocol {
  
  override open func storageKey() -> String {
    guard let hostId = self.hostId else { return "" }
    guard hostId.isValid() else { return "" }
    return "\(super.storageKey()).\(hostId)"
  }
  
  override open func load(arrayItem item: AnyObject, atIndex i: Int, json: AnyObject) {
    try? append(SwiftISYStatus(json: item))
  }
  
  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - SwiftISYAddressesProtocol
   * -----------------------------------------------------------------------------------------------
   */
  
  public typealias SwiftISYAddressesProtocolElement = SwiftISYStatus
  
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
  fileprivate func existingDocument(_ document: SwiftISYStatus) -> (index: Int, document: SwiftISYStatus?) {
    let i = addresses.index(of: document.address)
    return (i, i == NSNotFound ? nil : self[self.index(self.startIndex, offsetBy: i)])
  }
  
  /// Registers a new document.
  ///
  /// - Parameter document: Document to register
  /// - Returns: `true` if the document can be registered; `false` if the document with the same
  ///   address already exists in the collection.
  /// - Throws: See `register()` for throws.
  fileprivate func registerNewDocument(_ document: SwiftISYStatus) throws -> Bool {
    // check if this status exists
    let (_, d) = existingDocument(document)
    // cancel if this is an existing status
    if let _ = d { return false }
    // otherwise register this document and continue with the insert
    try register(document)
    return true
  }
  
  override open func willInsert(_ document: SwiftISYStatus, at index: Int) throws -> Bool {
    return try registerNewDocument(document)
  }
  
  override open func didInsert(_ document: SwiftISYStatus, at i: Int, success: Bool) {
    guard success else { return }
    (addresses as! NSMutableOrderedSet).insert(document.address, at: i)
  }
  
  override open func willAppend(_ document: SwiftISYStatus) throws -> Bool {
    return try registerNewDocument(document)
  }
  
  override open func didAppend(_ document: SwiftISYStatus, success: Bool) {
    guard success else { return }
    (addresses as! NSMutableOrderedSet).add(document.address)
  }
  
  override open func willRemove(_ document: SwiftISYStatus) -> Bool {
    return true
  }
  
  override open func didRemove(_ document: SwiftISYStatus, at i: Int, success: Bool) {
    guard success else { return }
    (addresses as! NSMutableOrderedSet).removeObject(at: i)
  }
  
  override open func willRemoveAll() -> Bool {
    return true
  }
  
  override open func didRemoveAll() {
    (addresses as! NSMutableOrderedSet).removeAllObjects()
  }
  
  override open func willReplace(_ document: SwiftISYStatus, with: SwiftISYStatus, at i: Int) throws -> Bool {
    return true
  }
  
  override open func didReplace(_ document: SwiftISYStatus, with: SwiftISYStatus, at i: Int, success: Bool) {
    guard success else { return }
    (addresses as! NSMutableOrderedSet).replaceObject(at: i, with: with.address)
  }

}

public class SwiftISYStatus: SCDocument, SwiftISYParserProtocol {
  
  /// Address of the node for this status.  This is the primary key.
  public var address = ""

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
  
  open override func load(propertyWithName name: String, currentValue: Any, potentialValue: Any, json: AnyObject) {
    super.load(propertyWithName: name, currentValue: currentValue, potentialValue: potentialValue, json: json)
    
    // get json as a dictionary
    guard let dict = json as? [String: Any] else { return }
    
    // get value for this property
    guard let value = dict[name] else { return }
    
    // apply value for property
    switch name {
    case Keys.address: address = value as? String ?? ""
    case Keys.value: self.value = (value as? NSNumber)?.uint8Value ?? 0
    case Keys.formatted: formatted = value as? String ?? ""
    case Keys.unitOfMeasure: unitOfMeasure = value as? String ?? ""
    default: break
    }
  }
  
}

extension SwiftISYStatus.Keys {
  
//  public static let address = "address"
  public static let value = "value"
  public static let formatted = "formatted"
  public static let unitOfMeasure = "unitOfMeasure"
  
}