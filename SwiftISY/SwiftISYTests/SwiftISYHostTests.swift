//
//  SwiftISYHostTests.swift
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

class SwiftISYHostTests: XCTestCase {
  
  let host1 = (id: UInt(1), host: "host1-value", user: "user1-value", password: "password1-value")
  let host2 = (id: UInt(2), host: "host2-value", user: "user2-value", password: "password2-value")
  let host3 = (id: UInt(3), host: "host3-value", user: "user3-value", password: "password3-value")
  
  var hosts = SwiftISYHosts()
  
  override func setUp() {
    super.setUp()
    
    // remove existing hosts
    try? hosts.remove(jsonStorage: .userDefaults, completion: nil)
  }
  
  override func tearDown() {
    // remove existing hosts
    try? hosts.remove(jsonStorage: .userDefaults, completion: nil)
    
    super.tearDown()
  }
  
  func testNoHosts() {
    try? hosts.load(jsonStorage: .userDefaults, completion: nil)
    XCTAssertEqual(hosts.count, 0)
  }
  
  func testCreateHost() {
    let hostA = SwiftISYHost(host: host1.host, user: host1.user, password: host1.password)
    XCTAssertEqual(hostA.id, 0)
    XCTAssertEqual(hostA.host, host1.host)
    XCTAssertEqual(hostA.user, host1.user)
    XCTAssertEqual(hostA.password, host1.password)
    
    let hostB = SwiftISYHost(id: host2.id, host: host2.host, user: host2.user, password: host2.password)
    XCTAssertEqual(hostB.id, host2.id)
    XCTAssertEqual(hostB.host, host2.host)
    XCTAssertEqual(hostB.user, host2.user)
    XCTAssertEqual(hostB.password, host2.password)
  }
  
  func testProvidePassword() {
    let host = SwiftISYHost()
    
    // Provide a password
    SwiftISYHost.providePassword { (host) -> String in
      return "TEST"
    }
    XCTAssertEqual(host.password, "TEST")
    
    // Clear password provider
    SwiftISYHost.providePassword(nil)
    XCTAssertEqual(host.password, "")
  }
  
  func testAddHost() {
    // create a host
    guard let hostA = try? hosts.create() else { XCTFail(); return }
    XCTAssertNotNil(hostA)
    XCTAssertGreaterThan(hostA.id, 0)
    hostA.host = host1.host
    hostA.user = host1.user
    
    // add host
    try? hosts.append(hostA)
    XCTAssertEqual(hosts.count, 1)
    
    // save host
    try? hosts.save(jsonStorage: .userDefaults, completion: nil)
    let jsonObject = hosts.jsonObject() as? [[String: Any]]
    XCTAssertNotNil(jsonObject)
    
    // load hosts
    let hostsB = SwiftISYHosts()
    XCTAssertNoThrow(try hostsB.load(jsonStorage: .userDefaults, completion: nil))
    XCTAssertEqual(hostsB.count, 1)
    
    // validate saved host
    let hostB = hostsB.first
    XCTAssertEqual(hostB?.host, host1.host)
    XCTAssertEqual(hostB?.user, host1.user)
    XCTAssertNotEqual(hostB?.password, host1.password)
    XCTAssertEqual(hostB?.password, "")
  }
  
  func testAddHosts() {
    // add to hosts
    let hostA = SwiftISYHost(id: host1.id, host: host1.host, user: host1.user, password: host1.password)
    let hostB = SwiftISYHost(id: host2.id, host: host2.host, user: host2.user, password: host2.password)
    try? hosts.append(contentsOf: [hostA, hostB])
    
    // save hosts
    try? hosts.save(jsonStorage: .userDefaults, completion: nil)
    let jsonObject = hosts.jsonObject() as? [[String: Any]]
    XCTAssertNotNil(jsonObject)
    
    // load hosts
    let anotherHosts = SwiftISYHosts()
    XCTAssertNoThrow(try anotherHosts.load(jsonStorage: .userDefaults, completion: nil))
    XCTAssertEqual(anotherHosts.count, 2)
    
    // validate saved hosts
    XCTAssertEqual(anotherHosts.first, hostA)
    XCTAssertEqual(anotherHosts.last, hostB)
  }
  
  func testAddHostsAgain() {
    // add to hosts
    let hostA = SwiftISYHost(id: host1.id, host: host1.host, user: host1.user, password: host1.password)
    let hostB = SwiftISYHost(id: host2.id, host: host2.host, user: host2.user, password: host2.password)
    let hostC = SwiftISYHost(id: host3.id, host: host3.host, user: host3.user, password: host3.password)
    try? hosts.append(contentsOf: [hostA, hostB])
    try? hosts.append(contentsOf: [hostB, hostC])
    
    // save hosts
    try? hosts.save(jsonStorage: .userDefaults, completion: nil)
    let jsonObject = hosts.jsonObject() as? [[String: Any]]
    XCTAssertNotNil(jsonObject)
    
    // load hosts
    let anotherHosts = SwiftISYHosts()
    XCTAssertNoThrow(try anotherHosts.load(jsonStorage: .userDefaults, completion: nil))
    XCTAssertEqual(anotherHosts.count, 3)
    
    // validate saved hosts
    XCTAssertEqual(anotherHosts.first, hostA)
    XCTAssertEqual(anotherHosts[anotherHosts.index(after: anotherHosts.startIndex)], hostB)
    XCTAssertEqual(anotherHosts.last, hostC)
  }
  
  func testLoadHosts() {
    // get json from test bundle
    guard let json =  testResourceJson(forResource: "Hosts", withExtension: "json") else { XCTFail("Failed to load Hosts.json."); return }
    // load hosts from json
    guard let hosts = try? SwiftISYHosts(json: json) else { XCTFail("Failed to load hosts from JSON."); return }
    XCTAssertEqual(hosts.count, 3)
    
    let hostA = hosts.first
    XCTAssertEqual(hostA?.id, host1.id)
    XCTAssertEqual(hostA?.host, host1.host)
    XCTAssertEqual(hostA?.user, host1.user)
    XCTAssertEqual(hostA?.password, "")
    XCTAssertEqual(hostA?.alternativeHost, "alternativeHost1-value")
    XCTAssertEqual(hostA?.friendlyName, "friendlyName1-value")
    
    let hostB = hosts[hosts.index(after: hosts.startIndex)]
    XCTAssertEqual(hostB.id, host2.id)
    XCTAssertEqual(hostB.host, host2.host)
    XCTAssertEqual(hostB.user, host2.user)
    XCTAssertEqual(hostB.password, "")
    
    let hostC = hosts.last
    XCTAssertEqual(hostC?.id, host3.id)
    XCTAssertEqual(hostC?.host, host3.host)
    XCTAssertEqual(hostC?.user, host3.user)
    XCTAssertEqual(hostC?.password, "")
    
  }
  
}
