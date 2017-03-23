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
  let docNone = SCDocument(id: 0x0)
  let docA = SCDocument(id: 0x1)
  let docB = SCDocument(id: 0xA)
  let docC = SCDocument(id: 0xF)
  let docD = SCDocument(id: 0xFF)

  // sets
  class PersistedSet: SCOrderedSet<SCDocument>, SCJsonProtocol {
    public func load(jsonObject json: AnyObject) throws -> AnyObject? {
      if let array = json as? [AnyObject] {
        for item in array {
          try? append(document: SCDocument(json: item))
        }
      }
      return json
    }
  }
  var set1 = PersistedSet()
  var set2 = PersistedSet()

  override func setUp() {
    super.setUp()
    set1.removeAll()
    set2.removeAll()
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Document
   * -----------------------------------------------------------------------------------------------
   */

  func testCreateDocument() {
    let doc1 = try! set1.createDocument()
    XCTAssertNotNil(doc1)
    XCTAssertGreaterThan(doc1.id, 0)
    XCTAssertThrowsError(try set1.createDocument(withId: doc1.id))
    let doc2 = try! set1.createDocument(withId: 2)
    XCTAssertEqual(doc2.id, 2)
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
    let arr = try! SCOrderedSet([docA, docB, docC])
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
    let arr = try! SCOrderedSet([docA, docB, docC])
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
    XCTAssertThrowsError(try set1.append(document: docNone))
  }

  func testAppendDocument() {
    try! set1.append(document: docA)
    try! set1.append(document: docB)
    XCTAssertEqual(set1.count, 2)
    XCTAssertEqual(set1.first, docA)
    XCTAssertEqual(set1.last, docB)
  }

  func testAppendDocuments() {
    try! set1.append(document: docA)
    try! set1.append(contentsOf: [docB, docC])
    XCTAssertEqual(set1.count, 3)
    XCTAssertEqual(set1.first, docA)
    XCTAssertEqual(set1[set1.index(set1.startIndex, offsetBy: 1)], docB)
    XCTAssertEqual(set1.last, docC)
  }
  
  func testInsertDocument() {
    try! set1.insert(document: docC, at: 0)
    try! set1.insert(document: docB, at: 0)
    try! set1.insert(document: docA, at: 0)
    XCTAssertEqual(set1.count, 3)
    XCTAssertEqual(set1.first, docA)
    XCTAssertEqual(set1[set1.index(set1.startIndex, offsetBy: 1)], docB)
    XCTAssertEqual(set1.last, docC)
  }
  
  func testInsertDocuments() {
    try! set1.insert(document: docC, at: 0)
    try! set2.insert(document: docB, at: 0)
    try! set2.insert(document: docA, at: 0)
    try! set1.insert(contentsOf: set2, at: 0)
    XCTAssertEqual(set1.count, 3)
    XCTAssertEqual(set2.count, 2)
    XCTAssertEqual(set1.first, docA)
    XCTAssertEqual(set1[set1.index(set1.startIndex, offsetBy: 1)], docB)
    XCTAssertEqual(set1.last, docC)
  }
  
  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Remove
   * -----------------------------------------------------------------------------------------------
   */
  
  func testRemoveDocument() {
    let set = try! SCOrderedSet<SCDocument>([docA, docB, docC])
    XCTAssertEqual(set.count, 3)
    set.remove(document: docB)
    XCTAssertEqual(set.count, 2)
  }

  func testRemoveDocuments() {
    let set = try! SCOrderedSet<SCDocument>([docA, docB, docC])
    XCTAssertEqual(set.count, 3)
    set.remove(contentsOf: [docA, docC])
    XCTAssertEqual(set.count, 1)
    XCTAssertEqual(set.last, docB)
  }

  func testRemoveAllDocuments() {
    let set = try! SCOrderedSet<SCDocument>([docA, docB, docC])
    XCTAssertEqual(set.count, 3)
    set.removeAll()
    XCTAssertEqual(set.count, 0)
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
