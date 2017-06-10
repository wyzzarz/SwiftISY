//
//  SwiftCollectionOrderedSetTests.swift
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

import XCTest
@testable import SwiftCollection

class SwiftCollectionOrderedSetTests: XCTestCase {
  
  // documents
  final class NamedDocument: SCDocument {
    
    var name: String = ""
    
    convenience init(id: SwiftCollection.Id, name: String) {
      self.init(id: id)
      self.name = name
    }
    
    override var description: String {
      return String(describing: "\(String(describing: type(of: self)))(\(id),\(name))")
    }
    
  }
  let docNone = NamedDocument(id: 0x0, name: "None")
  let docA = NamedDocument(id: 0x1, name: "A")
  let docB = NamedDocument(id: 0xA, name: "B")
  let docC = NamedDocument(id: 0xF, name: "C")
  let docD = NamedDocument(id: 0xFF, name: "D")

  // persisted sets
  class PersistedSet: SCOrderedSet<NamedDocument> {
    
    override func load(jsonObject json: AnyObject) throws -> AnyObject? {
      if let array = json as? [AnyObject] {
        for item in array {
          try? append(NamedDocument(json: item))
        }
      }
      return json
    }
    
  }
  var set1 = PersistedSet()
  var set2 = PersistedSet()
  
  // sorted sets
  class SortedSet: PersistedSet {
    
    let name = SCOrderedSet.Sort.SortId("name")!
    let rname = SCOrderedSet.Sort.SortId("rname")!
    
    required init() {
      super.init()
      sorting.sortId = name
      sorting.add(name) { (doc1, doc2) -> Bool in
        return (doc1).name.compare((doc2).name) == .orderedAscending
      }
      sorting.add(rname) { (doc1, doc2) -> Bool in
        return (doc2).name.compare((doc1).name) == .orderedAscending
      }
    }
    
    required init(json: AnyObject) throws {
      try super.init(json: json)
    }
    
  }
  
  // delegate sets
  final class DelegateSet: SCOrderedSet<NamedDocument> {
    var willStartCount: Int = 0
    var didEndCount: Int = 0
    var willCount: Int = 0
    var didCount: Int = 0
    var successes: Int = 0
    var failures: Int = 0
    func resetCounts() {
      willStartCount = 0
      didEndCount = 0
      willCount = 0
      didCount = 0
      successes = 0
      failures = 0
    }
    override func willStartChanges() {
      willStartCount += 1
    }
    override func didEndChanges() {
      didEndCount += 1
    }
    override func willInsert(_ document: Document, at i: Int) throws -> Bool {
      willCount += 1
      return try super.willInsert(document, at: i)
    }
    override func didInsert(_ document: Document, at i: Int, success: Bool) {
      didCount += 1
      if success { successes += 1 } else { failures += 1 }
    }
    override func willAppend(_ document: Document) throws -> Bool {
      willCount += 1
      return try super.willAppend(document)
    }
    override func didAppend(_ document: Document, success: Bool) {
      didCount += 1
      if success { successes += 1 } else { failures += 1 }
    }
    override func willAdd(_ document: Document, at i: Int) throws -> Bool {
      willCount += 1
      return try super.willAdd(document, at: i)
    }
    override func didAdd(_ document: Document, at i: Int, success: Bool) {
      didCount += 1
      if success { successes += 1 } else { failures += 1 }
    }
    override func willRemove(_ document: Document) -> Bool {
      willCount += 1
      return super.willRemove(document)
    }
    override func didRemove(_ document: Document, at i: Int, success: Bool) {
      didCount += 1
      if success { successes += 1 } else { failures += 1 }
    }
    override func willRemoveAll() -> Bool {
      willCount += 1
      return super.willRemoveAll()
    }
    override func didRemoveAll() {
      didCount += 1
    }
    override func willReplace(_ document: Document, with: Document, at i: Int) throws -> Bool {
      willCount += 1
      return try super.willReplace(document, with: with, at: i)
    }
    override func didReplace(_ document: Document, with: Document, at i: Int, success: Bool) {
      didCount += 1
      if success { successes += 1 } else { failures += 1 }
    }
  }

  override func setUp() {
    super.setUp()
    set1.removeAll()
    set2.removeAll()
  }
  
  override func tearDown() {
    try? set1.remove(jsonStorage: .userDefaults, completion: nil)
    super.tearDown()
  }
  
  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Document
   * -----------------------------------------------------------------------------------------------
   */

  func testCreateDocument() {
    let doc1 = try! set1.create()
    XCTAssertNotNil(doc1)
    XCTAssertGreaterThan(doc1.id, 0)
    XCTAssertThrowsError(try set1.create(withId: doc1.id))
    let doc2 = try! set1.create(withId: 2)
    XCTAssertEqual(doc2.id, 2)
  }
  
  func testRegisterDocument() {
    // register an empty document
    let doc1 = NamedDocument()
    XCTAssertEqual(doc1.id, 0)
    try? set1.register(doc1)
    XCTAssertGreaterThan(doc1.id, 0)
    
    // register a document with an existing id
    let doc2 = NamedDocument(id: doc1.id > 1000 ? 1000 : 1001)
    try? set1.register(doc2)
    
    // register a document with a hint for an existing id
    let doc3 = NamedDocument()
    XCTAssertEqual(doc3.id, 0)
    try? set1.register(doc3, hint: doc2.id)
    XCTAssertNotEqual(doc3.id, doc2.id)
  }
  
  func testRegisterNonExistingHint() {
    // register an empty document
    let doc1 = NamedDocument()
    try? set1.register(doc1)
    
    // register a document with a hint for a new id
    let id2: SwiftCollection.Id = doc1.id > 1000 ? 1000 : 1001
    let doc2 = NamedDocument()
    try? set1.register(doc2, hint: id2)
    XCTAssertEqual(doc2.id, id2)
  }
  
  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Document Id
   * -----------------------------------------------------------------------------------------------
   */

  func testId() {
    try! set1.append(contentsOf: [docA, docB, docC])
    XCTAssertEqual(set1.firstId, docA.id)
    XCTAssertEqual(set1.id(after: set1.firstId), docB.id)
    XCTAssertEqual(set1.id(before: set1.lastId), docB.id)
    XCTAssertEqual(set1.lastId, docC.id)
    
  }

  func testContainsId() {
    try! set1.append(contentsOf: [docA, docB, docC])
    XCTAssertTrue(set1.contains(id: docA.id))
    XCTAssertFalse(set1.contains(id: docD.id))
  }
  
  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Sequence
   * -----------------------------------------------------------------------------------------------
   */
  
  func testSequence() {
    let arr = try! SCOrderedSet<NamedDocument>([docA, docB, docC])
    XCTAssertEqual(arr.count, 3)
    for (i, e) in arr.enumerated() {
      switch i {
      case 0: XCTAssertEqual(e, docA)
      case 1: XCTAssertEqual(e, docB)
      case 2: XCTAssertEqual(e, docC)
      default: break
      }
    }
  }

  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Collection
   * -----------------------------------------------------------------------------------------------
   */

  func testCollection() {
    let arr = try! SCOrderedSet<NamedDocument>([docA, docB, docC])
    XCTAssertEqual(arr[arr.startIndex], docA)
    XCTAssertEqual(arr[arr.index(arr.startIndex, offsetBy: 1)], docB)
    XCTAssertEqual(arr[arr.index(arr.startIndex, offsetBy: 2)], docC)
    XCTAssertEqual(arr[arr.index(arr.endIndex, offsetBy: -1)], docC)
  }
  
  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Add
   * -----------------------------------------------------------------------------------------------
   */
  
  func testEmptyDocument() {
    XCTAssertThrowsError(try set1.append(docNone))
  }

  func testAppendDocument() {
    try! set1.append(docA)
    try! set1.append(docB)
    XCTAssertEqual(set1.count, 2)
    XCTAssertEqual(set1.first, docA)
    XCTAssertEqual(set1.last, docB)
  }

  func testAppendDocuments() {
    try! set1.append(docA)
    try! set1.append(contentsOf: [docB, docC])
    XCTAssertEqual(set1.count, 3)
    XCTAssertEqual(set1.first, docA)
    XCTAssertEqual(set1[set1.index(set1.startIndex, offsetBy: 1)], docB)
    XCTAssertEqual(set1.last, docC)
  }
  
  func testInsertDocument() {
    try! set1.insert(docC, at: 0)
    try! set1.insert(docB, at: 0)
    try! set1.insert(docA, at: 0)
    XCTAssertEqual(set1.count, 3)
    XCTAssertEqual(set1.first, docA)
    XCTAssertEqual(set1[set1.index(set1.startIndex, offsetBy: 1)], docB)
    XCTAssertEqual(set1.last, docC)
  }
  
  func testInsertDocuments() {
    try! set1.insert(docC, at: 0)
    try! set2.insert(docB, at: 0)
    try! set2.insert(docA, at: 0)
    try! set1.insert(contentsOf: set2, at: 0)
    XCTAssertEqual(set1.count, 3)
    XCTAssertEqual(set2.count, 2)
    XCTAssertEqual(set1.first, docA)
    XCTAssertEqual(set1[set1.index(set1.startIndex, offsetBy: 1)], docB)
    XCTAssertEqual(set1.last, docC)
  }

  func testAddReversedDocuments() {
    let set = SortedSet()
    
    // sort by reversed name
    set.sorting.sortId = set.rname
    let c = set.sorting.comparator()
    XCTAssertNotNil(c)
    XCTAssertEqual(set.sorting.sortId, set.rname)
    try! set.add(docC)
    try! set.add(contentsOf: [docD, docA, docB])
    XCTAssertEqual(set.count, 4)
    XCTAssertEqual(set.first, docD)
    XCTAssertEqual(set[set.index(set.startIndex, offsetBy: 1)], docC)
    XCTAssertEqual(set[set.index(set.startIndex, offsetBy: 2)], docB)
    XCTAssertEqual(set.last, docA)
  }

  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Remove
   * -----------------------------------------------------------------------------------------------
   */
  
  func testRemoveDocument() {
    let set = try! SCOrderedSet<NamedDocument>([docA, docB, docC])
    XCTAssertEqual(set.count, 3)
    _ = set.remove(docB)
    XCTAssertEqual(set.count, 2)
    try! set.append(docB)
    XCTAssertEqual(set.count, 3)
  }

  func testRemoveDocuments() {
    let set = try! SCOrderedSet<NamedDocument>([docA, docB, docC])
    XCTAssertEqual(set.count, 3)
    _ = set.remove(contentsOf: [docA, docC])
    XCTAssertEqual(set.count, 1)
    XCTAssertEqual(set.last, docB)
  }

  func testRemoveAllDocuments() {
    let set = try! SCOrderedSet<NamedDocument>([docA, docB, docC])
    XCTAssertEqual(set.count, 3)
    set.removeAll()
    XCTAssertEqual(set.count, 0)
  }
  
  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Replace
   * -----------------------------------------------------------------------------------------------
   */
  
  func testReplaceDocument() {
    let set = try! SCOrderedSet<NamedDocument>([docA, docB, docC])
    XCTAssertEqual(set.count, 3)
    try! set.replace(docB, with: NamedDocument(id: 0xAF, name: "Z"))
    XCTAssertEqual(set.first, docA)
    XCTAssertEqual(set.last, docC)
    let replaced = set[set.index(after: set.startIndex)]
    XCTAssertEqual(replaced.id, docB.id)
    XCTAssertEqual(replaced.name, "Z")
  }

  func testReplaceDocumentAtIndex1() {
    let set = try! SCOrderedSet<NamedDocument>([docA, docB, docC])
    XCTAssertEqual(set.count, 3)
    try! set.replace(at: 1, with: NamedDocument(id: 0xAF, name: "Z"))
    XCTAssertEqual(set.first, docA)
    XCTAssertEqual(set.last, docC)
    let replaced = set[set.index(after: set.startIndex)]
    XCTAssertEqual(replaced.id, docB.id)
    XCTAssertEqual(replaced.name, "Z")
  }

  func testReplaceDocumentAtIndex2() {
    let set = try! SCOrderedSet<NamedDocument>([docA, docB, docC])
    XCTAssertEqual(set.count, 3)
    let i = set.index(after: set.startIndex)
    try! set.replace(at: i, with: NamedDocument(id: 0xAF, name: "Z"))
    XCTAssertEqual(set.first, docA)
    XCTAssertEqual(set.last, docC)
    let replaced = set[i]
    XCTAssertEqual(replaced.id, docB.id)
    XCTAssertEqual(replaced.name, "Z")
  }
  
  func testReplaceMissingDocument() {
    let set = try! SCOrderedSet<NamedDocument>([docA, docB, docC])
    XCTAssertThrowsError(try set.replace(docD, with: NamedDocument(id: 0xAF, name: "Z")))
  }

  func testReplaceOutOfBoundsDocument() {
    let set = try! SCOrderedSet<NamedDocument>([docA, docB, docC])
    XCTAssertThrowsError(try set.replace(at: -1, with: NamedDocument(id: 0xAF, name: "Z")))
    XCTAssertThrowsError(try set.replace(at: set.count, with: NamedDocument(id: 0xAF, name: "Z")))
  }

  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Combine
   * -----------------------------------------------------------------------------------------------
   */

  func testUnion() {
    try! set1.append(contentsOf: [docA, docB, docC])
    try! set2.append(contentsOf: [docC, docD])
    let set = try! set1.union(set2)
    XCTAssertEqual(set.count, 4)
    XCTAssertEqual(set.first, docA)
    XCTAssertEqual(set.last, docD)
  }

  func testInterset() {
    try! set1.append(contentsOf: [docA, docB, docC])
    try! set2.append(contentsOf: [docC, docB, docD])
    set1.intersect(set2)
    XCTAssertEqual(set1.count, 2)
    XCTAssertEqual(set1.first, docB)
    XCTAssertEqual(set1.last, docC)
  }

  func testMinus() {
    try! set1.append(contentsOf: [docA, docB, docC])
    try! set2.append(contentsOf: [docC, docD])
    set1.minus(set2)
    XCTAssertEqual(set1.count, 2)
    XCTAssertEqual(set1.first, docA)
    XCTAssertEqual(set1.last, docB)
  }
  
  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Sort
   * -----------------------------------------------------------------------------------------------
   */

  func testSort() {
    let set = PersistedSet()
    let sorting = set.sorting

    // test defaults
    XCTAssertNil(sorting.sortId)
    XCTAssertNil(sorting.comparator())
    
    // test default sort id
    let name = SCOrderedSet.Sort.SortId("name")!
    sorting.sortId = name
    XCTAssertEqual(sorting.sortId, name)
    
    // test comparator
    XCTAssertNil(sorting.comparator(name))
    let c: (NamedDocument, NamedDocument) -> Bool = { (doc1, doc2) -> Bool in
      return (doc1).name.compare((doc2).name) != .orderedDescending
    }
    sorting.add(name, comparator: c)
    let comparator = sorting.comparator(name)
    XCTAssertNotNil(comparator)
    XCTAssertTrue(comparator!(docA, docB))
    XCTAssertFalse(comparator!(docC, docB))
    XCTAssertTrue(comparator!(docB, docB))
    
    // test default comparator
    XCTAssertNotNil(sorting.comparator())
    sorting.sortId = nil
    XCTAssertNil(sorting.comparator())
    
    // test remove
    let reversedName = SCOrderedSet.Sort.SortId("reversedName")!
    sorting.add(reversedName) { (doc1, doc2) -> Bool in
      return (doc2).name.compare((doc1).name) != .orderedDescending
    }
    XCTAssertNotNil(sorting.comparator(reversedName))
    sorting.remove(reversedName)
    XCTAssertNil(sorting.comparator(reversedName))
    
    // test remove all
    sorting.removeAll()
    XCTAssertNil(sorting.comparator(name))
  }
  
  func testSortedAddDocument() {
    let set = SortedSet()
    let c = set.sorting.comparator()
    XCTAssertNotNil(c)
    XCTAssertEqual(set.sorting.sortId, set.name)
    try! set.add(docD)
    try! set.add(docC)
    XCTAssertEqual(set.count, 2)
    XCTAssertEqual(set.first, docC)
    XCTAssertEqual(set.last, docD)
  }
  
  func testSortedAddDocuments() {
    let set = SortedSet()
    let c = set.sorting.comparator()
    XCTAssertNotNil(c)
    XCTAssertEqual(set.sorting.sortId, set.name)
    try! set.add(docC)
    try! set.add(contentsOf: [docD, docA, docB])
    XCTAssertEqual(set.count, 4)
    XCTAssertEqual(set.first, docA)
    XCTAssertEqual(set[set.index(set.startIndex, offsetBy: 1)], docB)
    XCTAssertEqual(set[set.index(set.startIndex, offsetBy: 2)], docC)
    XCTAssertEqual(set.last, docD)
  }

  func testChangeSort() {
    // default sort by name
    let set = SortedSet()
    try! set.add(contentsOf: [docD, docC, docA, docB])
    XCTAssertEqual(set.count, 4)
    XCTAssertEqual(set.first, docA)
    XCTAssertEqual(set[set.index(set.startIndex, offsetBy: 1)], docB)
    XCTAssertEqual(set[set.index(set.startIndex, offsetBy: 2)], docC)
    XCTAssertEqual(set.last, docD)
    // sort by name, reversed
    set.sorting.sortId = set.rname
    XCTAssertEqual(set.count, 4)
    XCTAssertEqual(set.first, docD)
    XCTAssertEqual(set[set.index(set.startIndex, offsetBy: 1)], docC)
    XCTAssertEqual(set[set.index(set.startIndex, offsetBy: 2)], docB)
    XCTAssertEqual(set.last, docA)
  }
  
  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Delegate
   * -----------------------------------------------------------------------------------------------
   */

  func testInsertDelegate() {
    let set = DelegateSet()
    
    try! set.insert(docA, at: 0)
    XCTAssertEqual(set.willStartCount, 1)
    XCTAssertEqual(set.didEndCount, 1)
    XCTAssertEqual(set.willCount, 1)
    XCTAssertEqual(set.didCount, 1)
    XCTAssertEqual(set.successes, 1)
    XCTAssertEqual(set.failures, 0)
    
    try! set.insert(docA, at: 0)
    XCTAssertEqual(set.willStartCount, 2)
    XCTAssertEqual(set.didEndCount, 2)
    XCTAssertEqual(set.willCount, 2)
    XCTAssertEqual(set.didCount, 2)
    XCTAssertEqual(set.successes, 1)
    XCTAssertEqual(set.failures, 1)
    
    try! set.insert(contentsOf: [docB, docC], at: 0)
    XCTAssertEqual(set.willStartCount, 3)
    XCTAssertEqual(set.didEndCount, 3)
    XCTAssertEqual(set.willCount, 4)
    XCTAssertEqual(set.didCount, 4)
    XCTAssertEqual(set.successes, 3)
    XCTAssertEqual(set.failures, 1)
  }

  func testAppendDelegate() {
    let set = DelegateSet()

    try! set.append(docA)
    XCTAssertEqual(set.willStartCount, 1)
    XCTAssertEqual(set.didEndCount, 1)
    XCTAssertEqual(set.willCount, 1)
    XCTAssertEqual(set.didCount, 1)
    XCTAssertEqual(set.successes, 1)
    XCTAssertEqual(set.failures, 0)

    try! set.append(docA)
    XCTAssertEqual(set.willStartCount, 2)
    XCTAssertEqual(set.didEndCount, 2)
    XCTAssertEqual(set.willCount, 2)
    XCTAssertEqual(set.didCount, 2)
    XCTAssertEqual(set.successes, 1)
    XCTAssertEqual(set.failures, 1)
    
    try! set.append(contentsOf: [docB, docC])
    XCTAssertEqual(set.willStartCount, 3)
    XCTAssertEqual(set.didEndCount, 3)
    XCTAssertEqual(set.willCount, 4)
    XCTAssertEqual(set.didCount, 4)
    XCTAssertEqual(set.successes, 3)
    XCTAssertEqual(set.failures, 1)
  }
  
  func testAddDelegate() {
    let set = DelegateSet()
    
    try! set.add(docA)
    XCTAssertEqual(set.willStartCount, 1)
    XCTAssertEqual(set.didEndCount, 1)
    XCTAssertEqual(set.willCount, 1)
    XCTAssertEqual(set.didCount, 1)
    XCTAssertEqual(set.successes, 1)
    XCTAssertEqual(set.failures, 0)
    
    try! set.add(docA)
    XCTAssertEqual(set.willStartCount, 2)
    XCTAssertEqual(set.didEndCount, 2)
    XCTAssertEqual(set.willCount, 2)
    XCTAssertEqual(set.didCount, 2)
    XCTAssertEqual(set.successes, 1)
    XCTAssertEqual(set.failures, 1)
    
    try! set.add(contentsOf: [docB, docC])
    XCTAssertEqual(set.willStartCount, 3)
    XCTAssertEqual(set.didEndCount, 3)
    XCTAssertEqual(set.willCount, 4)
    XCTAssertEqual(set.didCount, 4)
    XCTAssertEqual(set.successes, 3)
    XCTAssertEqual(set.failures, 1)
  }

  func testRemoveDelegate() {
    let set = DelegateSet()

    try! set.append(contentsOf: [docA, docB, docC, docD])
    XCTAssertEqual(set.willStartCount, 1)
    XCTAssertEqual(set.didEndCount, 1)
    XCTAssertEqual(set.willCount, 4)
    XCTAssertEqual(set.didCount, 4)
    XCTAssertEqual(set.successes, 4)
    XCTAssertEqual(set.failures, 0)

    set.resetCounts()
    XCTAssertEqual(set.willStartCount, 0)
    XCTAssertEqual(set.didEndCount, 0)
    XCTAssertEqual(set.willCount, 0)
    XCTAssertEqual(set.didCount, 0)
    XCTAssertEqual(set.successes, 0)
    XCTAssertEqual(set.failures, 0)

    let removed = set.remove(docA)
    XCTAssertEqual(removed, docA)
    XCTAssertEqual(set.didEndCount, 1)
    XCTAssertEqual(set.willCount, 1)
    XCTAssertEqual(set.willCount, 1)
    XCTAssertEqual(set.didCount, 1)
    XCTAssertEqual(set.successes, 1)
    XCTAssertEqual(set.failures, 0)
    
    let notRemoved = set.remove(docA)
    XCTAssertNil(notRemoved)
    XCTAssertEqual(set.willStartCount, 2)
    XCTAssertEqual(set.didEndCount, 2)
    XCTAssertEqual(set.willCount, 2)
    XCTAssertEqual(set.didCount, 2)
    XCTAssertEqual(set.successes, 1)
    XCTAssertEqual(set.failures, 1)
    
    let removes = set.remove(contentsOf: [docB, docC])
    XCTAssertEqual(removes, [docB, docC])
    XCTAssertEqual(set.willStartCount, 3)
    XCTAssertEqual(set.didEndCount, 3)
    XCTAssertEqual(set.willCount, 4)
    XCTAssertEqual(set.didCount, 4)
    XCTAssertEqual(set.successes, 3)
    XCTAssertEqual(set.failures, 1)
  }
  
  func testRemoveAllDelegate() {
    let set = DelegateSet()
    
    try! set.append(contentsOf: [docA, docB, docC, docD])
    XCTAssertEqual(set.willStartCount, 1)
    XCTAssertEqual(set.didEndCount, 1)
    XCTAssertEqual(set.willCount, 4)
    XCTAssertEqual(set.didCount, 4)
    XCTAssertEqual(set.successes, 4)
    XCTAssertEqual(set.failures, 0)
    
    set.resetCounts()
    XCTAssertEqual(set.willStartCount, 0)
    XCTAssertEqual(set.didEndCount, 0)
    XCTAssertEqual(set.willCount, 0)
    XCTAssertEqual(set.didCount, 0)
    XCTAssertEqual(set.successes, 0)
    XCTAssertEqual(set.failures, 0)

    set.removeAll()
    XCTAssertEqual(set.didEndCount, 1)
    XCTAssertEqual(set.willCount, 1)
    XCTAssertEqual(set.willCount, 1)
    XCTAssertEqual(set.didCount, 1)
    XCTAssertEqual(set.successes, 0)
    XCTAssertEqual(set.failures, 0)
  }

  func testReplaceDelegate() {
    let set = DelegateSet()
    
    try! set.append(contentsOf: [docA, docB, docC, docD])
    XCTAssertEqual(set.willStartCount, 1)
    XCTAssertEqual(set.didEndCount, 1)
    XCTAssertEqual(set.willCount, 4)
    XCTAssertEqual(set.didCount, 4)
    XCTAssertEqual(set.successes, 4)
    XCTAssertEqual(set.failures, 0)
    
    set.resetCounts()

    try! set.replace(at: 1, with: NamedDocument(id: 0xAF, name: "Z"))
    XCTAssertEqual(set.willStartCount, 1)
    XCTAssertEqual(set.didEndCount, 1)
    XCTAssertEqual(set.willCount, 1)
    XCTAssertEqual(set.didCount, 1)
    XCTAssertEqual(set.successes, 1)
    XCTAssertEqual(set.failures, 0)
  }
  
  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Persistence
   * -----------------------------------------------------------------------------------------------
   */
  
  func testPersistence() {
    // create expectations
    let se = expectation(description: "Save Failed.")
    let le = self.expectation(description: "Load Failed.")
    
    try! set1.append(contentsOf: [docA, docB, docC])
    
    let load = {
      XCTAssertEqual(self.set2.count, 0)
      try! self.set2.load(jsonStorage: .userDefaults, completion: { (success, json) in
        le.fulfill()
        XCTAssertEqual(self.set2.count, 3)
        XCTAssertEqual(self.set2.first, self.docA)
        XCTAssertEqual(self.set2.last, self.docC)
      })
    }
    
    try! set1.save(jsonStorage: .userDefaults) { (success) in
      se.fulfill()
      XCTAssertTrue(success)
      if (success) {
        load()
      }
    }
    
    // wait for save and load
    waitForExpectations(timeout: 60) { (error) in
      if let error = error {
        XCTFail("Save Failed: \(error.localizedDescription)")
      }
    }
  }

}
