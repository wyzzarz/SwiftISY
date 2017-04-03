//
//  ViewController.swift
//  SwiftCollectionExample
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
import SwiftCollection

/// `Document` sublcasses `SCDocument` and provides an additional field `name`.
///
/// Loading from persistent storage is updated for the `name` field.
class Document: SCDocument {
  
  var name: String?
  
  convenience init(id: SwiftCollection.Id, name: String) {
    self.init(id: id)
    self.name = name
  }

  override func load(propertyWithName name: String, currentValue: Any, potentialValue: Any, json: AnyObject) {
    switch name {
    case Keys.name: if let value = (json as? [String: Any])?[Keys.name] as? String { self.name = value }
    default: super.load(propertyWithName: name, currentValue: currentValue, potentialValue: potentialValue, json: json)
    }
  }

}

extension Document.Keys {

  static let name = "name"
  
}

/// `OrderedSet` provides a concrete implementation of `SCOrderedSet` for a collection of `Document`
/// objects.
///
/// A new persistent storage key is provided.  And loading from persistent storage is performed
/// for documents in the collection.
class OrderedSet: SCOrderedSet<Document> {
  
  override func storageKey() -> String {
    return "OrderedSetExample"
  }
  
  override func load(jsonObject json: AnyObject) throws -> AnyObject? {
    if let array = json as? [AnyObject] {
      for item in array {
        try? append(document: Document(json: item))
      }
    }
    return json
  }

}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  
  // create a new ordered set
  let orderedSet = OrderedSet()
  
  let tableView = UITableView()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // add documents to the collection
    try? orderedSet.append(document: Document(id: 1, name: "First"))
    try? orderedSet.append(document: Document(id: 2, name: "Second"))
    try? orderedSet.append(document: Document(id: 3, name: "Third"))

    tableView.dataSource = self
    tableView.delegate = self
    tableView.frame = UIEdgeInsetsInsetRect(self.view.frame, UIEdgeInsetsMake(20, 0, 0, 0))
    self.view.addSubview(tableView)
    
    DispatchQueue.main.async {
      self.saveAndLoad()
    }
  }
  
  /// An example to save the collection to persistent storage.  And load saved data from persistent
  /// storage.
  func saveAndLoad() {
    try? orderedSet.save(jsonStorage: .userDefaults) { (success) in
      print("saved", success)
      let anotherOrderedSet = OrderedSet()
      try? anotherOrderedSet.load(jsonStorage: .userDefaults) { (success, json) in
        print("loaded", success)
      }
    }
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return orderedSet.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cellId = "doc"
    
    // get cell
    var cell: UITableViewCell?
    if let aCell = tableView.dequeueReusableCell(withIdentifier: cellId) { cell = aCell }
    if cell == nil { cell = UITableViewCell(style: .value1, reuseIdentifier: cellId) }
    
    // setup cell
    let doc = orderedSet[orderedSet.index(orderedSet.startIndex, offsetBy: indexPath.row)]
    cell?.textLabel?.text = doc.name
    cell?.detailTextLabel?.text = String(doc.id)
    
    return cell!
  }
  
}
