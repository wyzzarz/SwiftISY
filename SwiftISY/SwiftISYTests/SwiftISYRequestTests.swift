//
//  SwiftISYRequestTests.swift
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

class SwiftISYRequestTests: XCTestCase {
  
  let host = SwiftISYHost(host: "host", user: "user", password: "password")
    
  override func setUp() {
    super.setUp()
    setupUrlSessionTest()
  }
  
  override func tearDown() {
    tearDownUrlSessionTest()
    super.tearDown()
  }
  
  func testNodesRequest() {
    let e = expectation(description: Paths.nodes)

    SwiftISYRequest(host).nodes { (result) in
      e.fulfill()
      
      // test successful request
      XCTAssertTrue(result.success)
      XCTAssertNil(result.error)
      
      // test objects
      XCTAssertNotNil(result.objects)
      guard let objects = result.objects else { XCTFail(); return }
      
      // test node
      XCTAssertEqual(objects.nodes.count, 4)
      let node = objects.nodes.filter({ (node) -> Bool in
        return node.address == "24 DD AD 1"
      }).first
      XCTAssertNotNil(node)
      XCTAssertEqual(node!.name, "Light 1 (R)")
      XCTAssertEqual(node!.type, "1.32.65.0")
      XCTAssertTrue(node!.enabled)
      XCTAssertEqual(node!.deviceClass, 1)
      XCTAssertEqual(node!.wattage, 2)
      XCTAssertEqual(node!.dcPeriod, 3)
      XCTAssertEqual(node!.pnode, node!.address)
      XCTAssertEqual(node!.elkId, "C02")
      XCTAssertEqual(node!.options.rawValue, SwiftISY.OptionFlags(other: [.light, .dimmable]).rawValue)
      
      // test status
      XCTAssertEqual(objects.statuses.count, 4)
      let status = objects.statuses["24 DD AD 1"]
      XCTAssertEqual(status!.address, "24 DD AD 1")
      XCTAssertEqual(status!.value, 75)
      XCTAssertEqual(status!.formatted, "30")
      XCTAssertEqual(status!.unitOfMeasure, "%/on/off")
      
      // test group
      XCTAssertEqual(objects.groups.count, 2)
      let group = objects.groups.first(where: { (group) -> Bool in
        return group.address == "10028"
      })
      XCTAssertEqual(group!.name, "Scene 2 (R)")
      XCTAssertEqual(group!.deviceGroup, 18)
      XCTAssertEqual(group!.elkId, "C16")
      XCTAssertEqual(group!.responderIds, ["24 DD AD 1", "24 EF 96 1", "24 EF 96 3"])
      XCTAssertEqual(group!.controllerIds, ["24 EF 96 4"])
    }
    
    waitForExpectations(timeout: 60) { (error) in
      guard error == nil else { XCTFail(error!.localizedDescription); return }
    }
  }

  func testStatusesRequest() {
    let e = expectation(description: Paths.statuses)
    
    SwiftISYRequest(host).statuses { (result) in
      e.fulfill()
      
      // test successful request
      XCTAssertTrue(result.success)
      XCTAssertNil(result.error)
      
      // test objects
      XCTAssertNotNil(result.objects)
      guard let objects = result.objects else { XCTFail(); return }
      
      // test status
      XCTAssertEqual(objects.statuses.count, 4)
      if let status = objects.statuses["24 DD AD 1"] {
        XCTAssertEqual(status.address, "24 DD AD 1")
        XCTAssertEqual(status.value, 75)
        XCTAssertEqual(status.formatted, "30")
        XCTAssertEqual(status.unitOfMeasure, "%/on/off")
      }
      if let status = objects.statuses["24 EF 96 1"] {
        XCTAssertEqual(status.address, "24 EF 96 1")
        XCTAssertEqual(status.value, 255)
        XCTAssertEqual(status.formatted, "On")
        XCTAssertEqual(status.unitOfMeasure, "on/off")
      }
      if let status = objects.statuses["24 EF 96 3"] {
        XCTAssertEqual(status.address, "24 EF 96 3")
        XCTAssertEqual(status.value, 0)
        XCTAssertEqual(status.formatted, "Off")
        XCTAssertEqual(status.unitOfMeasure, "on/off")
      }
      if let status = objects.statuses["24 EF 96 4"] {
        XCTAssertEqual(status.address, "24 EF 96 4")
        XCTAssertEqual(status.value, 0)
        XCTAssertEqual(status.formatted, "Off")
        XCTAssertEqual(status.unitOfMeasure, "on/off")
      }
    }
    
    waitForExpectations(timeout: 60) { (error) in
      guard error == nil else { XCTFail(error!.localizedDescription); return }
    }
  }

  func testResponseRequest() {
    let e = expectation(description: Paths.on)
    
    SwiftISYRequest(host).on(address: "24 DD AD 1") { (result) in
      e.fulfill()

      // test successful request
      XCTAssertTrue(result.success)
      XCTAssertNil(result.error)

      // test objects
      XCTAssertNotNil(result.objects)
      guard let objects = result.objects else { XCTFail(); return }
      
      // test response
      XCTAssertEqual(objects.responses.count, 1)
      if let response = objects.responses.first {
        XCTAssertEqual(response.status, SwiftISY.HttpStatusCodes.ok)
      }
    }
    
    waitForExpectations(timeout: 60) { (error) in
      guard error == nil else { XCTFail(error!.localizedDescription); return }
    }
  }

}
