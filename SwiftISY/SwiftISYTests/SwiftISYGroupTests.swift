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
import SwiftCollection

class SwiftISYGroupTests: XCTestCase {
  
  var _groups = SwiftISYGroups(hostId: SwiftCollection.Id(88))
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    // remove existing groups
    try? _groups.remove(jsonStorage: .userDefaults, completion: nil)

    super.tearDown()
  }
  
  func testNoGroups() {
    try? _groups.load(jsonStorage: .userDefaults, completion: nil)
    XCTAssertEqual(_groups.count, 0)
  }
  
  func testLoadGroups() {
    // get json from test bundle
    guard let json =  testResourceJson(forResource: "Groups", withExtension: "json") else { XCTFail("Failed to load Groups.json."); return }
    
    // load groups from json
    _ = try? _groups.load(jsonObject: json)
    XCTAssertEqual(_groups.count, 4)
    
    // validate group
    let group = _groups.document(withId: 3127395793)
    XCTAssertNotNil(group)
    XCTAssertEqual(group?.name, "Scene 2")
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
    try? _groups.save(jsonStorage: .userDefaults, completion: nil)
    
    // validate saved groups
    let groupsA = SwiftISYGroups(hostId: _groups.hostId!)
    try? groupsA.load(jsonStorage: .userDefaults, completion: nil)
    XCTAssertEqual(groupsA.count, 4)
  }

  func testLoadGroupsForHost() {
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
    guard let json =  testResourceJson(forResource: "Groups", withExtension: "json") else { XCTFail("Failed to load Groups.json."); return }
    guard let array = json as? [AnyObject] else { XCTFail("Failed to load Groups.json."); return }
    
    // load 2 groups into groups 1 (for host 1)
    let groups1 = SwiftISYGroups(hostId: host1!.id)
    _ = try? groups1.load(jsonObject: Array(array[0...1]) as AnyObject)
    XCTAssertEqual(groups1.count, 2)
    try? groups1.save(jsonStorage: .userDefaults, completion: nil)
    
    // load 2 groups into groups 2 (for host 2)
    let groups2 = SwiftISYGroups(hostId: host2!.id)
    _ = try? groups2.load(jsonObject: Array(array[2...3]) as AnyObject)
    XCTAssertEqual(groups2.count, 2)
    XCTAssertNotEqual(groups1.first, groups2.first)
    XCTAssertNotEqual(groups1.last, groups2.last)
    try? groups2.save(jsonStorage: .userDefaults, completion: nil)
    
    let s1 = Set<SwiftISYGroup>(groups1)
    let s2 = Set<SwiftISYGroup>(groups2)
    XCTAssertNotEqual(s1, s2)
    
    // validate saved groups for host 1
    let groups1s = SwiftISYGroups(hostId: groups1.hostId!)
    try? groups1s.load(jsonStorage: .userDefaults, completion: nil)
    XCTAssertEqual(groups1s.count, 2)
    XCTAssertEqual(s1, Set<SwiftISYGroup>(groups1s))
    
    // validate saved groups for host 2
    let groups2s = SwiftISYGroups(hostId: groups2.hostId!)
    try? groups2s.load(jsonStorage: .userDefaults, completion: nil)
    XCTAssertEqual(groups2s.count, 2)
    XCTAssertEqual(s2, Set<SwiftISYGroup>(groups2s))
    
    // cleanup
    try? groups1.remove(jsonStorage: .userDefaults, completion: nil)
    try? groups2.remove(jsonStorage: .userDefaults, completion: nil)
  }
  
  func testLoadAddresses() {
    // get json from test bundle
    guard let json =  testResourceJson(forResource: "Groups", withExtension: "json") else { XCTFail("Failed to load Groups.json."); return }
    
    // load groups from json
    _ = try? _groups.load(jsonObject: json)
    XCTAssertEqual(_groups.count, 4)
    
    // test addresses in same order as groups
    for (i, group) in _groups.enumerated() {
      XCTAssertEqual(_groups.index(ofAddress: group.address), i)
    }
    
    // get groups
    let group1 = _groups[_groups.startIndex]
    let group2 = _groups[_groups.index(_groups.startIndex, offsetBy: 1)]
    let group3 = _groups[_groups.index(_groups.startIndex, offsetBy: 2)]
    let group4 = _groups[_groups.index(_groups.startIndex, offsetBy: 3)]
    let groups = SwiftISYGroups()
    
    // test append
    try! groups.append(group2)
    XCTAssertEqual(groups.count, 1)
    XCTAssertEqual(groups[groups.startIndex].address, group2.address)
    XCTAssertEqual(groups.index(ofAddress: group1.address), NSNotFound)
    XCTAssertEqual(groups.index(ofAddress: group2.address), 0)
    XCTAssertEqual(groups.index(ofAddress: group3.address), NSNotFound)
    XCTAssertEqual(groups.index(ofAddress: group4.address), NSNotFound)
    
    // test insert
    try! groups.insert(group1, at: 0)
    XCTAssertEqual(groups.count, 2)
    XCTAssertEqual(groups[groups.startIndex].address, group1.address)
    XCTAssertEqual(groups[groups.index(groups.startIndex, offsetBy: 1)].address, group2.address)
    XCTAssertEqual(groups.index(ofAddress: group1.address), 0)
    XCTAssertEqual(groups.index(ofAddress: group2.address), 1)
    XCTAssertEqual(groups.index(ofAddress: group3.address), NSNotFound)
    XCTAssertEqual(groups.index(ofAddress: group4.address), NSNotFound)
    
    // test inserts
    try! groups.insert(contentsOf: [group3, group4], at: 1)
    XCTAssertEqual(groups.count, 4)
    XCTAssertEqual(groups[groups.startIndex].address, group1.address)
    XCTAssertEqual(groups[groups.index(groups.startIndex, offsetBy: 1)].address, group3.address)
    XCTAssertEqual(groups[groups.index(groups.startIndex, offsetBy: 2)].address, group4.address)
    XCTAssertEqual(groups[groups.index(groups.startIndex, offsetBy: 3)].address, group2.address)
    XCTAssertEqual(groups.index(ofAddress: group1.address), 0)
    XCTAssertEqual(groups.index(ofAddress: group2.address), 3)
    XCTAssertEqual(groups.index(ofAddress: group3.address), 1)
    XCTAssertEqual(groups.index(ofAddress: group4.address), 2)
    
    // test remove
    let removed = groups.remove(group3)
    XCTAssertEqual(removed, group3)
    XCTAssertEqual(groups.count, 3)
    XCTAssertEqual(groups[groups.startIndex].address, group1.address)
    XCTAssertEqual(groups[groups.index(groups.startIndex, offsetBy: 1)].address, group4.address)
    XCTAssertEqual(groups[groups.index(groups.startIndex, offsetBy: 2)].address, group2.address)
    XCTAssertEqual(groups.index(ofAddress: group1.address), 0)
    XCTAssertEqual(groups.index(ofAddress: group2.address), 2)
    XCTAssertEqual(groups.index(ofAddress: group3.address), NSNotFound)
    XCTAssertEqual(groups.index(ofAddress: group4.address), 1)
    
    // test removes
    let removes = groups.remove(contentsOf: [group1, group2])
    XCTAssertEqual(removes, [group1, group2])
    XCTAssertEqual(groups.count, 1)
    XCTAssertEqual(groups[groups.startIndex].address, group4.address)
    XCTAssertEqual(groups.index(ofAddress: group1.address), NSNotFound)
    XCTAssertEqual(groups.index(ofAddress: group2.address), NSNotFound)
    XCTAssertEqual(groups.index(ofAddress: group3.address), NSNotFound)
    XCTAssertEqual(groups.index(ofAddress: group4.address), 0)
    
    // test appends
    try! groups.append(contentsOf: [group1, group2])
    XCTAssertEqual(groups[groups.startIndex].address, group4.address)
    XCTAssertEqual(groups[groups.index(groups.startIndex, offsetBy: 1)].address, group1.address)
    XCTAssertEqual(groups[groups.index(groups.startIndex, offsetBy: 2)].address, group2.address)
    XCTAssertEqual(groups.index(ofAddress: group1.address), 1)
    XCTAssertEqual(groups.index(ofAddress: group2.address), 2)
    XCTAssertEqual(groups.index(ofAddress: group3.address), NSNotFound)
    XCTAssertEqual(groups.index(ofAddress: group4.address), 0)
    
    // test replace
    try! groups.replace(group1, with: group3)
    XCTAssertEqual(groups[groups.startIndex].address, group4.address)
    XCTAssertEqual(groups[groups.index(groups.startIndex, offsetBy: 1)].address, group3.address)
    XCTAssertEqual(groups[groups.index(groups.startIndex, offsetBy: 2)].address, group2.address)
    XCTAssertEqual(groups[groups.startIndex].address, group4.address)
    XCTAssertEqual(groups.index(ofAddress: group1.address), NSNotFound)
    XCTAssertEqual(groups.index(ofAddress: group2.address), 2)
    XCTAssertEqual(groups.index(ofAddress: group3.address), 1)
    XCTAssertEqual(groups.index(ofAddress: group4.address), 0)
    
    // test remove all
    groups.removeAll()
    XCTAssertEqual(groups.count, 0)
    XCTAssertEqual(groups.index(ofAddress: group1.address), NSNotFound)
    XCTAssertEqual(groups.index(ofAddress: group2.address), NSNotFound)
    XCTAssertEqual(groups.index(ofAddress: group3.address), NSNotFound)
    XCTAssertEqual(groups.index(ofAddress: group4.address), NSNotFound)
  }

}
