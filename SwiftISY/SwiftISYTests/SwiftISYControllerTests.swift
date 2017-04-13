//
//  SwiftISYControllerTests.swift
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

// -------------------------------------------------------------------------------------------------
// MARK: -
// -------------------------------------------------------------------------------------------------

class SwiftISYControllerLoadTests: XCTestCase {

  var _host1: SwiftISYHost?
  var _host2: SwiftISYHost?
  let _controller = SwiftISYController(refresh: false)
  
  override func setUp() {
    super.setUp()
    
    // set defaults
    _controller.storage = .userDefaults
    
    // load hosts from test bundle
    let hosts = testLoadHosts()
    _host1 = hosts?.first
    _host2 = hosts?.last

    // load objects for host 2
    testLoadNodes(_host2!)
    testLoadGroups(_host2!)
    testLoadStatuses(_host2!)
    
    // handle requests
    setupUrlSessionTest(_host2)
  }
  
  override func tearDown() {
    // unhandle requests
    self.tearDownUrlSessionTest()

    // remove objects
    testRemoveHosts()
    testRemoveNodes(_host2!)
    testRemoveGroups(_host2!)
    testRemoveStatuses(_host2!)
    
    super.tearDown()
  }
  
  func testLoadObjects() {
    _controller.reload(refresh: false)
    XCTAssertEqual(_controller.hosts.count, 3)
    XCTAssertEqual(_controller.nodes(_host1!).count, 0)
    XCTAssertEqual(_controller.groups(_host1!).count, 0)
    XCTAssertEqual(_controller.statuses(_host1!).count, 0)
    XCTAssertEqual(_controller.nodes(_host2!).count, 4)
    XCTAssertEqual(_controller.groups(_host2!).count, 4)
    XCTAssertEqual(_controller.statuses(_host2!).count, 4)
  }

  func testLoadAndRefreshObjects() {
    let e = expectation(description: Paths.nodes)

    _controller.reload { (success) in
      e.fulfill()
      XCTAssertEqual(self._controller.hosts.count, 3)
      XCTAssertEqual(self._controller.nodes(self._host1!).count, 0)
      XCTAssertEqual(self._controller.groups(self._host1!).count, 0)
      XCTAssertEqual(self._controller.statuses(self._host1!).count, 0)

      let nodes = self._controller.nodes(self._host2!)
      XCTAssertEqual(nodes.count, 4)
      XCTAssertEqual(nodes.document(address: "24 DD AD 1")?.name, "Light 1 (R)")

      let groups = self._controller.groups(self._host2!)
      XCTAssertEqual(groups.count, 2)
      XCTAssertEqual(groups.document(address: "00:21:b9:02:03:89")?.name, "Scene 1 (R)")

      let statuses = self._controller.statuses(self._host2!)
      XCTAssertEqual(statuses.count, 4)
      XCTAssertEqual(statuses.document(address: "24 EF 96 4")?.value, 255)
    }

    XCTAssertEqual(_controller.hosts.count, 3)
    XCTAssertEqual(_controller.nodes(_host1!).count, 0)
    XCTAssertEqual(_controller.groups(_host1!).count, 0)
    XCTAssertEqual(_controller.statuses(_host1!).count, 0)
    
    let nodes = _controller.nodes(_host2!)
    XCTAssertEqual(nodes.count, 4)
    XCTAssertEqual(nodes.document(address: "24 DD AD 1")?.name, "Light 1")
    
    let groups = _controller.groups(_host2!)
    XCTAssertEqual(groups.count, 4)
    XCTAssertEqual(groups.document(address: "00:21:b9:02:03:89")?.name, "Scene 1")
    
    let statuses = _controller.statuses(_host2!)
    XCTAssertEqual(statuses.count, 4)
    XCTAssertEqual(statuses.document(address: "24 EF 96 4")?.value, 0)

    waitForExpectations(timeout: 60) { (error) in
      guard error == nil else { XCTFail(error!.localizedDescription); return }
    }
  }

}

// -------------------------------------------------------------------------------------------------
// MARK: -
// -------------------------------------------------------------------------------------------------

class SwiftISYControllerRefreshTests: XCTestCase {
  
  let invalidHostId = Constants.hostId1
  var invalidHost: SwiftISYHost?
  let validHostId = Constants.hostId2
  var validHost: SwiftISYHost?
  
  override func setUp() {
    super.setUp()
    
    // load hosts from test bundle
    let hosts = testLoadHosts()
    invalidHost = hosts?.document(withId: invalidHostId)
    validHost = hosts?.document(withId: validHostId)
    
    // handle requests
    setupUrlSessionTest(validHost)
  }
  
  override func tearDown() {
    // unhandle requests
    tearDownUrlSessionTest()
    
    // remove objects
    testRemoveHosts()
    
    super.tearDown()
  }
  
  func testNoObjects() {
    let controller = SwiftISYController(refresh: false)
    for host in controller.hosts {
      XCTAssertEqual(controller.nodes(host).count, 0, "Nodes for \(host.id) not empty.")
      XCTAssertEqual(controller.groups(host).count, 0, "Groups for \(host.id) not empty.")
      XCTAssertEqual(controller.statuses(host).count, 0, "Statuses for \(host.id) not empty.")
    }
  }
  
  func testObjects() {
    let e = expectation(description: Paths.nodes)
    
    let controller = SwiftISYController(refresh: false)
    
    controller.refresh { (success) in
      e.fulfill()
      XCTAssertEqual(controller.nodes(self.invalidHost!).count, 0)
      XCTAssertEqual(controller.nodes(self.validHost!).count, 4)
    }
    
    waitForExpectations(timeout: 60) { (error) in
      guard error == nil else { XCTFail(error!.localizedDescription); return }
    }

  }
  
}
