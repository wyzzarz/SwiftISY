//
//  SCDocument.swift
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
/// The goal of `SCDocument` is to provide a document holder for use in collections and
/// provide a primary key, sorting and storage to and retrieval from a persistence store.
///
open class SCDocument: SCJsonObject {

  /// Keys describing properties for this class.
  public struct Keys {
    
    public static let id = "_id"
    
  }
  
  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Id
   * -----------------------------------------------------------------------------------------------
   */

  /// Primary key for this document.  It should be unique across a collection.
  final public var id: SwiftCollection.Id {
    return _id
  }
  fileprivate var _id: SwiftCollection.Id = 0
  
  /// Returns the primary key as a hex string in the format `0000-0000-0000-0000`.
  final public var guid: String {
    return id.toHexString(groupEvery: 2)
  }
  
  /// Returns `true` if `id` has a value with a length greater than zero; `false` otherwise.
  final public func hasId() -> Bool {
    return id > 0
  }
 
  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Initialize
   * -----------------------------------------------------------------------------------------------
   */

  public required init() {
    super.init()
  }
  
  public required init(json: AnyObject) throws {
    try super.init(json: json)
    // set id, if it exists
    guard let dict = json as? [String: Any] else { return }
    guard let anId = dict[Keys.id] as? SwiftCollection.Id else { return }
    _id = anId
  }

  /// Creates an instance of this class with the specified `id`.
  ///
  /// - Parameter id: Primary key to be used.
  public required convenience init(id: SwiftCollection.Id) {
    self.init()
    _id = id
  }

  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - CustomStringConvertible
   * -----------------------------------------------------------------------------------------------
   */
  
  override open var description: String {
    return String(describing: "SCDocument(\(_id))")
  }

  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Hashable
   * -----------------------------------------------------------------------------------------------
   */
  
  override open var hashValue: Int {
    return _id.hashValue
  }
  
  override open func isEqual(_ object: Any?) -> Bool {
    guard let object = object as? SCDocument else { return false }
    return self.id == object.id
  }

  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Json
   * -----------------------------------------------------------------------------------------------
   */
  
  override open func jsonObject() -> AnyObject? {
    let json = super.jsonObject()
    guard var dict = super.jsonObject() as? [String: Any] else { return json }
    if dict[Keys.id] != nil { return json }
    dict[Keys.id] = _id
    return dict as AnyObject
  }

  override open func load(propertyWithName name: String, currentValue: Any, potentialValue: Any, json: AnyObject) {
    guard let dict = json as? [String: Any] else { return }
    switch name {
    case Keys.id: if let id = dict[name] as? SwiftCollection.Id { _id = id }
    default: break
    }
  }

}
