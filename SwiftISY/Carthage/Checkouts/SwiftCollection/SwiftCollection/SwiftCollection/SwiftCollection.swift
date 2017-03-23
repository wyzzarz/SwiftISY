//
//  SwiftCollection.swift
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

public struct SwiftCollection {
  
  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Bundle
   * -----------------------------------------------------------------------------------------------
   */

  /// Bundle Id for this framework.
  public static let bundleId = "com.wyz.SwiftCollection"

  /// Bundle for this framework.
  public static let bundle = Bundle(identifier: bundleId)!
  
  /// Name for this framework.
  public static var name: String {
    let info = bundle.infoDictionary!
    let name = info["CFBundleName"] as! String
    let version = info["CFBundleShortVersionString"] as! String
    return "\(name) v\(version)"
  }

  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Error
   * -----------------------------------------------------------------------------------------------
   */
  
  /// Errors that can be thrown for `SwiftCollection`.
  ///
  /// - missingId: There is no `id` for a document.
  /// - existingId:  A document with the `id` already exists in the collection.
  /// - generateId: Unable to generate a new unique id.
  /// - notFound: Object cannot be found.
  /// - invalidJson: Object can not be serialized to JSON.  Contains invalid properties.
  public enum Errors: Error {
    
    /// There is no `id` for a document.
    case missingId
    
    /// A document with the `id` already exists in the collection.
    case existingId
    
    /// Unable to generate a new unique id.
    case generateId
    
    /// Object cannot be found.
    case notFound
    
    /// Object can not be serialized to/from JSON.  Contains invalid properties.
    case invalidJson
    
    /// Missing key for JSON serialized object.
    case missingJsonKey
    
  }

  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Functions
   * -----------------------------------------------------------------------------------------------
   */
  
  /// Unwraps optional values.  `NSNull` is substituted for `nil` values.
  ///
  /// - Parameter any: Object to unwrap.
  /// - Returns: Original value if not optional, unwrapped value or `NSNull` when `nil`.
  public static func unwrap(any: Any) -> Any {
    let mirror = Mirror(reflecting: any)
    
    // return original if it is not optional
    if mirror.displayStyle != .optional { return any }
    
    // handle nil optional
    if mirror.children.count == 0 { return NSNull() }
    
    // otherwise return some value
    let (_, some) = mirror.children.first!
    return some
  }

}
