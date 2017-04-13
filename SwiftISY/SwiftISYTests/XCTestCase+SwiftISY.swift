//
//  XCTestCase+ISY.swift
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

extension XCTestCase {

  // -------------------------------------------------------------------------------------------------
  // MARK: - Request
  // -------------------------------------------------------------------------------------------------

  struct Constants {
    
    static let hostId1 = SwiftCollection.Id(1)
    static let hostId2 = SwiftCollection.Id(2)
    static let hostId3 = SwiftCollection.Id(3)
    
  }
  
  struct Paths {
    
    static let nodes = "/rest/nodes"
    static let statuses = "/rest/status"
    static let response = "/rest/nodes/24 DD AD 1/cmd/DON"
    
  }
  
  struct RequestError: Error {
    
    fileprivate let _localizedDescription: String
    
    init(_ localizedDescription: String) {
      _localizedDescription = localizedDescription
    }
    
    var localizedDescription: String {
      return _localizedDescription
    }
    
  }

  func setupUrlSessionTest(_ host: SwiftISYHost? = nil) {
    SwizzledURLSessionDataTask.taskHandler = { (request) -> (Data?, URLResponse?, Error?) in
      var data: Data?
      var response: URLResponse?
      var error: Error?
      
      // get xml data from request
      let url = request.url
      if let path = url?.path {
        switch path {
        case Paths.nodes:
          data = self.testResourceData(forResource: "Nodes", withExtension: "xml")
        case Paths.statuses:
          data = self.testResourceData(forResource: "Statuses", withExtension: "xml")
        case Paths.response:
          data = self.testResourceData(forResource: "Response", withExtension: "xml")
        default:
          break
        }
      }

      // get host
      let urlHost = url?.host
      let hostName = host?.host

      // prepare response from data
      if urlHost != nil && hostName != nil && urlHost!.compare(hostName!) != .orderedSame {
        data = self.testResourceData(forResource: "Empty", withExtension: "xml")
        let statusCode = SwiftISY.HttpStatusCodes.ok.rawValue
        let headerFields: [String: String] = ["Content-Length": String(data!.count), "Content-Type": "text/xml; charset=UTF-8"]
        response = HTTPURLResponse(url: url!, statusCode: statusCode, httpVersion: nil, headerFields: headerFields)
      } else if let data = data {
        let statusCode = SwiftISY.HttpStatusCodes.ok.rawValue
        let headerFields: [String: String] = ["Content-Length": String(data.count), "Content-Type": "text/xml; charset=UTF-8"]
        response = HTTPURLResponse(url: url!, statusCode: statusCode, httpVersion: nil, headerFields: headerFields)
      } else {
        let statusCode = SwiftISY.HttpStatusCodes.badRequest.rawValue
        response = HTTPURLResponse(url: url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)
        error = RequestError("Bad Request")
      }
      
      return (data, response, error)
    }
  }
  
  func tearDownUrlSessionTest() {
    SwizzledURLSessionDataTask.taskHandler = nil
  }

  // -------------------------------------------------------------------------------------------------
  // MARK: - Bundle
  // -------------------------------------------------------------------------------------------------

  func testResourceUrl(forResource name: String, withExtension ext: String?) -> URL? {
    let bundle = Bundle(for: type(of: self))
    guard let testBundleUrl = bundle.url(forResource: "SwiftISYTests", withExtension: "bundle") else { return nil }
    guard let testBundle = Bundle(url: testBundleUrl) else { return nil }
    return testBundle.url(forResource: name, withExtension: ext)
  }

  func testResourceData(forResource name: String, withExtension ext: String?) -> Data? {
    guard let url = testResourceUrl(forResource: name, withExtension: ext) else { return nil }
    return try? Data(contentsOf: url)
  }

  func testResourceJson(forResource name: String, withExtension ext: String?) -> AnyObject? {
    guard let data = testResourceData(forResource: name, withExtension: ext) else { return nil }
    return try? JSONSerialization.jsonObject(with: data, options: []) as AnyObject
  }

  // -------------------------------------------------------------------------------------------------
  // MARK: - Persistence (Load/Remove)
  // -------------------------------------------------------------------------------------------------

  func testLoadHosts() -> SwiftISYHosts? {
    SwiftISYHost.providePassword { (host) -> String in
      return "password"
    }
    guard let json =  testResourceJson(forResource: "Hosts", withExtension: "json") else { return nil }
    do {
      let hosts = SwiftISYHosts()
      _ = try hosts.load(jsonObject: json)
      try? hosts.save(jsonStorage: .userDefaults, completion: nil)
      return hosts
    } catch { }
    return nil
  }

  func testRemoveHosts() {
    SwiftISYHost.providePassword(nil)
    try? SwiftISYHosts().remove(jsonStorage: .userDefaults, completion: nil)
  }
  
  func testLoadNodes(_ host: SwiftISYHost) {
    guard let json =  testResourceJson(forResource: "Nodes", withExtension: "json") else { return }
    let nodes = SwiftISYNodes(hostId: host.id)
    _ = try? nodes.load(jsonObject: json)
    try? nodes.save(jsonStorage: .userDefaults, completion: nil)
  }
  
  func testRemoveNodes(_ host: SwiftISYHost) {
    try? SwiftISYNodes(hostId: host.id).remove(jsonStorage: .userDefaults, completion: nil)
  }
  
  func testLoadGroups(_ host: SwiftISYHost) {
    guard let json =  testResourceJson(forResource: "Groups", withExtension: "json") else { return }
    let groups = SwiftISYGroups(hostId: host.id)
    _ = try? groups.load(jsonObject: json)
    try? groups.save(jsonStorage: .userDefaults, completion: nil)
  }
  
  func testRemoveGroups(_ host: SwiftISYHost) {
    try? SwiftISYGroups(hostId: host.id).remove(jsonStorage: .userDefaults, completion: nil)
  }

  func testLoadStatuses(_ host: SwiftISYHost) {
    guard let json =  testResourceJson(forResource: "Statuses", withExtension: "json") else { return }
    let statuses = SwiftISYStatuses(hostId: host.id)
    _ = try? statuses.load(jsonObject: json)
    try? statuses.save(jsonStorage: .userDefaults, completion: nil)
  }
  
  func testRemoveStatuses(_ host: SwiftISYHost) {
    try? SwiftISYStatuses(hostId: host.id).remove(jsonStorage: .userDefaults, completion: nil)
  }

}
