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

/// `SwiftISYController` provides a shared instance singleton to interact with registered hosts.
/// The controller handles requests to ISY hosts.  It maintains a list of nodes and groups and the
/// status of each.
public class SwiftISYController {
  
  /// Shared instance to be used for this controller.
  static public let sharedInstance = SwiftISYController()

  public typealias Completion = (_ controller: SwiftISYController, _ success: Bool) -> Void

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
    let id = hosts.existing(host).id
    guard let nodes = _nodes[id] else {
      let nodes = SwiftISYNodes(hostId: id)
      _nodes[id] = nodes
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
    let id = hosts.existing(host).id
    guard let groups = _groups[id] else {
      let groups = SwiftISYGroups(hostId: id)
      _groups[id] = groups
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
    let id = hosts.existing(host).id
    guard let statuses = _statuses[id] else {
      let statuses = SwiftISYStatuses(hostId: id)
      _statuses[id] = statuses
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
      self.handleNotifications()
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
      if let completion = completion { completion(self, true) }
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
        if let completion = completion { completion(self, true) }
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
    if let completion = completion { completion(self, true) }
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
        if let completion = completion { completion(self, true) }
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
        if let completion = completion { completion(self, result.success) }
      }
      guard result.success else { return }
      guard let objects = result.objects else { return }
      self.refreshNodes(host, nodes: objects.nodes)
      self.refreshGroups(host, groups: objects.groups)
      self.refreshStatuses(host, statuses: Array<SwiftISYStatus>(objects.statuses.values))
    }
  }
  
  public func refresh(_ host: SwiftISYHost, address: String, completion: Completion?) {
    SwiftISYRequest(host).status(address: address) { (result) in
      defer {
        if let completion = completion { completion(self, result.success) }
      }
      guard result.success else { return }
      guard let objects = result.objects else { return }
      self.refreshStatus(host, statuses: Array<SwiftISYStatus>(objects.statuses.values))
    }
  }
  
  /// Refresh nodes for host.
  ///
  /// - Parameters:
  ///   - host: Host to refresh.
  ///   - nodes: Nodes from request response.
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
      try? nodes.add(node)
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
  ///   - groups: Groups from request response.
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
      try? groups.add(group)
    }
    
    // remove unused groups
    for (_, group) in existing {
      _ = groups.remove(group)
    }
  }

  /// Refresh statuses for host.  New statuses will be added, existing statuses will be updated, and
  /// missing statuses will be removed.
  ///
  /// - Parameters:
  ///   - host: Host to refresh.
  ///   - statuses: Statuses from request response.
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
      try? statuses.add(status)
    }
    
    // remove unused statuses
    for (_, status) in existing {
      _ = statuses.remove(status)
    }
  }
  
  /// Refresh statuses for host.  New statuses will be added, existing statuses will be updated, and
  /// missing statuses will be remain.
  ///
  /// - Parameters:
  ///   - host: Host to refresh.
  ///   - statuses: Statuses to add or update.
  fileprivate func refreshStatus(_ host: SwiftISYHost, statuses theStatuses: [SwiftISYStatus]) {
    // get statuses
    let statuses = self.statuses(host)
    
    // process statuses
    for status in theStatuses {
      if let i = statuses.index(of: status) {
        try? statuses.replace(at: i, with: status)
      } else {
        try? statuses.add(status)
      }
    }
  }
  
  // -------------------------------------------------------------------------------------------------
  // MARK: - Request
  // -------------------------------------------------------------------------------------------------

  public func request(_ host: SwiftISYHost) -> SwiftISYRequest {
    if let request = _requests[host] { return request }
    let request = SwiftISYRequest(host)
    _requests[host] = request
    return request
  }
  fileprivate var _requests: [SwiftISYHost: SwiftISYRequest] = [:]

  // -------------------------------------------------------------------------------------------------
  // MARK: - Object
  // -------------------------------------------------------------------------------------------------

  public func status(_ host: SwiftISYHost, address: String) -> [String: SwiftISYStatus] {
    if let node = nodes(host).document(address: address) { return status(host, node: node) }
    if let group = groups(host).document(address: address) { return status(host, group: group) }
    return [:]
  }
  
  fileprivate func status(_ host: SwiftISYHost, node: SwiftISYNode) -> [String: SwiftISYStatus] {
    if let status = statuses(host).document(address: node.address) { return [node.address: status] }
    return [:]
  }
  
  fileprivate func status(_ host: SwiftISYHost, group: SwiftISYGroup) -> [String: SwiftISYStatus] {
    var theStatuses: [String: SwiftISYStatus] = [:]
    for address in group.responderIds {
      if let status = statuses(host).document(address: address) { theStatuses[address] = status }
    }
    for address in group.controllerIds {
      if let status = statuses(host).document(address: address) { theStatuses[address] = status }
    }
    return theStatuses
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
        NotificationCenter.default.post(name: SwiftISY.Notifications.onResume.notification, object: nil)
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
  
  /// Called when an object needs to be refreshed from a host.
  ///
  /// - Parameter n: Notification including host and address.
  @objc fileprivate func needsRefresh(n: Notification) {
    guard let host = n.object as? SwiftISYHost else { return }
    guard let userInfo = n.userInfo else { return }
    guard let address = userInfo[SwiftISY.Elements.address] as? String else { return }
    guard let node = nodes(host).document(address: address) else { return }
    performRefresh(host: host, node: node, max: DispatchTime.now() + 1.0) { (success) in
      if success {
        let nc = NotificationCenter.default
        nc.post(name: SwiftISY.Notifications.didRefresh.notification, object: host, userInfo: userInfo)
      }
    }
  }
  
  fileprivate func performRefresh(host: SwiftISYHost, node: SwiftISYNode, max: DispatchTime, completion: @escaping (_ success: Bool) -> Void) {
    print("trying")
    // get current value to check against
    let value = status(host, address: node.address).values.first?.value

    // wait a little bit before checking the latest status from the host
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
      
      // refresh the status for this address
      self.refresh(host, address: node.address, completion: { (controller, success) in
        
        // handle successful refresh
        if success {
          // get the current value
          guard let anotherValue = self.status(host, address: node.address).values.first?.value else {
            completion(false)
            return
          }

          // check that the value has changed
          if value == nil || value != anotherValue {
            completion(true)
            return
          }
        }
        
        // exit if we have timed out
        if DispatchTime.now() > max {
          completion(false)
          return
        }
        
        // otherwise try again
        self.performRefresh(host: host, node: node, max: max, completion: completion)
      })
    }
  }
  
  @objc fileprivate func updateStatus(n: Notification) {
    guard let host = n.object as? SwiftISYHost else { return }
    guard let userInfo = n.userInfo as? [String: Any] else { return }
    guard let address = userInfo[SwiftISY.Elements.address] as? String else { return }
    guard let value = userInfo[SwiftISY.Attributes.value] as? UInt8 else { return }
    guard let formatted = userInfo[SwiftISY.Attributes.formatted] as? String else { return }
    guard let status = self.status(host, address: address).values.first else { return }
    status.value = value
    status.formatted = formatted
    DispatchQueue.main.async {
      let nc = NotificationCenter.default
      nc.post(name: SwiftISY.Notifications.didRefresh.notification, object: host, userInfo: userInfo)
    }
  }
  
  fileprivate func handleNotifications() {
    let nc = NotificationCenter.default
    nc.addObserver(self, selector: #selector(needsRefresh(n:)), name: SwiftISY.Notifications.needsRefresh.notification, object: nil)
    nc.addObserver(self, selector: #selector(updateStatus(n:)), name: SwiftISY.Notifications.updateStatus.notification, object: nil)
  }
  
}
