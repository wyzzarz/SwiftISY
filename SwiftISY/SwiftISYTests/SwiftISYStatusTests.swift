//
//  SwiftISYStatusTests.swift
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

class SwiftISYStatusTests: XCTestCase {
  
  var statuses = SwiftISYStatuses()
  
  override func setUp() {
    super.setUp()
    
    // remove existing statuses
    try? statuses.remove(jsonStorage: .userDefaults, completion: nil)
  }
  
  override func tearDown() {
    // remove existing statuses
    try? statuses.remove(jsonStorage: .userDefaults, completion: nil)

    super.tearDown()
  }
  
  func testNoStatuses() {
    try? statuses.load(jsonStorage: .userDefaults, completion: nil)
    XCTAssertEqual(statuses.count, 0)
  }
  
  func testLoadStatuses() {
    // get json from test bundle
    guard let json =  testResourceJson(forResource: "Statuses", withExtension: "json") else { XCTFail("Failed to load Statuses.json."); return }
    
    // load statuses from json
    _ = try? statuses.load(jsonObject: json)
    XCTAssertEqual(statuses.count, 4)

    // validate status
    let status = statuses.document(withId: 4063923215)
    XCTAssertNotNil(status)
    XCTAssertEqual(status?.value, 75)
    XCTAssertEqual(status?.formatted, "30")
    XCTAssertEqual(status?.unitOfMeasure, "%/on/off")
    
    // save statuses
    try? statuses.save(jsonStorage: .userDefaults, completion: nil)
    
    // validate saved statuses
    let statusesA = SwiftISYStatuses()
    try? statusesA.load(jsonStorage: .userDefaults, completion: nil)
    XCTAssertEqual(statusesA.count, 4)
  }

}
