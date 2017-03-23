//
//  SwiftCollectionTests.swift
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

class SwiftCollectionTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testBundle() {
    XCTAssertTrue(SwiftCollection.bundleId.characters.count > 0)
    XCTAssertNotNil(SwiftCollection.bundle)
  }
  
  func testHexId() {
    XCTAssertEqual(SwiftCollection.Id(exactly: 0x0001000200030004)!.toHexString(), "0001000200030004")
    XCTAssertEqual(SwiftCollection.Id(exactly: 0x1234567890ABCDEF)!.toHexString(groupEvery: 1), "12-34-56-78-90-AB-CD-EF")
    XCTAssertEqual(SwiftCollection.Id(exactly: 0x1234567890ABCDEF)!.toHexString(groupEvery: 2), "1234-5678-90AB-CDEF")
    XCTAssertEqual(SwiftCollection.Id(exactly: 0x1234567890ABCDEF)!.toHexString(groupEvery: 3, separator: ":"), "123456:7890AB:CDEF")
    XCTAssertEqual(SwiftCollection.Id(exactly: 0x1234567890ABCDEF)!.toHexString(groupEvery: 4), "12345678-90ABCDEF")
    XCTAssertEqual(SwiftCollection.Id(exactly: 0x1234567890ABCDEF)!.toHexString(groupEvery: 8), "1234567890ABCDEF")
    XCTAssertEqual(SwiftCollection.Id(exactly: 0x1234567890ABCDEF)!.toHexString(groupEvery: 9), "1234567890ABCDEF")
    XCTAssertEqual(SwiftCollection.Id.max.toHexString(), "FFFFFFFFFFFFFFFF")
  }
  
  func testRandomId() {
    XCTAssertGreaterThan(SwiftCollection.Id.random(), 0)
    XCTAssertEqual(SwiftCollection.Id.random(upper: SwiftCollection.Id.max, lower: SwiftCollection.Id.max), SwiftCollection.Id.max)
    XCTAssertEqual(SwiftCollection.Id.random(upper: SwiftCollection.Id.min, lower: SwiftCollection.Id.min), SwiftCollection.Id.min)
    XCTAssertEqual(SwiftCollection.Id.random(upper: 5, lower: 5), 5)
    var i: UInt = 0
    while i < 10000 {
      XCTAssertGreaterThanOrEqual(SwiftCollection.Id.random(upper: 10, lower: 5), 5)
      XCTAssertLessThanOrEqual(SwiftCollection.Id.random(upper: 10, lower: 5), 10)
      i += 1
    }
  }
  
  func testUnwrap() {
    let a = "string"
    let b: String? = "string"
    let c: String? = nil
    XCTAssertEqual(SwiftCollection.unwrap(any: a) as! String, "string")
    XCTAssertEqual(SwiftCollection.unwrap(any: b as Any) as! String, "string")
    XCTAssertTrue(SwiftCollection.unwrap(any: c as Any) is NSNull)
  }

}
