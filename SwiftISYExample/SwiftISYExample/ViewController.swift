//
//  ViewController.swift
//  SwiftISYExample
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

import UIKit
import SwiftISY

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

  // create request to host
  let request = SwiftISYRequest(SwiftISYHost(host: "your host", user: "your username"))
  
  // create array to hold devices
  var nodes: [SwiftISYNode] = []
  
  // initalize table to display devices
  let cellId = "cell"
  let tableView = UITableView()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // add table
    tableView.frame = UIEdgeInsetsInsetRect(self.view.frame, UIEdgeInsetsMake(20, 0, 0, 0))
    tableView.dataSource = self
    tableView.delegate = self
    self.view.addSubview(tableView)
    
    // get nodes
    request.nodes { (results) in
      if let objects = results.objects { self.nodes = objects.nodes.sorted(by: { (n1, n2) -> Bool in
        return n1.name.compare(n2.name) == ComparisonResult.orderedAscending
      }) }
      self.tableView.reloadData()
    }
    
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return nodes.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    var cell: UITableViewCell?
    if let aCell = tableView.dequeueReusableCell(withIdentifier: cellId) {
      cell = aCell
    } else {
      cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellId)
    }
    let node = nodes[indexPath.row]
    cell?.textLabel?.text = node.name
    cell?.detailTextLabel?.text = node.address
    return cell!
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let node = nodes[indexPath.row]
    print("Address: \(node.address)")
  }
  
}
