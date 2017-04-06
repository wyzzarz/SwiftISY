//
//  SwiftISYNodeTests.swift
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
import SwiftISY

class SwiftISYNodeTests: XCTestCase {
  
  var nodes = SwiftISYNodes()
  
  override func setUp() {
    super.setUp()
    
    // remove existing nodes
    try? nodes.remove(jsonStorage: .userDefaults, completion: nil)
  }
  
  override func tearDown() {
    // remove existing nodes
    try? nodes.remove(jsonStorage: .userDefaults, completion: nil)
    
    super.tearDown()
  }
  
  func testNoNodes() {
    try? nodes.load(jsonStorage: .userDefaults, completion: nil)
    XCTAssertEqual(nodes.count, 0)
  }

  func testLoadNodes() {
    // get json from test bundle
    guard let json =  testResourceJson(forResource: "Nodes", withExtension: "json") else { XCTFail("Failed to load Nodes.json."); return }

    // load nodes from json
    _ = try? nodes.load(jsonObject: json)
    XCTAssertEqual(nodes.count, 4)

    // validate node
    let node = nodes.document(withId: 1525177531)
    XCTAssertNotNil(node)
    XCTAssertEqual(node?.name, "Light 2")
    XCTAssertEqual(node?.pnode, "24 EF 96 1")
    XCTAssertEqual(node?.family, 11)
    XCTAssertEqual(node?.address, "24 EF 96 1")
    XCTAssertEqual(node?.wattage, 12)
    XCTAssertEqual(node?.elkId, "B05")
    XCTAssertEqual(node?.enabled, true)
    XCTAssertEqual(node?.type, "2.44.65.0")
    XCTAssertEqual(node?.deviceClass, 13)
    XCTAssertEqual(node?.property, "property01")
    XCTAssertEqual(node?.parent, "parent01")
    XCTAssertEqual(node?.dcPeriod, 14)
    XCTAssertEqual(node?.flags.rawValue, 128)

    // save nodes
    try? nodes.save(jsonStorage: .userDefaults, completion: nil)
    
    // validate saved nodes
    let nodesA = SwiftISYNodes()
    try? nodesA.load(jsonStorage: .userDefaults, completion: nil)
    XCTAssertEqual(nodesA.count, 4)
  }
  
}
