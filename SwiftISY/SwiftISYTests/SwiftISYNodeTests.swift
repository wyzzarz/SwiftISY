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
import SwiftCollection

class SwiftISYNodeTests: XCTestCase {
  
  let _nodes = SwiftISYNodes(hostId: SwiftCollection.Id(88))
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    // remove existing nodes
    try? _nodes.remove(jsonStorage: .userDefaults, completion: nil)
    
    super.tearDown()
  }
  
  func testNoNodes() {
    try? _nodes.load(jsonStorage: .userDefaults, completion: nil)
    XCTAssertEqual(_nodes.count, 0)
  }

  func testLoadNodes() {
    // get json from test bundle
    guard let json =  testResourceJson(forResource: "Nodes", withExtension: "json") else { XCTFail("Failed to load Nodes.json."); return }

    // load nodes from json
    _ = try? _nodes.load(jsonObject: json)
    XCTAssertEqual(_nodes.count, 4)

    // validate node
    let node = _nodes.document(withId: 1525177531)
    XCTAssertNotNil(node)
    XCTAssertEqual(node?.name, "Light 2")
    XCTAssertEqual(node?.pnode, "44 EF 96 1")
    XCTAssertEqual(node?.family, 11)
    XCTAssertEqual(node?.address, "44 EF 96 1")
    XCTAssertEqual(node?.wattage, 12)
    XCTAssertEqual(node?.elkId, "B05")
    XCTAssertEqual(node?.enabled, true)
    XCTAssertEqual(node?.type, "2.44.65.0")
    XCTAssertEqual(node?.deviceClass, 13)
    XCTAssertEqual(node?.property, "property01")
    XCTAssertEqual(node?.parent, "parent01")
    XCTAssertEqual(node?.dcPeriod, 14)
    XCTAssertEqual(node?.flags.rawValue, 128)
    XCTAssertEqual(node?.options.rawValue, 3)

    // save nodes
    try? _nodes.save(jsonStorage: .userDefaults, completion: nil)
    
    // validate saved nodes
    let nodesA = SwiftISYNodes(hostId: _nodes.hostId!)
    try? nodesA.load(jsonStorage: .userDefaults, completion: nil)
    XCTAssertEqual(nodesA.count, 4)
  }
  
  func testLoadNodesForHost() {
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
    guard let json =  testResourceJson(forResource: "Nodes", withExtension: "json") else { XCTFail("Failed to load Nodes.json."); return }
    guard let array = json as? [AnyObject] else { XCTFail("Failed to load Nodes.json."); return }
    
    // load 2 nodes into nodes 1 (for host 1)
    let nodes1 = SwiftISYNodes(hostId: host1!.id)
    _ = try? nodes1.load(jsonObject: Array(array[0...1]) as AnyObject)
    XCTAssertEqual(nodes1.count, 2)
    try? nodes1.save(jsonStorage: .userDefaults, completion: nil)
    
    // load 2 nodes into nodes 2 (for host 2)
    let nodes2 = SwiftISYNodes(hostId: host2!.id)
    _ = try? nodes2.load(jsonObject: Array(array[2...3]) as AnyObject)
    XCTAssertEqual(nodes2.count, 2)
    XCTAssertNotEqual(nodes1.first, nodes2.first)
    XCTAssertNotEqual(nodes1.last, nodes2.last)
    try? nodes2.save(jsonStorage: .userDefaults, completion: nil)

    let s1 = Set<SwiftISYNode>(nodes1)
    let s2 = Set<SwiftISYNode>(nodes2)
    XCTAssertNotEqual(s1, s2)
    
    // validate saved nodes for host 1
    let nodes1s = SwiftISYNodes(hostId: host1!.id)
    try? nodes1s.load(jsonStorage: .userDefaults, completion: nil)
    XCTAssertEqual(nodes1s.count, 2)
    XCTAssertEqual(s1, Set<SwiftISYNode>(nodes1s))
    
    // validate saved nodes for host 2
    let nodes2s = SwiftISYNodes(hostId: host2!.id)
    try? nodes2s.load(jsonStorage: .userDefaults, completion: nil)
    XCTAssertEqual(nodes2s.count, 2)
    XCTAssertEqual(s2, Set<SwiftISYNode>(nodes2s))
    
    // cleanup
    try? nodes1.remove(jsonStorage: .userDefaults, completion: nil)
    try? nodes2.remove(jsonStorage: .userDefaults, completion: nil)
  }
  
  func testLoadAddresses() {
    // get json from test bundle
    guard let json =  testResourceJson(forResource: "Nodes", withExtension: "json") else { XCTFail("Failed to load Nodes.json."); return }
    
    // load nodes from json
    _ = try? _nodes.load(jsonObject: json)
    XCTAssertEqual(_nodes.count, 4)
    
    // test addresses in same order as nodes
    for (i, node) in _nodes.enumerated() {
      XCTAssertEqual(_nodes.index(ofAddress: node.address), i)
    }
    
    // get nodes
    let node1 = _nodes[_nodes.startIndex]
    let node2 = _nodes[_nodes.index(_nodes.startIndex, offsetBy: 1)]
    let node3 = _nodes[_nodes.index(_nodes.startIndex, offsetBy: 2)]
    let node4 = _nodes[_nodes.index(_nodes.startIndex, offsetBy: 3)]
    let nodes = SwiftISYNodes()
    
    // test append
    try! nodes.append(node2)
    XCTAssertEqual(nodes.count, 1)
    XCTAssertEqual(nodes[nodes.startIndex].address, node2.address)
    XCTAssertEqual(nodes.index(ofAddress: node1.address), NSNotFound)
    XCTAssertEqual(nodes.index(ofAddress: node2.address), 0)
    XCTAssertEqual(nodes.index(ofAddress: node3.address), NSNotFound)
    XCTAssertEqual(nodes.index(ofAddress: node4.address), NSNotFound)
    
    // test insert
    try! nodes.insert(node1, at: 0)
    XCTAssertEqual(nodes.count, 2)
    XCTAssertEqual(nodes[nodes.startIndex].address, node1.address)
    XCTAssertEqual(nodes[nodes.index(nodes.startIndex, offsetBy: 1)].address, node2.address)
    XCTAssertEqual(nodes.index(ofAddress: node1.address), 0)
    XCTAssertEqual(nodes.index(ofAddress: node2.address), 1)
    XCTAssertEqual(nodes.index(ofAddress: node3.address), NSNotFound)
    XCTAssertEqual(nodes.index(ofAddress: node4.address), NSNotFound)
    
    // test inserts
    try! nodes.insert(contentsOf: [node3, node4], at: 1)
    XCTAssertEqual(nodes.count, 4)
    XCTAssertEqual(nodes[nodes.startIndex].address, node1.address)
    XCTAssertEqual(nodes[nodes.index(nodes.startIndex, offsetBy: 1)].address, node3.address)
    XCTAssertEqual(nodes[nodes.index(nodes.startIndex, offsetBy: 2)].address, node4.address)
    XCTAssertEqual(nodes[nodes.index(nodes.startIndex, offsetBy: 3)].address, node2.address)
    XCTAssertEqual(nodes.index(ofAddress: node1.address), 0)
    XCTAssertEqual(nodes.index(ofAddress: node2.address), 3)
    XCTAssertEqual(nodes.index(ofAddress: node3.address), 1)
    XCTAssertEqual(nodes.index(ofAddress: node4.address), 2)
    
    // test remove
    let removed = nodes.remove(node3)
    XCTAssertEqual(removed, node3)
    XCTAssertEqual(nodes.count, 3)
    XCTAssertEqual(nodes[nodes.startIndex].address, node1.address)
    XCTAssertEqual(nodes[nodes.index(nodes.startIndex, offsetBy: 1)].address, node4.address)
    XCTAssertEqual(nodes[nodes.index(nodes.startIndex, offsetBy: 2)].address, node2.address)
    XCTAssertEqual(nodes.index(ofAddress: node1.address), 0)
    XCTAssertEqual(nodes.index(ofAddress: node2.address), 2)
    XCTAssertEqual(nodes.index(ofAddress: node3.address), NSNotFound)
    XCTAssertEqual(nodes.index(ofAddress: node4.address), 1)
    
    // test removes
    let removes = nodes.remove(contentsOf: [node1, node2])
    XCTAssertEqual(removes, [node1, node2])
    XCTAssertEqual(nodes.count, 1)
    XCTAssertEqual(nodes[nodes.startIndex].address, node4.address)
    XCTAssertEqual(nodes.index(ofAddress: node1.address), NSNotFound)
    XCTAssertEqual(nodes.index(ofAddress: node2.address), NSNotFound)
    XCTAssertEqual(nodes.index(ofAddress: node3.address), NSNotFound)
    XCTAssertEqual(nodes.index(ofAddress: node4.address), 0)
    
    // test appends
    try! nodes.append(contentsOf: [node1, node2])
    XCTAssertEqual(nodes[nodes.startIndex].address, node4.address)
    XCTAssertEqual(nodes[nodes.index(nodes.startIndex, offsetBy: 1)].address, node1.address)
    XCTAssertEqual(nodes[nodes.index(nodes.startIndex, offsetBy: 2)].address, node2.address)
    XCTAssertEqual(nodes.index(ofAddress: node1.address), 1)
    XCTAssertEqual(nodes.index(ofAddress: node2.address), 2)
    XCTAssertEqual(nodes.index(ofAddress: node3.address), NSNotFound)
    XCTAssertEqual(nodes.index(ofAddress: node4.address), 0)
    
    // test replace
    try! nodes.replace(node1, with: node3)
    XCTAssertEqual(nodes[nodes.startIndex].address, node4.address)
    XCTAssertEqual(nodes[nodes.index(nodes.startIndex, offsetBy: 1)].address, node3.address)
    XCTAssertEqual(nodes[nodes.index(nodes.startIndex, offsetBy: 2)].address, node2.address)
    XCTAssertEqual(nodes[nodes.startIndex].address, node4.address)
    XCTAssertEqual(nodes.index(ofAddress: node1.address), NSNotFound)
    XCTAssertEqual(nodes.index(ofAddress: node2.address), 2)
    XCTAssertEqual(nodes.index(ofAddress: node3.address), 1)
    XCTAssertEqual(nodes.index(ofAddress: node4.address), 0)
    
    // test remove all
    nodes.removeAll()
    XCTAssertEqual(nodes.count, 0)
    XCTAssertEqual(nodes.index(ofAddress: node1.address), NSNotFound)
    XCTAssertEqual(nodes.index(ofAddress: node2.address), NSNotFound)
    XCTAssertEqual(nodes.index(ofAddress: node3.address), NSNotFound)
    XCTAssertEqual(nodes.index(ofAddress: node4.address), NSNotFound)
  }
  
}
