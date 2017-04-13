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
import SwiftCollection

class SwiftISYStatusTests: XCTestCase {
  
  var _statuses = SwiftISYStatuses(hostId: SwiftCollection.Id(88))
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    // remove existing statuses
    try? _statuses.remove(jsonStorage: .userDefaults, completion: nil)

    super.tearDown()
  }
  
  func testNoStatuses() {
    try? _statuses.load(jsonStorage: .userDefaults, completion: nil)
    XCTAssertEqual(_statuses.count, 0)
  }
  
  func testLoadStatuses() {
    // get json from test bundle
    guard let json =  testResourceJson(forResource: "Statuses", withExtension: "json") else { XCTFail("Failed to load Statuses.json."); return }
    
    // load statuses from json
    _ = try? _statuses.load(jsonObject: json)
    XCTAssertEqual(_statuses.count, 4)

    // validate status
    let status = _statuses.document(withId: 4063923215)
    XCTAssertNotNil(status)
    XCTAssertEqual(status?.address, "24 DD AD 1")
    XCTAssertEqual(status?.value, 75)
    XCTAssertEqual(status?.formatted, "30")
    XCTAssertEqual(status?.unitOfMeasure, "%/on/off")
    
    // save statuses
    try? _statuses.save(jsonStorage: .userDefaults, completion: nil)
    
    // validate saved statuses
    let statusesA = SwiftISYStatuses(hostId: _statuses.hostId!)
    try? statusesA.load(jsonStorage: .userDefaults, completion: nil)
    XCTAssertEqual(statusesA.count, 4)
  }
  
  func testLoadStatusesForHost() {
    defer {
      testRemoveHosts()
    }
    
    // get hosts
    guard let hosts = testLoadHosts() else { XCTFail("Failed to load Hosts.json."); return }
    let host1 = hosts.first
    let host2 = hosts.last
    XCTAssertNotNil(host1)
    XCTAssertNotNil(host2)
    XCTAssertNotEqual(host1, host2)
    
    // get json from test bundle
    guard let json =  testResourceJson(forResource: "Statuses", withExtension: "json") else { XCTFail("Failed to load Statuses.json."); return }
    guard let array = json as? [AnyObject] else { XCTFail("Failed to load Statuses.json."); return }
    
    // load 2 statuses into statuses 1 (for host 1)
    let statuses1 = SwiftISYStatuses(hostId: host1!.id)
    _ = try? statuses1.load(jsonObject: Array(array[0...1]) as AnyObject)
    XCTAssertEqual(statuses1.count, 2)
    try? statuses1.save(jsonStorage: .userDefaults, completion: nil)
    
    // load 2 statuses into statuses 2 (for host 2)
    let statuses2 = SwiftISYStatuses(hostId: host2!.id)
    _ = try? statuses2.load(jsonObject: Array(array[2...3]) as AnyObject)
    XCTAssertEqual(statuses2.count, 2)
    XCTAssertNotEqual(statuses1.first, statuses2.first)
    XCTAssertNotEqual(statuses1.last, statuses2.last)
    try? statuses2.save(jsonStorage: .userDefaults, completion: nil)
    
    let s1 = Set<SwiftISYStatus>(statuses1)
    let s2 = Set<SwiftISYStatus>(statuses2)
    XCTAssertNotEqual(s1, s2)
    
    // validate saved statuses for host 1
    let statuses1s = SwiftISYStatuses(hostId: statuses1.hostId!)
    try? statuses1s.load(jsonStorage: .userDefaults, completion: nil)
    XCTAssertEqual(statuses1s.count, 2)
    XCTAssertEqual(s1, Set<SwiftISYStatus>(statuses1s))
    
    // validate saved statuses for host 2
    let statuses2s = SwiftISYStatuses(hostId: statuses2.hostId!)
    try? statuses2s.load(jsonStorage: .userDefaults, completion: nil)
    XCTAssertEqual(statuses2s.count, 2)
    XCTAssertEqual(s2, Set<SwiftISYStatus>(statuses2s))
    
    // cleanup
    try? statuses1.remove(jsonStorage: .userDefaults, completion: nil)
    try? statuses2.remove(jsonStorage: .userDefaults, completion: nil)
  }
  
  func testLoadAddresses() {
    // get json from test bundle
    guard let json =  testResourceJson(forResource: "Statuses", withExtension: "json") else { XCTFail("Failed to load Statuses.json."); return }
    
    // load statuses from json
    _ = try? _statuses.load(jsonObject: json)
    XCTAssertEqual(_statuses.count, 4)
    
    // test addresses in same order as statuses
    for (i, status) in _statuses.enumerated() {
      XCTAssertEqual(_statuses.index(ofAddress: status.address), i)
    }
    
    // get statuses
    let status1 = _statuses[_statuses.startIndex]
    let status2 = _statuses[_statuses.index(_statuses.startIndex, offsetBy: 1)]
    let status3 = _statuses[_statuses.index(_statuses.startIndex, offsetBy: 2)]
    let status4 = _statuses[_statuses.index(_statuses.startIndex, offsetBy: 3)]
    let statuses = SwiftISYStatuses()
    
    // test append
    try! statuses.append(status2)
    XCTAssertEqual(statuses.count, 1)
    XCTAssertEqual(statuses[statuses.startIndex].address, status2.address)
    XCTAssertEqual(statuses.index(ofAddress: status1.address), NSNotFound)
    XCTAssertEqual(statuses.index(ofAddress: status2.address), 0)
    XCTAssertEqual(statuses.index(ofAddress: status3.address), NSNotFound)
    XCTAssertEqual(statuses.index(ofAddress: status4.address), NSNotFound)
    
    // test insert
    try! statuses.insert(status1, at: 0)
    XCTAssertEqual(statuses.count, 2)
    XCTAssertEqual(statuses[statuses.startIndex].address, status1.address)
    XCTAssertEqual(statuses[statuses.index(statuses.startIndex, offsetBy: 1)].address, status2.address)
    XCTAssertEqual(statuses.index(ofAddress: status1.address), 0)
    XCTAssertEqual(statuses.index(ofAddress: status2.address), 1)
    XCTAssertEqual(statuses.index(ofAddress: status3.address), NSNotFound)
    XCTAssertEqual(statuses.index(ofAddress: status4.address), NSNotFound)
    
    // test inserts
    try! statuses.insert(contentsOf: [status3, status4], at: 1)
    XCTAssertEqual(statuses.count, 4)
    XCTAssertEqual(statuses[statuses.startIndex].address, status1.address)
    XCTAssertEqual(statuses[statuses.index(statuses.startIndex, offsetBy: 1)].address, status3.address)
    XCTAssertEqual(statuses[statuses.index(statuses.startIndex, offsetBy: 2)].address, status4.address)
    XCTAssertEqual(statuses[statuses.index(statuses.startIndex, offsetBy: 3)].address, status2.address)
    XCTAssertEqual(statuses.index(ofAddress: status1.address), 0)
    XCTAssertEqual(statuses.index(ofAddress: status2.address), 3)
    XCTAssertEqual(statuses.index(ofAddress: status3.address), 1)
    XCTAssertEqual(statuses.index(ofAddress: status4.address), 2)
    
    // test remove
    let removed = statuses.remove(status3)
    XCTAssertEqual(removed, status3)
    XCTAssertEqual(statuses.count, 3)
    XCTAssertEqual(statuses[statuses.startIndex].address, status1.address)
    XCTAssertEqual(statuses[statuses.index(statuses.startIndex, offsetBy: 1)].address, status4.address)
    XCTAssertEqual(statuses[statuses.index(statuses.startIndex, offsetBy: 2)].address, status2.address)
    XCTAssertEqual(statuses.index(ofAddress: status1.address), 0)
    XCTAssertEqual(statuses.index(ofAddress: status2.address), 2)
    XCTAssertEqual(statuses.index(ofAddress: status3.address), NSNotFound)
    XCTAssertEqual(statuses.index(ofAddress: status4.address), 1)
    
    // test removes
    let removes = statuses.remove(contentsOf: [status1, status2])
    XCTAssertEqual(removes, [status1, status2])
    XCTAssertEqual(statuses.count, 1)
    XCTAssertEqual(statuses[statuses.startIndex].address, status4.address)
    XCTAssertEqual(statuses.index(ofAddress: status1.address), NSNotFound)
    XCTAssertEqual(statuses.index(ofAddress: status2.address), NSNotFound)
    XCTAssertEqual(statuses.index(ofAddress: status3.address), NSNotFound)
    XCTAssertEqual(statuses.index(ofAddress: status4.address), 0)
    
    // test appends
    try! statuses.append(contentsOf: [status1, status2])
    XCTAssertEqual(statuses[statuses.startIndex].address, status4.address)
    XCTAssertEqual(statuses[statuses.index(statuses.startIndex, offsetBy: 1)].address, status1.address)
    XCTAssertEqual(statuses[statuses.index(statuses.startIndex, offsetBy: 2)].address, status2.address)
    XCTAssertEqual(statuses.index(ofAddress: status1.address), 1)
    XCTAssertEqual(statuses.index(ofAddress: status2.address), 2)
    XCTAssertEqual(statuses.index(ofAddress: status3.address), NSNotFound)
    XCTAssertEqual(statuses.index(ofAddress: status4.address), 0)
  }

}
