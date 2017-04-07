//
//  SwiftISYGroupTests.swift
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

class SwiftISYGroupTests: XCTestCase {
  
  var groups = SwiftISYGroups()
  
  override func setUp() {
    super.setUp()
    
    // remove existing groups
    try? groups.remove(jsonStorage: .userDefaults, completion: nil)
  }
  
  override func tearDown() {
    // remove existing groups
    try? groups.remove(jsonStorage: .userDefaults, completion: nil)

    super.tearDown()
  }
  
  func testNoGroups() {
    try? groups.load(jsonStorage: .userDefaults, completion: nil)
    XCTAssertEqual(groups.count, 0)
  }
  
  func testLoadGroups() {
    // get json from test bundle
    guard let json =  testResourceJson(forResource: "Groups", withExtension: "json") else { XCTFail("Failed to load Groups.json."); return }
    
    // load groups from json
    _ = try? groups.load(jsonObject: json)
    XCTAssertEqual(groups.count, 2)
    
    // validate group
    let group = groups.document(withId: 3127395793)
    XCTAssertNotNil(group)
    XCTAssertEqual(group?.name, "Scene 1")
    XCTAssertEqual(group?.family, 12)
    XCTAssertEqual(group?.address, "10028")
    XCTAssertEqual(group?.elkId, "C16")
    XCTAssertEqual(group?.deviceGroup, 18)
    XCTAssertEqual(group?.flags.rawValue, 132)
    XCTAssertEqual(group?.controllerIds.count, 1)
    XCTAssertEqual(group!.controllerIds, ["24 EF 96 4"])
    XCTAssertEqual(group?.responderIds.count, 3)
    XCTAssertEqual(group!.responderIds, ["24 DD AD 1", "24 EF 96 1", "24 EF 96 3"])
    
    // save groups
    try? groups.save(jsonStorage: .userDefaults, completion: nil)
    
    // validate saved groups
    let groupsA = SwiftISYGroups()
    try? groupsA.load(jsonStorage: .userDefaults, completion: nil)
    XCTAssertEqual(groupsA.count, 2)
  }

}
