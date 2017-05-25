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

public protocol SCOrderedSetDelegate {
  
  associatedtype Document
  
  /// Tells the delegate that there will be changes to the collection.
  func willStartChanges()
  
  /// Tells the delegate that changes have been performed to he collection.
  func didEndChanges()
  
  /// Tells the delegate that a document will be inserted into the collection.
  ///
  /// - Parameters:
  ///   - document: Document to be inserted.
  ///   - i: Position to insert document.
  /// - Returns: `true` if the document can be inserted; `false` otherwise.
  func willInsert(_ document: Document, at i: Int) throws -> Bool

  /// Tells the delegate that a document was inserted.
  ///
  /// - Parameters:
  ///   - document: Document that was inserted.
  ///   - i: Position of inserted document.
  ///   - success: `true` if the document was inserted; `false` otherwise.  Documents are not 
  ///     inserted if they already exist in the collection.
  func didInsert(_ document: Document, at i: Int, success: Bool)

  /// Tells the delegate that a document will be appended to the collection.
  ///
  /// - Parameter document: Document to be appended.
  /// - Returns: `true` if the document can be appended; `false` otherwise.
  func willAppend(_ document: Document) throws -> Bool

  /// Tells the delegate that a document was appended to the collection.
  ///
  /// - Parameters:
  ///   - document: Document that was appended.
  ///   - success: `true` if the document was appended; `false` otherwise.  Documents are not
  ///     appended if they already exist in the collection.
  func didAppend(_ document: Document, success: Bool)
  
  /// Tells the delegate that a document will be added into the collection.
  ///
  /// - Parameters:
  ///   - document: Document to be added.
  ///   - i: Position to add document.
  /// - Returns: `true` if the document can be added; `false` otherwise.
  func willAdd(_ document: Document, at i: Int) throws -> Bool
  
  /// Tells the delegate that a document was added.
  ///
  /// - Parameters:
  ///   - document: Document that was added.
  ///   - i: Position of added document.
  ///   - success: `true` if the document was added; `false` otherwise.  Documents are not
  ///     added if they already exist in the collection.
  func didAdd(_ document: Document, at i: Int, success: Bool)

  /// Tells the delegate that a document will be removed from the collection.
  ///
  /// - Parameter document: Document to be removed.
  /// - Returns: `true` if the document can be removed; `false` otherwise.
  func willRemove(_ document: Document) -> Bool

  /// Tells the delegate that a document was removed from the collection.
  ///
  /// - Parameters:
  ///   - document: Document that was removed
  ///   - i: Position of removed document.
  ///   - success: `true` if the document was removed; `false` otherwise.  Documents are not
  ///     removed if they do not exist in the collection.
  func didRemove(_ document: Document, at i: Int, success: Bool)

  /// Tells the delegate that all documents will be removed from the collection.
  /// - Returns: `true` if all documents in the collection can be removed; `false` otherwise.
  func willRemoveAll() -> Bool
  
  /// Tells the delegate that all documents were removed from the collection.
  func didRemoveAll()

  /// Tells the delegate that a document will be replaced.
  ///
  /// - Parameters:
  ///   - document: Document to be replaced.
  ///   - with: Document to be used as a replacement.
  ///   - i: Location of document to be replaced.
  /// - Returns: `true` if the document can be replaced; `false` otherwise.
  func willReplace(_ document: Document, with: Document, at i: Int) throws -> Bool

  /// Tells the delegate that a document was replaced.
  ///
  /// - Parameters:
  ///   - document: Document that was replaced.
  ///   - with: Document used as a replacement.
  ///   - i: Location of replaced document.
  ///   - success: `true` if the document was replaced; `false` otherwise.  Documents are not
  ///     replaced if they do not exist in the collection.
  func didReplace(_ document: Document, with: Document, at i: Int, success: Bool)

}

/// `SCOrderedSet` holds `SCDocument` objects.  Documents added to this collection must include a
/// primary key.
///
/// The collection automatically arranges elements by the sort keys.
///
open class SCOrderedSet<Element: SCDocument>: SCJsonObject, SCOrderedSetDelegate {

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
    self.sorting.needsSort = { self.sort() }
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
      try append(element)
    }
  }

  /// Creates an instance of `SCOrderedSet` populated by documents in the array.
  ///
  /// - Parameter array: Documents to be added.
  /// - Throws: `missingId` if a document has no id.
  public convenience init<S: Sequence>(_ sequence: S) throws where S.Iterator.Element == Element {
    self.init()
    for element in sequence {
      try append(element)
    }
  }
  
  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - CustomStringConvertible
   * -----------------------------------------------------------------------------------------------
   */
  
  override open var description: String {
    return String(describing: elements)
  }

  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Document
   * -----------------------------------------------------------------------------------------------
   */
  
  /// Creates a document stub with a valid id.  The id will be randomly generated and unique for
  /// documents in the collection.
  ///
  /// The document will not be added to the collection.  The document needs to be added by either 
  /// `insert()` or `append()`.
  ///
  /// - Parameter id: Optional id to be applied to the document.
  /// - Returns: A document that can be added to the collection.
  /// - Throws: `existingId` the `id` already exists in the collection.  `generateId` if an id could 
  ///           not be generated.
  open func create(withId id: SwiftCollection.Id? = nil) throws -> Element {
    // get an id
    let anId = try generateId(hint: id)
    
    // verify supplied id can be used
    if let id = id {
      // generateId will return the supplied id, unless it already exists.  in that case a new id
      // will be returned
      if anId != id { throw SwiftCollection.Errors.existingId }
    }
    
    // done
    return Element(id: anId)
  }
  
  /// For documents with an id, if the id is not being used in the collection then the document
  /// will be registered with its id.
  ///
  /// Otherwise an id is added to this document.  The id will be randomly generated and unique for 
  /// documents in the collection.
  ///
  /// In either case, the document will not be added to the collection.  The document needs to be
  /// added by either `insert()` or `append()`.
  ///
  /// - Parameters:
  ///   - element: Document to register.
  ///   - hint: Id to be used as a hint.  If it isn't used in the collection, then the document will
  ///     be updated with this id.  Otherwise a new id will be generated.
  /// - Throws: `generateId` if an id could not be generated.
  open func register(_ element: Element, hint id: SwiftCollection.Id? = nil) throws {
    // exit if this element already has an id
    if element.hasId() && !(createdIds.contains(element.id) || ids.contains(element.id)) {
      createdIds.insert(element.id)
      return
    }

    // get an id
    let id = try generateId(hint: id)
    
    // store this id
    element.setId(id)
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
  
  fileprivate func generateId(hint id: SwiftCollection.Id? = nil) throws -> SwiftCollection.Id {
    // get existing ids
    let existing = createdIds.union(ids.set as! Set<SwiftCollection.Id>)
    
    // check if this id can be used
    if let id = id {
      if !existing.contains(id) {
        // remember this id until the document is stored in this collection
        createdIds.insert(id)
        // done
        return id
      }
    }

    // otherwise randomly pick an id
    // limit attempts to generate id
    // TODO: scan for an id if random attempts fail
    var i: Int = Int.max / 10
    repeat {
      let r = SwiftCollection.Id.random()
      if !existing.contains(r) {
        // remember this id until the document is stored in this collection
        createdIds.insert(r)
        // done
        return r
      }
      i -= 1
    } while i > 0
    
    // failed
    throw SwiftCollection.Errors.generateId
  }
  
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
  open func insert(_ document: Element, at i: Int) throws {
    try insert(document, at: i, multipleChanges: false)
  }
  
  /// Adds the document to the collection at the specified index.  Existing documents are ignored.
  ///
  /// - Parameters:
  ///   - document: Document to be added.
  ///   - i: Position to insert the document.  `i` must be a valid index into the collection.
  ///   - multipleChanges: `true` if willStartChanges() and didEndChanges() will be executed from another
  ///     routine; `false` otherwise.  Defuault is `false`.
  /// - Throws: `missingId` if the document has no id.
  fileprivate func insert(_ document: Element, at i: Int, multipleChanges: Bool) throws {
    if !multipleChanges { willStartChanges() }
    
    guard try willInsert(document, at: i) else {
      didInsert(document, at: i, success: false)
      if !multipleChanges { didEndChanges() }
      return
    }

    // ensure the document has an id
    guard document.hasId() else { throw SwiftCollection.Errors.missingId }
    guard !ids.contains(document.id) else {
      didInsert(document, at: i, success: false)
      if !multipleChanges { didEndChanges() }
      return
    }
    
    elements.insert(document, at: i)
    ids.insert(document.id, at: i)
    createdIds.remove(document.id)
    
    didInsert(document, at: i, success: true)
    if !multipleChanges { didEndChanges() }
  }
  
  /// Adds the documents to the end of the collection.
  ///
  /// - Parameters:
  ///   - newDocuments: Documents to be added.
  ///   - i: Position to insert the documents.  `i` must be a valid index into the collection.
  /// - Throws: `missingId` if a document has no id.
  open func insert<C : Collection>(contentsOf newDocuments: C, at i: Int) throws where C.Iterator.Element == Element {
    willStartChanges()
    let newTotal = ids.count + Int(newDocuments.count.toIntMax())
    elements.reserveCapacity(newTotal)
    for d in newDocuments.reversed() {
      try self.insert(d, at: i, multipleChanges: true)
    }
    didEndChanges()
  }

  /// Adds the document to the end of the collection.
  ///
  /// - Parameters:
  ///   - document: Document to be added.
  /// - Throws: `missingId` if the document has no id.
  open func append(_ document: Element) throws {
    try append(document, multipleChanges: false)
  }
  
  /// Adds the document to the end of the collection.
  ///
  /// - Parameters:
  ///   - document: Document to be added.
  ///   - multipleChanges: `true` if willStartChanges() and didEndChanges() will be executed from another
  ///     routine; `false` otherwise.  Defuault is `false`.
  /// - Throws: `missingId` if the document has no id.
  fileprivate func append(_ document: Element, multipleChanges: Bool) throws {
    if !multipleChanges { willStartChanges() }
    guard try willAppend(document) else {
      didAppend(document, success: false)
      if !multipleChanges { didEndChanges() }
      return
    }
    
    // ensure the document has an id
    guard document.hasId() else { throw SwiftCollection.Errors.missingId }
    guard !ids.contains(document.id) else {
      didAppend(document, success: false)
      if !multipleChanges { didEndChanges() }
      return
    }

    elements.append(document)
    ids.add(document.id)
    createdIds.remove(document.id)

    didAppend(document, success: true)
    if !multipleChanges { didEndChanges() }
  }
  
  /// Adds documents to the end of the collection.  Existing documents are ignored.
  ///
  /// - Parameter newDocuments: A collection of documents to be added.
  /// - Throws: `missingId` if a document has no id.
  open func append<C : Collection>(contentsOf newDocuments: C) throws where C.Iterator.Element == Element {
    willStartChanges()
    let newTotal = ids.count + Int(newDocuments.count.toIntMax())
    elements.reserveCapacity(newTotal)
    for d in newDocuments {
      if ids.contains(d.id) { continue }
      try self.append(d, multipleChanges: true)
    }
    didEndChanges()
  }

  /// Inserts the document into the collection based on the default sort.  If there is no sort, then
  /// the document is added to the end of the collection.
  ///
  /// - Parameters:
  ///   - document: Document to be added.
  /// - Throws: `missingId` if the document has no id.
  open func add(_ document: Element) throws {
    try add(document, multipleChanges: false)
  }
  
  /// Inserts the document into the collection based on the default sort.  If there is no sort, then
  /// the document is added to the end of the collection.
  ///
  /// - Parameters:
  ///   - document: Document to be added.
  ///   - multipleChanges: `true` if willStartChanges() and didEndChanges() will be executed from another
  ///     routine; `false` otherwise.  Defuault is `false`.
  /// - Throws: `missingId` if the document has no id.
  fileprivate func add(_ document: Element, multipleChanges: Bool) throws {
    if !multipleChanges { willStartChanges() }
    
    // get location to insert
    let i = sortedIndex(document)
    
    guard try willAdd(document, at: i) else {
      didAdd(document, at: i, success: false)
      if !multipleChanges { didEndChanges() }
      return
    }
    
    // ensure the document has an id
    guard document.hasId() else { throw SwiftCollection.Errors.missingId }
    guard !ids.contains(document.id) else {
      didAdd(document, at: i, success: false)
      if !multipleChanges { didEndChanges() }
      return
    }
    
    elements.insert(document, at: i)
    ids.insert(document.id, at: i)
    createdIds.remove(document.id)
    
    didAdd(document, at: i, success: true)
    if !multipleChanges { didEndChanges() }
  }
  
  /// Inserts the documents into the collection based on the default sort.  If there is no sort,
  /// then the documents are added to the end of the collection.
  ///
  /// - Parameter newDocuments: A collection of documents to be added.
  /// - Throws: `missingId` if a document has no id.
  open func add<C : Collection>(contentsOf newDocuments: C) throws where C.Iterator.Element == Element {
    willStartChanges()
    let newTotal = ids.count + Int(newDocuments.count.toIntMax())
    elements.reserveCapacity(newTotal)
    for d in newDocuments {
      if ids.contains(d.id) { continue }
      try self.add(d, multipleChanges: true)
    }
    didEndChanges()
  }

  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Remove
   * -----------------------------------------------------------------------------------------------
   */

  /// Removes the document from the collection.
  ///
  /// - Parameters:
  ///   - document: Document to be removed.
  open func remove(_ document: Element) -> Element? {
    return remove(document, multipleChanges: false)
  }
  
  /// Removes the document from the collection.
  ///
  /// - Parameters:
  ///   - document: Document to be removed.
  ///   - multipleChanges: `true` if willStartChanges() and didEndChanges() will be executed from another
  ///     routine; `false` otherwise.  Defuault is `false`.
  fileprivate func remove(_ document: Element, multipleChanges: Bool) -> Element? {
    if !multipleChanges { willStartChanges() }
    guard willRemove(document) else {
      didRemove(document, at: NSNotFound, success: false)
      if !multipleChanges { didEndChanges() }
      return nil
    }
    var removed: Element?
    if let i = index(of: document) {
      removed = elements.remove(at: i.index)
      ids.removeObject(at: i.index)
      didRemove(document, at: i.index, success: true)
    } else {
      didRemove(document, at: NSNotFound, success: false)
    }
    createdIds.remove(document.id)
    if !multipleChanges { didEndChanges() }
    return removed
  }
 
  /// Removes documents from the collection.
  ///
  /// - Parameter newDocuments: A collection of documents to be removed.
  /// - Throws: `missingId` if a document has no id.
  open func remove<C : Collection>(contentsOf newDocuments: C) -> [Element] where C.Iterator.Element == Element {
    willStartChanges()
    var removed: [Element] = []
    for d in newDocuments {
      if let r = remove(d, multipleChanges: true) {
        removed.append(r)
      }
    }
    didEndChanges()
    return removed
  }

  /// Removes all documents from the collection.
  open func removeAll() {
    willStartChanges()
    guard willRemoveAll() else { return }
    elements.removeAll()
    ids.removeAllObjects()
    createdIds.removeAll()
    didRemoveAll()
    didEndChanges()
  }

  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Replace
   * -----------------------------------------------------------------------------------------------
   */
  
  /// Replaces document with the new document.
  ///
  /// The id of the new document will be replaced by the id of the existing document.
  ///
  /// - Parameters:
  ///   - document: Document to be replaced.
  ///   - with: Document to be used as a replacement.
  /// - Throws: `notFound` if the document does not exist in the collection.
  open func replace(_ document: Element, with: Element) throws {
    guard let i = elements.index(of: document) else { throw SwiftCollection.Errors.notFound }
    try replace(at: i, with: with)
  }
  
  /// Replaces document at the specified index with the new document.
  ///
  /// The id of the new document will be replaced by the id of the existing document.
  ///
  /// - Parameters:
  ///   - i: Location of document to be replaced.
  ///   - with: Document to be used as a replacement.
  /// - Throws: `notFound` if the document does not exist in the collection.
  open func replace(at index: Index, with: Element) throws {
    try replace(at: index.index, with: with)
  }

  /// Replaces document at the specified index with the new document.
  ///
  /// The id of the new document will be replaced by the id of the existing document.
  ///
  /// - Parameters:
  ///   - i: Location of document to be replaced.
  ///   - with: Document to be used as a replacement.
  /// - Throws: `notFound` if the document does not exist in the collection.
  open func replace(at i: Int, with: Element) throws {
    guard (0..<elements.count).contains(i) else { throw SwiftCollection.Errors.notFound }
    willStartChanges()
    let existing = elements[i]
    guard try willReplace(existing, with: with, at: i) else {
      didReplace(existing, with: with, at: i, success: false)
      return
    }
    with.setId(existing.id)
    elements[i] = with
    didReplace(existing, with: with, at: i, success: true)
    didEndChanges()
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
      if !set.contains(element) { try set.append(element) }
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

  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Sort
   * -----------------------------------------------------------------------------------------------
   */

  public class Sort {
    
    public typealias SortId = String
    
    /// Tests whether `e1` should be ordered before `e2`.
    ///
    /// - Parameters:
    ///   - e1: First argument.
    ///   - e2: Second argument.
    /// - Returns: `true` if `e1` should be ordered before `e2`; `false` otherwise.
    public typealias SortComparator = (_ e1: Element, _ e2: Element) -> Bool
    
    fileprivate var needsSort: (() -> Void)?
    
    /// Default sort identifier to be used when adding an element to this collection.
    public var sortId: SortId? {
      get {
        return _sortId
      }
      set {
        _sortId = newValue
        if let needsSort = self.needsSort { needsSort() }
      }
    }
    fileprivate var _sortId: SortId?
    
    /// Returns a sort comparator for this sort id.
    ///
    /// - Parameter sortId: Sort id to be used.
    /// - Returns: The sort comparator for this id.
    public func comparator(_ sortId: SortId? = nil) -> SortComparator? {
      let aSortId = sortId ?? self.sortId
      guard aSortId != nil else { return nil }
      return sortComparators[aSortId!]
    }
    fileprivate var sortComparators: [SortId: SortComparator] = [:]
    
    /// Adds a sort comparator for this sort id.
    ///
    /// - Parameters:
    ///   - sortId: Sort id to be used.
    ///   - comparator: The sort comparator to be added.
    public func add(_ sortId: SortId, comparator: @escaping SortComparator) {
      sortComparators[sortId] = comparator
      guard let needsSort = self.needsSort else { return }
      guard let aSortId = self.sortId else { return }
      if aSortId == sortId { needsSort() }
    }
    
    /// Removes a sort comparator for this sort id.
    ///
    /// - Parameter sortId: Sort id to be removed.
    public func remove(_ sortId: SortId) {
      sortComparators.removeValue(forKey: sortId)
    }
    
    /// Removes all sort comparators.
    public func removeAll() {
      sortComparators.removeAll()
    }
    
  }
  
  /// Default sort and sorting comparators for the collection.
  public var sorting = Sort()
  
  /// Returns the index in the collection to add this document using the default sort.
  ///
  /// - Parameter document: Document to add.
  /// - Returns: Index to insert; or the end index of the collection.
  fileprivate func sortedIndex(_ document: Element) -> Int {
    // if there is no comparator, then return index for end of collection.
    guard let c = sorting.comparator() else { return elements.endIndex }
    // if there are no documents, then return index for end of collection.
    guard elements.count > 0 else { return elements.endIndex }
    // check if the document should be last.
    if !c(document, elements.last!) { return elements.endIndex }
    // find the location in the collection.
    for (i, element) in elements.enumerated() {
      if !c(document, element) { continue }
      return i
    }
    // otherwise return the end index of the collection
    return elements.endIndex
  }
  
  public func sort() {
    guard let c = sorting.comparator() else { return }
    self.elements = self.sorted(by: c)
    self.ids.removeAllObjects()
    for element in elements {
      ids.add(element.id)
    }
  }

  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Delegate
   * -----------------------------------------------------------------------------------------------
   */
  
  public typealias Document = Element

  open func willStartChanges() { }

  open func didEndChanges() { }
  
  open func willInsert(_ document: Document, at i: Int) throws -> Bool { return true }
  
  open func didInsert(_ document: Document, at i: Int, success: Bool) { }
  
  open func willAppend(_ document: Document) throws -> Bool { return true }
  
  open func didAppend(_ document: Document, success: Bool) { }

  open func willAdd(_ document: Document, at i: Int) throws -> Bool { return true }
  
  open func didAdd(_ document: Document, at i: Int, success: Bool) { }
  
  open func willRemove(_ document: Document) -> Bool { return true }
  
  open func didRemove(_ document: Document, at i: Int, success: Bool) { }
  
  open func willRemoveAll() -> Bool { return true }
  
  open func didRemoveAll() { }
  
  open func willReplace(_ document: Element, with: Element, at i: Int) throws -> Bool { return true }

  open func didReplace(_ document: Element, with: Element, at i: Int, success: Bool) { }
  
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
