//
//  SwiftCollectionTests+Document.swift
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

class SwiftCollectionDocumentTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    super.tearDown()
  }

  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Document
   * -----------------------------------------------------------------------------------------------
   */
  
  func testGuid() {
    XCTAssertEqual(SCDocument(id: 0x1).guid, "0000-0000-0000-0001")
    XCTAssertEqual(SCDocument(id: 0x10000).guid, "0000-0000-0001-0000")
    XCTAssertEqual(SCDocument(id: 0x100000000).guid, "0000-0001-0000-0000")
    XCTAssertEqual(SCDocument(id: 0x1000000000000).guid, "0001-0000-0000-0000")
    XCTAssertEqual(SCDocument(id: UInt.max).guid, "FFFF-FFFF-FFFF-FFFF")
    XCTAssertEqual(SCDocument(id: 0x1234567890abcdef).guid, "1234-5678-90AB-CDEF")
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

    let doc = SCDocument(id: 0x10000)
    defer {
      try? doc.remove(jsonStorage: .userDefaults, completion: nil)
    }
    
    let load = {
      let loaded = SCDocument()
      try! loaded.load(jsonStorage: .userDefaults, completion: { (success, json) in
        le.fulfill()
        XCTAssertEqual(doc.id, loaded.id)
      })
    }
    
    try! doc.save(jsonStorage: .userDefaults) { (success) in
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
