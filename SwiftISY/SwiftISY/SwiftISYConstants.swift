//
//  SwiftISYConstants.swift
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

extension NSNotification.Name {
  static let SwiftISYControllerDidFetchObjects = NSNotification.Name("SwiftISYControllerDidFetchObjects")
  static let SwiftISYControllerDidFetchStatuses = NSNotification.Name("SwiftISYControllerDidFetchStatuses")
}

public struct SwiftISYConstants {
  
  /// Bundle Id for this framework.
  public static let bundleId = "com.wyz.SwiftISY"
  
  /// Name for this framework.
  public static var name: String {
    get {
      let info = Bundle(identifier: bundleId)!.infoDictionary!
      let name = info["CFBundleName"] as! String
      let version = info["CFBundleShortVersionString"] as! String
      return "\(name) v\(version)"
    }
  }
  
  ///
  /// Keys for ISY attributes.
  ///
  public struct Attributes {
    
    static let flag = "flag"
    static let formatted = "formatted"
    static let id = "id"
    static let succeeded = "succeeded"
    static let type = "type"
    static let unitsOfMeasure = "uom"
    static let value = "value"
    
  }

  ///
  /// Keys for ISY elements
  ///
  public struct Elements {
    
    static let address = "address"
    static let controllerIds = "controllerIds"
    static let dcPeriod = "dcPeriod"
    static let deviceClass = "deviceClass"
    static let deviceGroup = "deviceGroup"
    static let elkId = "ELK_ID"
    static let enabled = "enabled"
    static let family = "family"
    static let group = "group"
    static let link = "link"
    static let name = "name"
    static let nodes = "nodes"
    static let node = "node"
    static let parent = "parent"
    static let pnode = "pnode"
    static let property = "property"
    static let responderIds = "responderIds"
    static let restResponse = "RestResponse"
    static let status = "status"
    static let type = "type"
    static let wattage = "wattage"
    
  }
  
  ///
  /// Values for ISY property types.
  ///
  public struct PropertyTypes {
    
    static let status = "ST"
    
  }

  ///
  /// Values for ISY member types.
  ///
  public enum MemberTypes: UInt {
    
    case none = 0
    case controller = 16
    case responder = 32
    
    var description: String {
      switch self {
      case .none: return "Responder"
      case .controller: return "Controller"
      case .responder: return " Responder"
      }
    }
    
  }
  
  ///
  /// Standard HTTP status codes.
  ///
  public enum HttpStatusCodes: Int {
    // Informational (1xx)
    case shouldContinue = 100
    case switchingProtocols = 101
    
    // Successful (2xx)
    case ok = 200
    case created = 201
    case accepted = 202
    case nonAuthoritativeInformation = 203
    case noContent = 204
    case resetContent = 205
    case partialContent = 206
    
    // Redirection (3xx)
    case multipleChoices = 300
    case movedPermanently = 301
    case found = 302
    case seeOther = 303
    case notModified = 304
    case useProxy = 305
    case redictionUnused = 306
    case temporaryRedirect = 307
    
    // Client Error (4xx)
    case badRequest = 400
    case unauthorized = 401
    case paymentRequired = 402
    case forbidden = 403
    case notFound = 404
    case methodNotAllowed = 405
    case notAcceptable = 406
    case proxyAuthenticationRequired = 407
    case requestTimeout = 408
    case conflict = 409
    case gone = 410
    case lengthRequired = 411
    case preconditionFailed = 412
    case requestEntityTooLarge = 413
    case RequestUriTooLong = 414
    case unsupportedMediaType = 415
    case requestedRangeNotSatisfiable = 416
    case expectationFailed = 417
    
    // Server Error
    case internalServerError = 500
    case notImplemented = 501
    case badGateway = 502
    case serviceUnavailable = 503
    case gatewayTimeout = 504
    case httpVersionNotSupported = 505
    
    /// Whether the status code is in the range 1xx.
    public var isInformational: Bool {
      get { return (HttpStatusCodes.shouldContinue.rawValue...HttpStatusCodes.switchingProtocols.rawValue).contains(self.rawValue) }
    }
    
    /// Whether the status cusde is in the range 2xx.
    public var isSuccessful: Bool {
      get { return (HttpStatusCodes.ok.rawValue...HttpStatusCodes.partialContent.rawValue).contains(self.rawValue) }
    }
 
    /// Whether the status code is in the range 3xx.
    public var isRedirection: Bool {
      get { return (HttpStatusCodes.multipleChoices.rawValue...HttpStatusCodes.temporaryRedirect.rawValue).contains(self.rawValue) }
    }
    
    // Whether the status code is in the range 4xx.
    public var isClientError: Bool {
      get { return (HttpStatusCodes.badRequest.rawValue...HttpStatusCodes.expectationFailed.rawValue).contains(self.rawValue) }
    }
    
    /// Whether the status code is in the range 5xx.
    public var isServerError: Bool {
      get { return (HttpStatusCodes.internalServerError.rawValue...HttpStatusCodes.httpVersionNotSupported.rawValue).contains(self.rawValue) }
    }
    
    /// Whether the status code is the the range 4xx or 5xx.
    public var isError: Bool {
      return isClientError || isServerError
    }
    
    /// Returns a localized string for the status ode.
    var localizedString: String {
      get { return HTTPURLResponse.localizedString(forStatusCode: self.rawValue) }
    }

    /// Returns a friendly description for the status code.
    var description: String {
      switch self {
      // Informational
      case .shouldContinue: return "Continue"
      case .switchingProtocols: return "Switching Protocols"
        // Successful
      case .ok: return "OK"
      case .created: return "Created"
      case .accepted: return "Accepted"
      case .nonAuthoritativeInformation: return "Non-AuthoritativeInformation"
      case .noContent: return "No Content"
      case .resetContent: return "Reset Content"
      case .partialContent: return "Partial Content"
        // Redirection
      case .multipleChoices: return "Multiple Choices"
      case .movedPermanently: return "Moved Permanently"
      case .found: return "Found"
      case .seeOther: return "See Other"
      case .notModified: return "Not Modified"
      case .useProxy: return "Use Proxy"
      case .redictionUnused: return "Redirection (Unused)"
      case .temporaryRedirect: return "Temporary Redirect"
      // Client Error
      case .badRequest: return "Bad Requst"
      case .unauthorized: return "Unauthorized"
      case .paymentRequired: return "Payment Required"
      case .forbidden: return "Forbidden"
      case .notFound: return "Not Found"
      case .methodNotAllowed: return "Method Not Allowed"
      case .notAcceptable: return "Not Acceptable"
      case .proxyAuthenticationRequired: return "Proxy Authentication Required"
      case .requestTimeout: return "Request Timeout"
      case .conflict: return "Conflict"
      case .gone: return "Gone"
      case .lengthRequired: return "Length Required"
      case .preconditionFailed: return "Precondition Failed"
      case .requestEntityTooLarge: return "Request Entity Too Large"
      case .RequestUriTooLong: return "Request URI Too Long"
      case .unsupportedMediaType: return "Unsupported Media Type"
      case .requestedRangeNotSatisfiable: return "Requested Range Not Satisfiable"
      case .expectationFailed: return "Expectation Failed"
      // Server Error
      case .internalServerError: return "Internal Server Error"
      case .notImplemented: return "Not Implemented"
      case .badGateway: return "Bad Gateway"
      case .serviceUnavailable: return "Service Unavailable"
      case .gatewayTimeout: return "Gateway Timeout"
      case .httpVersionNotSupported: return "HTTP Version Not Supported"
      }
    }

  }
  
  ///
  /// Flags for a node or group.
  ///
  public struct NodeFlags: OptionSet {
    
    public let rawValue: UInt8
    
    public static let none         = NodeFlags(rawValue: 0x00)
    public static let isInit       = NodeFlags(rawValue: 0x01)  // Needs to be initialized
    public static let toScan       = NodeFlags(rawValue: 0x02)  // Needs to be scanned
    public static let isGroup      = NodeFlags(rawValue: 0x04)  // It’s a group!
    public static let isRoot       = NodeFlags(rawValue: 0x08)  // It’s the root group
    public static let isError      = NodeFlags(rawValue: 0x10)  // It’s in error!
    public static let isNew        = NodeFlags(rawValue: 0x20)  // Brand new node
    public static let toDelete     = NodeFlags(rawValue: 0x40)  // Has to be deleted later
    public static let isDeviceRoot = NodeFlags(rawValue: 0x80)  // Root device such as KPL load
    
    public init(rawValue: UInt8) {
      self.rawValue = rawValue
    }
    
  }
  
}

///
/// The `SwiftISYError` class includes errors used in this framework.
///
public struct SwiftISYError: Error {
  
  /// Kinds of errors.
  public enum Kind {
    case none
    case invalidUser
    case invalidPassword
    case invalidCredential
    case invalidCommand
    case invalidHost
    case badRequest
    case http
  }
  
  /// Kind of error.
  public let kind: Kind
  
  /// Object associated with this error.
  public var object: Any?
  
  /// Returns a localized description for this error.
  fileprivate var _localizedDescription: String = ""
  public var localizedDescription: String {
    get {
      switch kind {
      case .none: return _localizedDescription
      case .invalidUser: return "Invalid or Missing Username"
      case .invalidPassword: return "Invalid or Missing Password"
      case .invalidCredential: return "Invalid Username or Password"
      case .invalidCommand: return "Invalid or Missing Command"
      case .invalidHost: return "Invalid or Missing Host"
      case .badRequest: return "Bad Request"
      case .http: return httpStatusCode!.description
      }
    }
    set {
      _localizedDescription = newValue
    }
  }
  
  ///
  /// Creates a `SwiftISYError` with this kind of error.
  ///
  /// - Parameter kind: Kind of error.
  ///
  public init(kind: Kind) {
    self.kind = kind
    self.httpStatusCode = nil
  }
  
  ///
  /// Creates a `SwiftISYError` with this localized description.  Kind of error defaults to `none`.
  ///
  /// - Parameter localizedDescription: Localized description for this error.
  /// - Parameter object: Object for this error or nil if there is none.
  ///
  public init(localizedDescription: String, object: Any?) {
    self.kind = .none
    self.object = object
    self.httpStatusCode = nil
    self.localizedDescription = localizedDescription
  }
  
  ///
  /// Creates a `SwiftISYError` with the localized description from this error.  Kind of error 
  /// defaults to `none`.
  ///
  /// - Parameter error: Error to be applied.
  ///
  public init(error: Error) {
    self.init(localizedDescription: error.localizedDescription, object: nil)
  }
  
  /*
   * HTTP Error
   */
  
  /// HTTP status code for this error.
  public let httpStatusCode: SwiftISYConstants.HttpStatusCodes?

  ///
  /// If the HTTP status code is in the range 4xx or 5xx, this function returns an instance of 
  /// `SwiftISYError` for HTTP and this status code.
  ///
  /// - Parameter statusCode: HTTP status code.
  /// - Returns: An instance of `SwiftISYError` if the HTTP status code is an error.
  ///
  public static func httpError(statusCode: Int) -> SwiftISYError? {
    guard let sc = SwiftISYConstants.HttpStatusCodes(rawValue: statusCode) else { return nil }
    return SwiftISYError(httpStatusCode: sc)
  }
  
  ///
  /// If the HTTP status code is a client or server error, a `SwiftISYError` is created for HTTP
  /// and this status code.
  ///
  /// - Parameter localizedDescription: Localized description for this error.
  /// - Parameter object: Object for this error or nil if there is none.
  ///
  public init?(httpStatusCode: SwiftISYConstants.HttpStatusCodes) {
    if !httpStatusCode.isError { return nil }
    self.kind = .http
    self.httpStatusCode = httpStatusCode
  }
  
}

public struct ValidationError: Error {
  
  public enum Kind {
    case required
    case tooLong
    case tooShort
  }
  
  public let kind: Kind
  public let field: String
  public let friendlyName: String
  public let maxLength: UInt
  public let minLength: UInt
  
  public init(kind: Kind, field: String, friendlyName: String) {
    self.kind = kind
    self.field = field
    self.friendlyName = friendlyName
    maxLength = 0
    minLength = 0
  }

  public init(kind: Kind, field: String, friendlyName: String, minLength: UInt, maxLength: UInt) {
    self.kind = kind
    self.field = field
    self.friendlyName = friendlyName
    self.minLength = minLength
    self.maxLength = maxLength
  }

  var localizedDescription: String {
    get {
      switch kind {
      case .required: return "\(friendlyName.localizedCapitalized) is required."
      case .tooLong: return "\(friendlyName.localizedCapitalized) should be at most \(maxLength) characters."
      case .tooShort: return "\(friendlyName.localizedCapitalized) should be at least \(maxLength) characters."
      }
    }
  }
  
}
