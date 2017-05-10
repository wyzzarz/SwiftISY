//
//  SwiftISYObject.swift
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

// -------------------------------------------------------------------------------------------------
// MARK: -
// -------------------------------------------------------------------------------------------------

/// Associates a host to the object that adopts this protocol.  The host is identified by its `id`.
public protocol SwiftISYHostKeyProtocol {
  
  /// `id` of host; or `nil` if none.
  var hostId: SwiftCollection.Id? { get set }
  
  /// Returns a host object for the host id; or `nil` if it does not exist.
  var host: SwiftISYHost? { get }
  
  init()
  
  /// Initializes with this host.
  ///
  /// - Parameter hostId: `Id' of host.
  init(hostId: SwiftCollection.Id)
  
}

extension SwiftISYHostKeyProtocol {
  
  public var hostId: SwiftCollection.Id? {
    get {
      return objc_getAssociatedObject(self, &SwiftISY.AssociatedKeys.hostIdKey) as? SwiftCollection.Id
    }
    set {
      setHost(nil)
      objc_setAssociatedObject(self, &SwiftISY.AssociatedKeys.hostIdKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
  
  public var host: SwiftISYHost? {
    get {
      // check for host id
      guard let hostId = self.hostId else { return nil }
      
      // get saved host
      let host = objc_getAssociatedObject(self, &SwiftISY.AssociatedKeys.hostKey) as? SwiftISYHost
      if host != nil { return host }
      
      // otherwise find this host
      let hosts = SwiftISYHosts()
      try? hosts.load(jsonStorage: .userDefaults, completion: nil)
      let thisHost = (hosts.filter { (host) -> Bool in
        return host.id == hostId
      }).first
      setHost(thisHost)
      
      return thisHost
    }
  }

  fileprivate func setHost(_ host: SwiftISYHost?) {
    objc_setAssociatedObject(self, &SwiftISY.AssociatedKeys.hostKey, host, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  }
  
  public init(hostId: SwiftCollection.Id) {
    self.init()
    self.hostId = hostId
  }

}

// -------------------------------------------------------------------------------------------------
// MARK: -
// -------------------------------------------------------------------------------------------------

/// Associates a set of addresses for objects that adopt this protocol.  This protocol should be
/// adopted by a collection.
public protocol SwiftISYAddressesProtocol {

  associatedtype SwiftISYAddressesProtocolElement: SCDocument
  
  /// Set of ISY device addresses.
  var addresses: NSOrderedSet { get }

  /// Returns the location of the specified address.
  ///
  /// - Parameter address: Address to be located.
  /// - Returns: Index of the address; or `NSNotFound`
  func index(ofAddress address: String) -> Int
  
  /// Tests whether address exists in the collection
  ///
  /// - Parameter address: Address to br located.
  /// - Returns: `true` if the address exists in the collection; `false` otherwise.
  func contains(address: String) -> Bool

  /// Returns the document for this address.
  ///
  /// - Parameter address: Address to be located.
  /// - Returns: The document for this address; or `nil` if the address does not exist.
  func document(address: String) -> SwiftISYAddressesProtocolElement?
  
}

extension SwiftISYAddressesProtocol {

  public var addresses: NSOrderedSet {
    get {
      if let addresses: NSOrderedSet = objc_getAssociatedObject(self, &SwiftISY.AssociatedKeys.addressesKey) as? NSOrderedSet { return addresses }
      let addresses = NSMutableOrderedSet()
      objc_setAssociatedObject(self, &SwiftISY.AssociatedKeys.addressesKey, addresses, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return addresses
    }
  }

  final public func index(ofAddress address: String) -> Int {
    return addresses.index(of: address)
  }

  final public func contains(address: String) -> Bool {
    return index(ofAddress: address) != NSNotFound
  }

}
