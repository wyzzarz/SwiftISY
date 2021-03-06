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
import SwiftCollection

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  
  // isy
  var host: SwiftISYHost?

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
    guard let host = SwiftISYController.sharedInstance.hosts.first else { return }
    self.host = host
    SwiftISYController.sharedInstance.refresh(host) { (controller, success) in
      self.nodes = Array(controller.nodes(host))
      self.tableView.reloadData()
    }
    
    NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(n:)), name: SwiftCollection.Notifications.didChange.notification, object: nil)
  }
  
  func handleNotification(n: Notification) {
    guard let status = n.object as? SwiftISYStatus else { return }
    print(status)
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
    
    // get address
    let node = nodes[indexPath.row]
    let address = node.address
    print("Address: \(address)")
  }
  
}
