//
//  SwiftISYRequest.swift
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
//  ================================================================================================
//
//  For additional information, see:
//    http://wiki.universal-devices.com/index.php?title=ISY_Developers:API:REST_Interface
//

import Foundation

// MARK: -

///
/// `SwiftISYRequest` provides an API to connect to ISY series devices to fetch data and issue
/// commands.
///
public struct SwiftISYRequest {
  
  ///
  /// Results from completion of a request.
  ///
  /// - success: `true` if the request was successful, `false` otherwise.
  /// - error: Contains `Error` if the request failed, `nil` otherwise.
  /// - objects: Contains `Objects` if the request was successful, `nil` otherwise.
  ///
  public struct Result {
    
    /// `true` if the request was successful, `false` otherwise.
    public var success: Bool = false
    
    /// Contains `Error` if the request failed, `nil` otherwise.
    public var error: SwiftISY.RequestError?
    
    /// Contains `Objects` if the request was successful, `nil` otherwise.
    public var objects: Objects?
    
  }
  
  ///
  /// Holds a collection of ISY objects returned from a request.
  ///
  /// - responses: Array of responses (0 or more) from commands to the host.
  /// - nodes: Array of nodes (0 or more) returned from the host.
  /// - groups: Array of groups (0 or more) returned from the host.
  /// - statuses: Array of statuses (0 or more) for nodes returned from the host.
  ///
  public struct Objects {
    
    public var responses: [SwiftISYResponse] = []
    public var nodes: [SwiftISYNode] = []
    public var groups: [SwiftISYGroup] = []
    public var statuses: [String: SwiftISYStatus] = [:]
    
  }

  ///
  /// Closure for completion of a request.
  ///
  /// - Parameter result:   Result from completion of a request.
  ///
  public typealias Completion = (_ result: Result) -> Void

  fileprivate let session = URLSession(configuration: URLSessionConfiguration.default)
  
  /// Host to be connected to for this request.
  public var host: SwiftISYHost? {
    get {
      return _host
    }
    set {
      _host = newValue
    }
  }
  fileprivate var _host: SwiftISYHost?
  
  ///
  /// Creates a request for the specified host.  Host requires at minimum an address,
  /// username and password.  The username and password are used to generate an authorization
  /// header when connecting to the host.
  ///
  /// The following example creates a request to get all nodes and processes each node returned.
  ///
  ///     // create a request
  ///     let request = SwiftISYRequest(SwiftISYHost(host: "your host", user: "your username", password: "your password"))
  ///
  ///     // get all nodes for this host
  ///     request.nodes { (results) in
  ///       if let objects = results.objects {
  ///         // loop through all devices on this host
  ///         for node in objects.nodes {
  ///           // process this device
  ///           ...
  ///         }
  ///       }
  ///     }
  ///
  /// - Parameter host: Host for the request.
  ///
  public init(_ host: SwiftISYHost) {
    self.host = host
  }
  
}

// -------------------------------------------------------------------------------------------------
// MARK: - REQUEST
// -------------------------------------------------------------------------------------------------

extension SwiftISYRequest {
  
  /// Returns an encoded address to be used in a URL.
  ///
  /// - Parameter address: The address to be encoded.
  /// - Returns: The encoded address.
  public static func encodedAddress(_ address: String) -> String {
    return address.addingPercentEncoding(withAllowedCharacters:.urlHostAllowed)!
  }
  
  private func makeRequest(command: String) -> (URLRequest?, SwiftISY.RequestError?) {
    // ensure there is a command
    if command.characters.count == 0 { return (nil, SwiftISY.RequestError(kind: .invalidCommand)) }

    // ensure there is a host
    guard let host = self.host else { return (nil, SwiftISY.RequestError(kind: .invalidHost)) }

    // get address for this host
    let address = host.host
    if address.characters.count == 0 { return (nil, SwiftISY.RequestError(kind: .invalidHost)) }

    // get authorization header for this host
    let (authorization, error) = host.authorization()
    if error != nil { return (nil, error) }

    // get url to connect to this host
    guard let url = URL(string: "http://\(address)/\(command)") else { return (nil, SwiftISY.RequestError(kind: .badRequest)) }
    
    // create a request and include the authorization header
    var request = URLRequest(url: url)
    request.setValue(authorization, forHTTPHeaderField: "Authorization")
    
    // done
    return (request, nil)
  }
  
  private func parseResponse(data: Data, response: HTTPURLResponse, userInfo: SwiftISY.UserInfo, completion: @escaping Completion) {
    _ = SwiftISYParser(data: data, userInfo: userInfo).parse() { (objects) in
      DispatchQueue.main.async {
        completion(Result(success: true, error: nil, objects: objects))
      }
    }
  }
  
  private func handleResponse(data: Data?, response: HTTPURLResponse, userInfo: SwiftISY.UserInfo, completion: @escaping Completion) {
    // handle successful request
    if let statusCode = SwiftISY.HttpStatusCodes(rawValue: response.statusCode) {
      if statusCode.isSuccessful && data != nil {
        parseResponse(data: data!, response: response, userInfo: userInfo, completion: completion)
        return
      }
    }
    
    // otherwise fail
    let localizedString = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
    handleError(error: SwiftISY.RequestError(localizedDescription: localizedString, object: response), completion: completion)
  }
  
  private func handleError(error: SwiftISY.RequestError?, completion: @escaping Completion) {
    if let anError = error {
      print(anError.localizedDescription)
    } else {
      print("Unknown Error")
    }
    DispatchQueue.main.async {
      completion(Result(success: false, error: error, objects: nil))
    }
  }

  fileprivate func executeRest(command: String, userInfo: SwiftISY.UserInfo = [:], completion: @escaping Completion) {
    // build request for rest command and include authorization
    let (request, error) = makeRequest(command: command)
    if error != nil {
      handleError(error: error, completion: completion)
      return
    }
    
    // perform the request
    session.dataTask(with: request!) { (data, response, error) in
      guard error == nil else {
        self.handleError(error: SwiftISY.RequestError(error: error!), completion: completion)
        return
      }
      let httpResponse = response as? HTTPURLResponse?
      self.handleResponse(data: data, response: httpResponse!!, userInfo: userInfo, completion: completion)
      }.resume()
  }

}

// -------------------------------------------------------------------------------------------------
// MARK: - QUERY
// -------------------------------------------------------------------------------------------------

extension SwiftISYRequest {
  
  ///
  /// Gets all nodes, groups and statuses from the host.
  ///
  /// - Parameter completion: The closure to execute once the network request has completed.
  ///
  public func nodes(completion: @escaping Completion) {
    executeRest(command: "rest/nodes") { (result) in
      defer {
        completion(result)
      }
      // apply status from property to node
      guard result.success else { return }
      guard let objects = result.objects else { return }
      let statuses = objects.statuses
      for node in objects.nodes {
        if let status = statuses[node.address] {
          node.options = SwiftISY.OptionFlags(string: status.unitOfMeasure)
        }
      }
    }
  }
  
  ///
  /// Gets statuses for all nodes from the host.
  ///
  /// - Parameter completion: The closure to execute once the network request has completed.
  ///
  public func statuses(completion: @escaping Completion) {
    executeRest(command: "rest/status", completion: completion)
  }
  
  ///
  /// Gets status for the specified node.
  ///
  /// - Parameters:
  ///   - address: Address for the node.
  ///   - completion: The closure to execute once the network request has completed.
  public func status(address: String, completion: @escaping Completion) {
    let encodedAddress = SwiftISYRequest.encodedAddress(address)
    executeRest(command: "rest/nodes/\(encodedAddress)/ST", userInfo: [SwiftISY.Elements.address: address], completion: completion)
  }

}

// -------------------------------------------------------------------------------------------------
// MARK: - COMMAND
// -------------------------------------------------------------------------------------------------

extension SwiftISYRequest {
  
  ///
  /// Executes a command for the specified node on the host.
  ///
  /// - Parameters:
  ///   - address: Address for the node/group.
  ///   - command: Command to be issued for the node.
  ///   - completion: The closure to execute once the network request has completed.
  ///
  fileprivate func deviceCommand(address: String, command: String, completion: @escaping Completion) {
    let encodedAddress = SwiftISYRequest.encodedAddress(address)
    executeRest(command: "rest/nodes/\(encodedAddress)/cmd/\(command)") { (result) in
      DispatchQueue.main.async {
        NotificationCenter.default.post(name: .needsRefresh, object: self.host, userInfo: [SwiftISY.Elements.address: address])
      }
      completion(result)
    }
  }
  
  ///
  /// Turns the specifed node on.
  ///
  /// - Parameters:
  ///   - address: Address for the node/group.
  ///   - fast: `true` if the device is to be turned on fast; `false` otherwise.  Default is
  ///     `false`.
  ///   - brightness: Sets the brightness level for a dimmable light from 0.0 (0%) to 1.0 (100%).
  ///   - completion: The closure to execute once the network request has completed.
  public func on(address: String, fast: Bool = false, brightness: Double = 1.0, completion: @escaping Completion) {
    var command = fast ? "DFON" : "DON"
    let brightness = min(1.0, max(0.0, brightness))
    if brightness < 1.0 { command += "/\(Int(round(brightness * 255)))" }
    deviceCommand(address: address, command: command, completion: completion)
  }

  ///
  /// Turns the specifed node off.
  ///
  /// - Parameters:
  ///   - address: Address for the node/group.
  ///   - fast: `true` if the device is to be turned off fast; `false` otherwise.  Default is
  ///     `false`.
  ///   - completion: The closure to execute once the network request has completed.
  ///
  public func off(address: String, fast: Bool = false, completion: @escaping Completion) {
    deviceCommand(address: address, command: fast ? "DFOF" : "DOF", completion: completion)
  }

  ///
  /// Brightens the specifed node by ~3%.
  ///
  /// - Parameters:
  ///   - address: Address for the node/group.
  ///   - completion: The closure to execute once the network request has completed.
  ///
  public func brighten(address: String, completion: @escaping Completion) {
    deviceCommand(address: address, command: "BRT", completion: completion)
  }

  ///
  /// Dims the specifed node by ~3%.
  ///
  /// - Parameters:
  ///   - address: Address for the node/group.
  ///   - completion: The closure to execute once the network request has completed.
  ///
  public func dim(address: String, completion: @escaping Completion) {
    deviceCommand(address: address, command: "DIM", completion: completion)
  }

}
