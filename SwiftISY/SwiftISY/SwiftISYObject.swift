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

public protocol SwiftISYHostKeyProtocol {
  
  var hostId: SwiftCollection.Id? { get set }
  
  var host: SwiftISYHost? { get set }
  
  init()
  
  init(hostId: SwiftCollection.Id)
  
}

extension SwiftISYHostKeyProtocol {
  
  public var hostId: SwiftCollection.Id? {
    get {
      return objc_getAssociatedObject(self, &SwiftISY.AssociatedKeys.hostIdKey) as? SwiftCollection.Id
    }
    set {
      self.host = nil
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
      objc_setAssociatedObject(self, &SwiftISY.AssociatedKeys.hostKey, thisHost, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      
      return thisHost
    }
    set {
      objc_setAssociatedObject(self, &SwiftISY.AssociatedKeys.hostKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
  
  public init(hostId: SwiftCollection.Id) {
    self.init()
    self.hostId = hostId
  }

}

// -------------------------------------------------------------------------------------------------
// MARK: -
// -------------------------------------------------------------------------------------------------

public protocol SwiftISYAddressesProtocol {

  associatedtype SwiftISYAddressesProtocolElement: SCDocument
  
  var addresses: NSOrderedSet { get }

  func index(ofAddress address: String) -> Int
  
  func contains(address: String) -> Bool
  
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

  /// Returns the location of the specified address.
  ///
  /// - Parameter address: Address to be located.
  /// - Returns: Index of the address; or `NSNotFound`
  final public func index(ofAddress address: String) -> Int {
    return addresses.index(of: address)
  }

  /// Tests whether address exists in the collection
  ///
  /// - Parameter address: Address to br located.
  /// - Returns: `true` if the address exists in the collection; `false` otherwise.
  final public func contains(address: String) -> Bool {
    return index(ofAddress: address) != NSNotFound
  }

}
