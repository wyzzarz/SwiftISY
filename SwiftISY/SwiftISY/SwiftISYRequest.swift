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
  /// - objects: Contains `SwiftISYObjects` if the request was successful, `nil` otherwise.
  ///
  public struct Result {
    
    /// `true` if the request was successful, `false` otherwise.
    public var success: Bool = false
    
    /// Contains `Error` if the request failed, `nil` otherwise.
    public var error: SwiftISY.RequestError?
    
    /// Contains `SwiftISYObjects` if the request was successful, `nil` otherwise.
    public var objects: SwiftISYObjects?
    
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
  ///     let request = SwiftISYRequest(host: SwiftISYHost(host: "your host", user: "your username", password: "your password"))
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
  public init(host: SwiftISYHost) {
    self.host = host
  }
  
}

// -------------------------------------------------------------------------------------------------
// MARK: - REQUEST
// -------------------------------------------------------------------------------------------------

extension SwiftISYRequest {
  
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
  
  private func parseResponse(data: Data, response: HTTPURLResponse, completion: @escaping Completion) {
    _ = SwiftISYParser(data: data).parse() { (objects) in
      DispatchQueue.main.async {
        completion(Result(success: true, error: nil, objects: objects))
      }
    }
  }
  
  private func handleResponse(data: Data?, response: HTTPURLResponse, completion: @escaping Completion) {
    // handle successful request
    if let statusCode = SwiftISY.HttpStatusCodes(rawValue: response.statusCode) {
      if statusCode.isSuccessful && data != nil {
        parseResponse(data: data!, response: response, completion: completion)
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

  fileprivate func executeRest(command: String, completion: @escaping Completion) {
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
      self.handleResponse(data: data, response: httpResponse!!, completion: completion)
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
    executeRest(command: "rest/nodes", completion: completion)
  }
  
  ///
  /// Gets statuses for all nodes from the host.
  ///
  /// - Parameter completion: The closure to execute once the network request has completed.
  ///
  public func statuses(completion: @escaping Completion) {
    executeRest(command: "rest/status", completion: completion)
  }
  
}

// -------------------------------------------------------------------------------------------------
// MARK: - COMMAND
// -------------------------------------------------------------------------------------------------

extension SwiftISYRequest {
  
  ///
  /// Executes a command for the specified node on the host.
  ///
  /// - Parameter address: Address for the node/group.
  /// - Parameter command: Command to be issued for the node.
  /// - Parameter completion: The closure to execute once the network request has completed.
  ///
  fileprivate func deviceCommand(address: String, command: String, completion: @escaping Completion) {
    let encodedAddress = address.addingPercentEncoding(withAllowedCharacters:.urlHostAllowed)!
    executeRest(command: "rest/nodes/\(encodedAddress)/cmd/\(command)", completion: completion)
  }
  
  ///
  /// Turns the specifed node on.
  ///
  /// - Parameter address: Address for the node/group.
  /// - Parameter completion: The closure to execute once the network request has completed.
  ///
  public func on(address: String, completion: @escaping Completion) {
    deviceCommand(address: address, command: "DON", completion: completion)
  }

  ///
  /// Turns the specifed node off.
  ///
  /// - Parameter address: Address for the node/group.
  /// - Parameter completion: The closure to execute once the network request has completed.
  ///
  public func off(address: String, completion: @escaping Completion) {
    deviceCommand(address: address, command: "DOF", completion: completion)
  }

}
