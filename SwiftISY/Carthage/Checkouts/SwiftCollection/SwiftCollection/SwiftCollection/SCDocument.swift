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
/// `SCDocumentProtocol` describes the routines necessary to implement a `SCDocument`.
///
/// The goal of `SCDocumentProtocol` is to provide a document holder for use in collections and
/// provide a primary key, sorting and storage to and retrieval from a persistence store.
///
public protocol SCDocumentProtocol: Hashable {
  
  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Id
   * -----------------------------------------------------------------------------------------------
   */
  
  /// Primary key for this document.  It should be unique across a collection.
  var id: SwiftCollection.Id { get }

  /// Returns the primary key as a hex string in the format `0000-0000-0000-0000`.
  var guid: String { get }
  
  /// Returns `true` if `id` has a value with a length greater than zero; `false` otherwise.
  func hasId() -> Bool
  
  /// Creates an instance of this class with the specified `id`.
  ///
  /// - Parameter id: Primary key to be used.
  init(id: SwiftCollection.Id)
  
}

extension SCDocumentProtocol {
  
  public var guid: String {
    return id.toHexString(groupEvery: 2)
  }
  
  public func hasId() -> Bool {
    return id > 0
  }

}

///
/// The goal of `SCDocument` is to provide a document holder for use in collections and
/// provide a primary key, sorting and storage to and retrieval from a persistence store.
///
open class SCDocument: SCJsonProtocol {

  public struct Keys {
    
    public static let id = "_id"
    
  }
  
  fileprivate var _id: SwiftCollection.Id = 0
  
  public required init() {
    // nothing to do
  }

  public required convenience init(id: SwiftCollection.Id) {
    self.init()
    _id = id
  }

  open func load(propertyWithName name: String, currentValue: Any, potentialValue: Any, json: AnyObject) {
    switch name {
    case Keys.id: if let id = (json as? [String: Any])?[Keys.id] as? SwiftCollection.Id { _id = id }
    default: break
    }
  }

}

extension SCDocument: SCDocumentProtocol {

  public var id: SwiftCollection.Id {
    return _id
  }
  
  public var hashValue: Int {
      return _id.hashValue
  }
  
  public static func == (lhs: SCDocument, rhs: SCDocument) -> Bool {
    return lhs.id == rhs.id && lhs.id == rhs.id
  }
  
}

extension SCDocument: CustomStringConvertible {
  
  public var description: String {
    return String(describing: "SCDocument(\(_id))")
  }
  
}
