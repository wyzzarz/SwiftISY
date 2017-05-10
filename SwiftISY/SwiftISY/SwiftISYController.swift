//
//  SwiftISYController.swift
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

import Foundation
import SwiftCollection

public class SwiftISYController {
  
  /// Shared instance to be used for this controller.
  static public let sharedInstance = SwiftISYController()

  public typealias Completion = (_ success: Bool) -> Void

  /// Returns `true` if the controller is actively managing ISY objects.  `false` otherwise.
  final public var enabled: Bool = true
  
  /// Persistent store to be used when saving and loading.
  final public var storage: SwiftCollection.Storage {
    get {
      return _storage
    }
    set {
      _storage = newValue
    }
  }
  fileprivate var _storage = SwiftCollection.Storage.userDefaults

  /// Registered hosts.
  final public var hosts: SwiftISYHosts {
    // load hosts if necessary
    if _hosts.count == 0 {
      try? _hosts.load(jsonStorage: storage, completion: nil)
    }
    return _hosts
  }
  fileprivate let _hosts = SwiftISYHosts()
  
  /// Nodes available for a host.
  ///
  /// - Parameter host: Host to be retrieved.
  /// - Returns: Nodes for this host.
  final public func nodes(_ host: SwiftISYHost) -> SwiftISYNodes {
    guard let nodes = _nodes[host.id] else {
      let nodes = SwiftISYNodes(hostId: host.id)
      _nodes[host.id] = nodes
      return nodes
    }
    return nodes
  }
  fileprivate var _nodes: [SwiftCollection.Id: SwiftISYNodes] = [:]

  /// Groups available for a host.
  ///
  /// - Parameter host: Host to be retrieved.
  /// - Returns: Groups for this host.
  final public func groups(_ host: SwiftISYHost) -> SwiftISYGroups {
    guard let groups = _groups[host.id] else {
      let groups = SwiftISYGroups(hostId: host.id)
      _groups[host.id] = groups
      return groups
    }
    return groups
  }
  fileprivate var _groups: [SwiftCollection.Id: SwiftISYGroups] = [:]

  /// Statuses available for a host.
  ///
  /// - Parameter host: Host to be retrieved.
  /// - Returns: Statuses for this host.
  final public func statuses(_ host: SwiftISYHost) -> SwiftISYStatuses {
    guard let statuses = _statuses[host.id] else {
      let statuses = SwiftISYStatuses(hostId: host.id)
      _statuses[host.id] = statuses
      return statuses
    }
    return statuses
  }
  fileprivate var _statuses: [SwiftCollection.Id: SwiftISYStatuses] = [:]

  // -------------------------------------------------------------------------------------------------
  // MARK: - Initializers
  // -------------------------------------------------------------------------------------------------

  /// Creates an instance of `SwiftISYController`.  Nodes, Groups and Statuses are loaded from
  /// persistent storage upon initialization.
  ///
  /// - Parameters:
  ///   - storage: Persistent storage to be used.  Defaults to `userDefaults`.
  ///   - refresh: `true` if objects should be refreshed from hosts once loading from persistent
  ///              storage is complete.
  public init(storage: SwiftCollection.Storage = .userDefaults, refresh: Bool = true) {
    self.storage = storage
    DispatchQueue.main.async {
      self.reload(refresh: refresh)
      self.notificationsEnabled = self._notificationsEnabled
    }
  }
  
  // -------------------------------------------------------------------------------------------------
  // MARK: - Reload
  // -------------------------------------------------------------------------------------------------
  
  /// Processes each host.
  ///
  /// - Parameters:
  ///   - completion: Called when processing hosts is complete.
  ///   - processHost: Called for each host.
  fileprivate func processHosts(completion: Completion? = nil, _ processHost: (_ host: SwiftISYHost, _ i: Int, _ count: Int) -> Void) {
    // get hosts
    let hosts = self.hosts
    
    // ensure there are hosts to load
    let count = hosts.count
    guard count > 0 else {
      if let completion = completion { completion(true) }
      return
    }
    
    // load each host
    for (i, host) in hosts.enumerated() {
      processHost(host, i, count)
    }
  }
  
  /// Reload nodes, groups and statuses from persistent storage for all hosts.  And fetch latest
  /// objects and statuses for each host.
  ///
  /// - Parameters:
  ///   - refresh: `true` if objects should be refreshed from hosts once loading from persistent
  ///              storage is complete.
  ///   - completion: Called once reload is complete.
  public func reload(refresh: Bool = true, completion: Completion? = nil) {
    processHosts(completion: completion) { (host, i , count) in
      reload(host: host, refresh: refresh) { (success) in
        if count - i > 1 { return }
        if let completion = completion { completion(true) }
      }
    }
  }

  /// Reload nodes, groups and statuses from persistent storage for the specified host.  And fetch 
  /// latest objects and statuses for the host.
  ///
  /// - Parameters:
  ///   - host: Host to be loaded.
  ///   - refresh: `true` if objects should be refreshed from the host once loading from persistent
  ///              storage is complete.
  ///   - completion: Called once reload is complete.
  public func reload(host: SwiftISYHost, refresh: Bool = true, completion: Completion?) {
    // reload from persistent storage
    reloadNodes(host)
    reloadGroups(host)
    reloadStatuses(host)
    
    // fetch from host
    if refresh {
      self.refresh(host, completion: completion)
      return
    }

    // otherwise handle successful completion
    if let completion = completion { completion(true) }
  }
  
  /// Reload nodes for host from persistent storage.
  ///
  /// - Parameter host: Host to load from.
  fileprivate func reloadNodes(_ host: SwiftISYHost) {
    try? nodes(host).load(jsonStorage: storage, completion: nil)
  }
  
  /// Reload groups for host from persistent storage.
  ///
  /// - Parameter host: Host to load from.
  fileprivate func reloadGroups(_ host: SwiftISYHost) {
    try? groups(host).load(jsonStorage: storage, completion: nil)
  }
  
  /// Reload statuses for host from persistent storage.
  ///
  /// - Parameter host: Host to load from.
  fileprivate func reloadStatuses(_ host: SwiftISYHost) {
    // load statuses
    try? statuses(host).load(jsonStorage: storage, completion: nil)
  }
  
  // -------------------------------------------------------------------------------------------------
  // MARK: - Refresh
  // -------------------------------------------------------------------------------------------------
  
  /// Fetch nodes, groups and statuses for all hosts.
  ///
  /// - Parameter completion: Called once refresh is complete.
  public func refresh(completion: Completion?) {
    processHosts(completion: completion) { (host, i , count) in
      refresh(host) { (success) in
        if count - i > 1 { return }
        if let completion = completion { completion(true) }
      }
    }
  }
  
  /// Fetch nodes, groups and statuses for host.
  ///
  /// - Parameters:
  ///   - host: Host to refresh.
  ///   - completion: Called once refresh is complete.
  public func refresh(_ host: SwiftISYHost, completion: Completion?) {
    /// call to nodes includes nodes, groups and statuses
    SwiftISYRequest(host).nodes { (result) in
      defer {
        if let completion = completion { completion(result.success) }
      }
      guard result.success else { return }
      guard let objects = result.objects else { return }
      self.refreshNodes(host, nodes: objects.nodes)
      self.refreshGroups(host, groups: objects.groups)
      self.refreshStatuses(host, statuses: Array<SwiftISYStatus>(objects.statuses.values))
    }
  }
  
  /// Refresh nodes for host.
  ///
  /// - Parameters:
  ///   - host: Host to refresh.
  ///   - objects: Objects from request response.
  fileprivate func refreshNodes(_ host: SwiftISYHost, nodes theNodes: [SwiftISYNode]) {
    // get nodes
    let nodes = self.nodes(host)
    
    // remember existing nodes
    var existing: [String: SwiftISYNode] = [:]
    for node in nodes {
      existing[node.address] = node
    }
    
    // process nodes
    for node in theNodes {
      // get address for node
      let address = node.address
      
      // replace existing node
      if let existingNode = existing[address] {
        try? nodes.replace(existingNode, with: node)
        existing.removeValue(forKey: address)
        continue
      }
      
      // otherwise add this node
      try? nodes.append(node)
    }
    
    // remove unused nodes
    for (_, node) in existing {
      _ = nodes.remove(node)
    }
  }

  /// Refresh groups for host.
  ///
  /// - Parameters:
  ///   - host: Host to refresh.
  ///   - objects: Objects from request response.
  fileprivate func refreshGroups(_ host: SwiftISYHost, groups theGroups: [SwiftISYGroup]) {
    // get groups
    let groups = self.groups(host)
    
    // remember existing groups
    var existing: [String: SwiftISYGroup] = [:]
    for group in groups {
      existing[group.address] = group
    }
    
    // process groups
    for group in theGroups {
      // get address for group
      let address = group.address
      
      // replace existing group
      if let existingGroup = existing[address] {
        try? groups.replace(existingGroup, with: group)
        existing.removeValue(forKey: address)
        continue
      }
      
      // otherwise add this group
      try? groups.append(group)
    }
    
    // remove unused groups
    for (_, group) in existing {
      _ = groups.remove(group)
    }
  }

  /// Refresh statuses for host.
  ///
  /// - Parameters:
  ///   - host: Host to refresh.
  ///   - objects: Objects from request response.
  fileprivate func refreshStatuses(_ host: SwiftISYHost, statuses theStatuses: [SwiftISYStatus]) {
    // get statuses
    let statuses = self.statuses(host)
    
    // remember existing statuses
    var existing: [String: SwiftISYStatus] = [:]
    for status in statuses {
      existing[status.address] = status
    }
    
    // process statuses
    for status in theStatuses {
      // get address for status
      let address = status.address
      
      // replace existing status
      if let existingStatus = existing[address] {
        try? statuses.replace(existingStatus, with: status)
        existing.removeValue(forKey: address)
        continue
      }
      
      // otherwise add this status
      try? statuses.append(status)
    }
    
    // remove unused statuses
    for (_, status) in existing {
      _ = statuses.remove(status)
    }
  }
  
  // -------------------------------------------------------------------------------------------------
  // MARK: - Notifications
  // -------------------------------------------------------------------------------------------------
  
  /// Whether notifications are sent to observers.
  public var notificationsEnabled: Bool {
    get {
      return _notificationsEnabled
    }
    set {
      _notificationsEnabled = newValue
      toggleNotifications()
    }
  }
  fileprivate var _notificationsEnabled = true

  /// Whether notifications are sent when the application returns from the background and becomes
  /// active.
  public var onResumeEnabled: Bool {
    get {
      return _onResumeEnabled
    }
    set {
      _onResumeEnabled = newValue
      toggleNotifications()
    }
  }
  fileprivate var _onResumeEnabled = true
  
  /// Called when the application returns from the background and becomes active.
  ///
  /// `onResumeEnabled` must be `true` in order for this function to be called.
  @objc public func onResume() {
    DispatchQueue.main.async {
      self.refresh { (success) in
        NotificationCenter.default.post(name: .onResume, object: nil)
      }
    }
  }
  
  /// Updates `NotificationCenter` for notifications sent from this framework.
  fileprivate func toggleNotifications() {
    let nc = NotificationCenter.default
    
    // exit if notifications are off
    guard _notificationsEnabled else {
      nc.removeObserver(self)
      return
    }
    
    // handle on resume
    if _onResumeEnabled {
      nc.addObserver(self, selector: #selector(onResume), name: .UIApplicationWillEnterForeground, object: nil)
    } else {
      nc.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
    }
  }
  
}
