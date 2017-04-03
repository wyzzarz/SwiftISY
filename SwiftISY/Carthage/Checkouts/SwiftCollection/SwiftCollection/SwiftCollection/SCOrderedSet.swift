//
//  SCOrderedSet.swift
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

/// `SCOrderedSet` holds `SCDocument` objects.  Documents added to this collection must include a
/// primary key.
///
/// The collection automatically arranges elements by the sort keys.
///
open class SCOrderedSet<Element: SCDocument>: SCJsonObject {

  // Holds an array of elements.
  fileprivate var elements: [Element] = []

  // Holds a set of ids that corresponds to each element in elements.
  fileprivate var ids = NSMutableOrderedSet()
 
  // Temporarily holds a set of ids for elements that have been created, but have not been added to 
  // elements.
  fileprivate var createdIds: Set<SwiftCollection.Id> = []

  /// Creates an instance of `SCOrderedSet`.
  public required init() {
    super.init()
  }
  
  public required init(json: AnyObject) throws {
    try super.init(json: json)
  }

  /// Creates an instance of `SCOrderedSet` populated by documents in the collection.
  ///
  /// - Parameter collection: Documents to be added.
  /// - Throws: `missingId` if a document has no id.
  public convenience init<C: Collection>(_ collection: C) throws where C.Iterator.Element == Element {
    self.init()
    for element in collection {
      try append(document: element)
    }
  }

  /// Creates an instance of `SCOrderedSet` populated by documents in the array.
  ///
  /// - Parameter array: Documents to be added.
  /// - Throws: `missingId` if a document has no id.
  public convenience init<S: Sequence>(_ sequence: S) throws where S.Iterator.Element == Element {
    self.init()
    for element in sequence {
      try append(document: element)
    }
  }
  
  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - CustomStringConvertible
   * -----------------------------------------------------------------------------------------------
   */
  
  override open var description: String {
    return String(describing: ids)
  }

  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Document
   * -----------------------------------------------------------------------------------------------
   */
  
  /// Creates a document stub with a valid id.  The id will be randomly generated and unique for
  /// documents in the collection.
  ///
  /// The document will not be added to the collection.  It can be added later once the details
  /// have been updated.
  ///
  /// - Parameter id: Optional id to be applied to the document.
  /// - Returns: A document that can be added to the collection.
  /// - Throws: `existingId` if a document has no id.  `generateId` if an id could not be generated.
  open func create(withId id: SwiftCollection.Id? = nil) throws -> Element {
    let existing = createdIds.union(ids.set as! Set<SwiftCollection.Id>)
    var theId = id
    if theId != nil {
      // check if this id already exists
      if existing.contains(theId!) { throw SwiftCollection.Errors.existingId }
    } else {
      // get a new id
      var i: Int = Int.max / 10
      repeat {
        let r = SwiftCollection.Id.random()
        if !existing.contains(r) {
          theId = r
          break
        }
        i -= 1
      } while i > 0
    }
    guard theId != nil else { throw SwiftCollection.Errors.generateId }
    
    // remember this id until the document is stored in this collection
    self.createdIds.insert(theId!)
    
    // done
    return Element(id: theId!)
  }
  
  /// Returns the last document from the collection.
  final public var last: Iterator.Element? {
    return elements.last
  }

  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Document Id
   * -----------------------------------------------------------------------------------------------
   */
  
  /// Returns a document from the collection.
  ///
  /// - Parameter id: `id` of document to return.
  /// - Returns: A document with the specified id.
  final public func document(withId id: SwiftCollection.Id?) -> Element? {
    guard let id = id else { return nil }
    let i = ids.index(of: id)
    return i == NSNotFound ? nil : elements[i]
  }
  
  /// Returns the first document id in the collection.
  final public var firstId: SwiftCollection.Id? {
    return ids.firstObject as? SwiftCollection.Id
  }
  
  /// Returns the last document id in the collection.
  final public var lastId: SwiftCollection.Id? {
    return ids.lastObject as? SwiftCollection.Id
  }
  
  /// Checks whether the document id exists in this set.
  ///
  /// - Parameter id: `id` of document to be located.
  /// - Returns: `true` if the document id exists; `false` otherwise.
  final public func contains(id: SwiftCollection.Id) -> Bool {
    return ids.index(of: id) != NSNotFound
  }
  
  /// The document id in the collection offset from the specified id.
  ///
  /// - Parameters:
  ///   - id: `id` of document to be located.
  ///   - offset: Distance from the specified id.
  /// - Returns: `id` of the document.  Or `nil` if the offset is out of bounds.
  final public func id(id: SwiftCollection.Id?, offset: Int) -> SwiftCollection.Id? {
    guard let id = id else { return nil }
    let i = ids.index(of: id)
    if i == NSNotFound { return nil }
    let ni = i + offset
    return ni >= 0 && ni < ids.count ? ids[ni] as? SwiftCollection.Id : nil
  }

  /// The next document id in the collection after the specified id.
  ///
  /// - Parameter id: `id` of document to be located.
  /// - Returns: `id` of next document.  Or `nil` if this is the last document.
  final public func id(after id: SwiftCollection.Id?) -> SwiftCollection.Id? {
    return self.id(id: id, offset: +1)
  }

  /// The previous document id in the collection before the specified id.
  ///
  /// - Parameter id: `id` of document to be located.
  /// - Returns: `id` of previous document.  Or `nil` if this is the first document.
  final public func id(before id: SwiftCollection.Id?) -> SwiftCollection.Id? {
    return self.id(id: id, offset: -1)
  }

  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Add
   * -----------------------------------------------------------------------------------------------
   */
  
  /// Adds the document to the collection at the specified index.  Existing documents are ignored.
  ///
  /// - Parameters:
  ///   - document: Document to be added.
  ///   - i: Position to insert the document.  `i` must be a valid index into the collection.
  /// - Throws: `missingId` if the document has no id.
  open func insert(document: Element, at i: Int) throws {
    // ensure the document has an id
    guard document.hasId() else { throw SwiftCollection.Errors.missingId }
    guard !ids.contains(document.id) else { return }
    elements.insert(document, at: i)
    ids.insert(document.id, at: i)
    createdIds.remove(document.id)
  }
  
  /// Adds the documents to the end of the collection.
  ///
  /// - Parameters:
  ///   - newDocuments: Documents to be added.
  ///   - i: Position to insert the documents.  `i` must be a valid index into the collection.
  /// - Throws: `missingId` if a document has no id.
  open func insert<C : Collection>(contentsOf newDocuments: C, at i: Int) throws where C.Iterator.Element == Element {
    let newTotal = ids.count + Int(newDocuments.count.toIntMax())
    elements.reserveCapacity(newTotal)
    for d in newDocuments.reversed() {
      try self.insert(document: d, at: i)
    }
  }
  
  /// Adds the document to the end of the collection.
  ///
  /// - Parameter document: Document to be added.
  /// - Throws: `missingId` if the document has no id.
  open func append(document: Element) throws {
    // ensure the document has an id
    guard document.hasId() else { throw SwiftCollection.Errors.missingId }
    guard !ids.contains(document.id) else { return }
    elements.append(document)
    ids.add(document.id)
    createdIds.remove(document.id)
  }
  
  /// Adds documents to the end of the collection.  Existing documents are ignored.
  ///
  /// - Parameter newDocuments: A collection of documents to be added.
  /// - Throws: `missingId` if a document has no id.
  open func append<C : Collection>(contentsOf newDocuments: C) throws where C.Iterator.Element == Element {
    let newTotal = ids.count + Int(newDocuments.count.toIntMax())
    elements.reserveCapacity(newTotal)
    for d in newDocuments {
      if ids.contains(d.id) { continue }
      try self.append(document: d)
    }
  }
  
  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Remove
   * -----------------------------------------------------------------------------------------------
   */

  /// Removes the document from the collection.
  ///
  /// - Parameter document: Document to be removed.
  open func remove(document: Element) {
    if let i = index(of: document) {
      elements.remove(at: i.index)
      ids.remove(at: i.index)
    }
    createdIds.remove(document.id)
  }
 
  /// Removes documents from the collection.
  ///
  /// - Parameter newDocuments: A collection of documents to be removed.
  /// - Throws: `missingId` if a document has no id.
  open func remove<C : Collection>(contentsOf newDocuments: C) where C.Iterator.Element == Element {
    for d in newDocuments {
      if let i = index(of: d) {
        elements.remove(at: i.index)
        ids.remove(at: i.index)
        createdIds.remove(d.id)
      }
    }
  }

  /// Removes all documents from the collection.
  open func removeAll() {
    elements.removeAll()
    ids.removeAllObjects()
    createdIds.removeAll()
  }
  
  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Combine
   * -----------------------------------------------------------------------------------------------
   */
  
  /// Returns a new set that is a combination of this set and the other set.
  ///
  /// - Parameter other: Other set to combine.
  /// - Returns: A new set with unique elements from both sets.
  /// - Throws: `missingId` if the document has no id.
  open func union(_ other: SCOrderedSet<Element>) throws -> SCOrderedSet<Element> {
    let set = self
    for (_, element) in other.enumerated() {
      if !set.contains(element) { try set.append(document: element) }
    }
    return set
  }

  /// Removes any element in this set that is not present in the other set.
  ///
  /// - Parameter other: Other set to perform the intersection.
  open func intersect(_ other: SCOrderedSet<Element>) {
    var i = 0
    while i < elements.count {
      let element = elements[i]
      if !other.contains(element) {
        elements.remove(at: i)
        ids.removeObject(at: i)
      } else {
        i += 1
      }
    }
  }

  /// Removes any element in this set that is present in the other set.
  ///
  /// - Parameter other: Other set to perform the subtraction.
  open func minus(_ other: SCOrderedSet<Element>) {
    var i = 0
    while i < elements.count {
      let element = elements[i]
      if other.contains(element) {
        elements.remove(at: i)
        ids.removeObject(at: i)
      } else {
        i += 1
      }
    }
  }

}

/*
 * -----------------------------------------------------------------------------------------------
 * MARK: - Sequence
 * -----------------------------------------------------------------------------------------------
 */

extension SCOrderedSet: Sequence {

  public typealias Iterator = AnyIterator<Element>
  
  public func makeIterator() -> Iterator {
    var iterator = elements.makeIterator()
    return AnyIterator { return iterator.next() }
  }
}

/*
 * -----------------------------------------------------------------------------------------------
 * MARK: - Collection
 * -----------------------------------------------------------------------------------------------
 */

public struct SCOrderedSetIndex<Element: Hashable>: Comparable {
  
  fileprivate let index: Int
  
  fileprivate init(_ index: Int) {
    self.index = index
  }
  
  public static func == (lhs: SCOrderedSetIndex, rhs: SCOrderedSetIndex) -> Bool {
    return lhs.index == rhs.index
  }
  
  public static func < (lhs: SCOrderedSetIndex, rhs: SCOrderedSetIndex) -> Bool {
    return lhs.index < rhs.index
  }
  
}

extension SCOrderedSet: BidirectionalCollection {

  public typealias Index = SCOrderedSetIndex<Element>
  
  final public var startIndex: Index {
    return SCOrderedSetIndex(elements.startIndex)
  }
  
  final public var endIndex: Index {
    return SCOrderedSetIndex(elements.endIndex)
  }
  
  final public func index(after i: Index) -> Index {
    return Index(elements.index(after: i.index))
  }

  final public func index(before i: Index) -> Index {
    return Index(elements.index(before: i.index))
  }

  final public subscript (position: Index) -> Iterator.Element {
    return elements[position.index]
  }
  
}

/*
 * -----------------------------------------------------------------------------------------------
 * MARK: - Persistence
 * -----------------------------------------------------------------------------------------------
 */

extension SCOrderedSet: SCJsonCollectionProtocol {
  
  open func jsonCollectionElements() -> [Any] {
    return elements
  }

}
