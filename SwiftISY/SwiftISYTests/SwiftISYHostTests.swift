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

  struct Constants {
    static let id1 = "id1-value"
    static let host1 = "host1-value"
    static let user1 = "user1-value"
    static let password1 = "password1-value"
    static let id2 = "id2-value"
    static let host2 = "host2-value"
    static let user2 = "user2-value"
    static let password2 = "password2-value"
    static let id3 = "id3-value"
    static let host3 = "host3-value"
    static let user3 = "user3-value"
    static let password3 = "password3-value"
  }
  
  override func setUp() {
    super.setUp()
    
    // remove existing hosts
    let ud = UserDefaults.standard
    ud.removeObject(forKey: "hosts")
  }
  
  override func tearDown() {
    // remove existing hosts
    let ud = UserDefaults.standard
    ud.removeObject(forKey: "hosts")

    super.tearDown()
  }
  
  func testNoHosts() {
    let hosts = SwiftISYHost.get(persistentStorage: .userDefaults)
    XCTAssertEqual(hosts.count, 0)
  }

  func testCreateHost() {
    let host1 = SwiftISYHost(id: Constants.id1, host: Constants.host1, user: Constants.user1, password: Constants.password1)
    XCTAssertEqual(host1.id, Constants.id1)
    XCTAssertEqual(host1.host, Constants.host1)
    XCTAssertEqual(host1.user, Constants.user1)
    XCTAssertEqual(host1.password, Constants.password1)
  }
  
  func testAddHost() {
    let host1 = SwiftISYHost(id: Constants.id1, host: Constants.host1, user: Constants.user1, password: Constants.password1)
    SwiftISYHost.add(persistentStorage: .userDefaults, hosts: [host1])
    let hosts = SwiftISYHost.get(persistentStorage: .userDefaults)
    XCTAssertEqual(hosts.count, 1)
    let anotherHost1 = hosts[0]
    XCTAssertEqual(anotherHost1.id, Constants.id1)
    XCTAssertEqual(anotherHost1.host, Constants.host1)
    XCTAssertEqual(anotherHost1.user, Constants.user1)
    XCTAssertEqual(anotherHost1.password, "")
  }

  func testAddHosts() {
    let host1 = SwiftISYHost(id: Constants.id1, host: Constants.host1, user: Constants.user1, password: Constants.password1)
    let host2 = SwiftISYHost(id: Constants.id2, host: Constants.host2, user: Constants.user2, password: Constants.password2)
    SwiftISYHost.add(persistentStorage: .userDefaults, hosts: [host1, host2])
    let hosts = SwiftISYHost.get(persistentStorage: .userDefaults)
    XCTAssertEqual(hosts.count, 2)
    let anotherHost1 = hosts[0]
    XCTAssertEqual(anotherHost1.id, Constants.id1)
    let anotherHost2 = hosts[1]
    XCTAssertEqual(anotherHost2.id, Constants.id2)
  }

  func testAddHostsAgain() {
    let host1 = SwiftISYHost(id: Constants.id1, host: Constants.host1, user: Constants.user1, password: Constants.password1)
    let host2 = SwiftISYHost(id: Constants.id2, host: Constants.host2, user: Constants.user2, password: Constants.password2)
    let host3 = SwiftISYHost(id: Constants.id3, host: Constants.host3, user: Constants.user3, password: Constants.password3)
    SwiftISYHost.add(persistentStorage: .userDefaults, hosts: [host1, host2])
    SwiftISYHost.add(persistentStorage: .userDefaults, hosts: [host2, host3])
    let hosts = SwiftISYHost.get(persistentStorage: .userDefaults)
    XCTAssertEqual(hosts.count, 3)
    let anotherHost1 = hosts[0]
    XCTAssertEqual(anotherHost1.id, Constants.id1)
    let anotherHost2 = hosts[1]
    XCTAssertEqual(anotherHost2.id, Constants.id2)
    let anotherHost3 = hosts[2]
    XCTAssertEqual(anotherHost3.id, Constants.id3)
  }

}
