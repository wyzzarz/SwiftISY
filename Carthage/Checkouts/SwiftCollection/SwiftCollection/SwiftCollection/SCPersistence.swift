//
//  SCPersistence.swift
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

/*
 * MARK: -
 */

extension SwiftCollection {
  
  /// A JSON serializable dictionary object.
  ///
  /// See [JSONSerialization](apple-reference-documentation://hsVFr-345J) for more information.
  public typealias JsonDictionary = [String: AnyObject]

  /// A JSON serializable array object.
  ///
  /// See [JSONSerialization](apple-reference-documentation://hsVFr-345J) for more information.
  public typealias JsonArray = [AnyObject]

  /// Persistence storage options:
  ///
  /// - userDefaults: `UserDefaults` as the persistence store.
  public enum Storage: Int {
    
    /// `UserDefaults` as the persistence store.
    case userDefaults
    
  }
  
}

/*
 * MARK: -
 */

/// Generic collections cannot be processed directly.  This protocol adds support for collections
/// to provide their own elements.
public protocol SCJsonCollectionProtocol {
  
  /// Collections should return their enumerated elements as an array.
  ///
  /// - Returns: Array of elements for the collection.
  func jsonCollectionElements() -> [Any]

}

/*
 * MARK: -
 */

/// `SCJsonObject` supports persistence to physical storage.  It provides functions to serialize an 
/// object into JSON.  And to load an object from JSON.
open class SCJsonObject: NSObject {
  
  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Initialize
   * -----------------------------------------------------------------------------------------------
   */
  
  override public required init() {
    super.init()
  }

  /// Initializes an instance of this class from this JSON object.
  ///
  /// - Parameter json: JSON object to be loaded.  Must be either an Array or Dictionary.
  /// - Throws: `invalidJson` if the JSON object is not an Array or Dictionary.
  public required init(json: AnyObject) throws {
    super.init()
    _ = try load(jsonObject: json)
  }
  
  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Serialize
   * -----------------------------------------------------------------------------------------------
   */

  /// Serializes a JSON array from a collection.
  ///
  /// - Parameter collection: Collection to be serialized.
  /// - Returns: JSON serialized array.
  fileprivate func _jsonCollection(collection: SCJsonCollectionProtocol) -> SwiftCollection.JsonArray? {
    // return results as an array
    var json: SwiftCollection.JsonArray = []
    
    // get elements for this collection
    let elements = collection.jsonCollectionElements()
    
    // process each element in the array
    for element in elements {
      // serialize this element and add it to the array
      if let jsonElement = element as? SCJsonObject {
        if let jsonObject = jsonElement.jsonObject() {
          json.append(jsonObject)
          continue
        }
      }
      if let jsonElement = _jsonObject(object: element) {
        json.append(jsonElement)
      }
    }
    
    return json.count > 0 ? json : nil
  }
  
  /// Serializes a JSON array from an array.
  ///
  /// - Parameter array: Array to be serialized.
  /// - Returns: JSON serialized array.
  fileprivate func _jsonArray(array: NSArray) -> SwiftCollection.JsonArray? {
    // return results as an array
    var json: SwiftCollection.JsonArray = []
    
    // process each element in the array
    for element in array {
      // serialize this element and add it to the array
      if let jsonElement = _jsonObject(object: element) {
        json.append(jsonElement)
      }
    }
    
    return json.count > 0 ? json : nil
  }

  /// Serializes a JSON dictionary from a dictionary.
  ///
  /// - Parameter dict: Dictionary to be serialized.
  /// - Returns: JSON serialized dictionary.
  fileprivate func _jsonDictionary(dict: NSDictionary) -> SwiftCollection.JsonDictionary? {
    // return results as a dictionary
    var json: SwiftCollection.JsonDictionary = [:]
    
    // process each element in the dictionary
    for (key, value) in dict {
      if let key = key as? String {
        // serialize this element and add it to the dictionary
        if let jsonValue = _jsonObject(object: value) {
          json[key] = jsonValue
        }
      }
    }
    
    return json.count > 0 ? json : nil
  }
  
  /// Serializes a JSON array from a tuple.  The elements of a tuple are converted to elements of
  /// an array.
  ///
  /// - Parameter object: Tuple to be serialized.
  /// - Returns: JSON serialized array.
  fileprivate func _jsonTuple(object: Any) -> SwiftCollection.JsonArray? {
    let mirror = Mirror(reflecting: object)
    if mirror.children.count == 0 { return nil }
    
    var json: SwiftCollection.JsonArray = []
    
    for case let (_, value) in mirror.children {
      // serialize this element and add it to the array
      if let jsonElement = _jsonObject(object: value) {
        json.append(jsonElement)
      }
    }
    
    return json.count > 0 ? json : nil
  }

  /// Serializes a JSON object.
  ///
  /// - A String is returned unchanged.
  /// - A Number is returned unchanged.
  /// - An Array is returned with each element serialized.
  /// - A Dictionary is returned with each element serialized.
  /// - A Set is returned with each element serialized into an Array.
  /// - A Tuple is returned with each element serialized into an Array.
  /// - A Struct is returned with properties serialized into a Dictionary.
  /// - A Class is returned with properties serialized into a Dictionary.
  ///
  /// Null and any unhandled object will be ignored.
  ///
  /// To adjust or provide a value, update `jsonObject(willSerializeProperty:,value:)`.
  ///
  /// - Parameter object: Object to be seralized.
  /// - Returns: A JSON serialized object.
  fileprivate func _jsonObject(object: Any) -> AnyObject? {
    // unwrap any optional
    let object = SwiftCollection.unwrap(any: object)
    if object is NSNull { return nil }
    
    // handle strings and numbers
    switch object {
    case _ as NSString: return object as AnyObject?
    case _ as NSNumber: return object as AnyObject?
    case _ as Date: return (object as! Date).timeIntervalSince1970 as AnyObject?
    case _ as SCJsonCollectionProtocol: return _jsonCollection(collection: object as! SCJsonCollectionProtocol) as AnyObject?
    default: break
    }
    
    // reflect this object
    let mirror = Mirror(reflecting: object)
    
    // handle certain mirror types
    if let displayStyle = mirror.displayStyle {
      switch displayStyle {
      case .tuple: return _jsonTuple(object: object) as AnyObject
      case .enum: return object as AnyObject?
      default: break
      }
    }
    
    // exit if the object has no children
    if mirror.children.count == 0 {
      return nil
    }
    
    // otherwise, add the children to a dictionary
    var json: SwiftCollection.JsonDictionary = [:]

    // handle saving of key and value pairs to the json dictionary
    let willSerializeProperty = { (label: String, value: Any) in
      let (newLabel, newValue) = self.jsonObject(willSerializeProperty: label, value: value)
      guard newValue != nil && (newValue is NSString || newValue is NSNumber || newValue is NSArray || newValue is NSDictionary) else { return }
      json[newLabel] = newValue as AnyObject
    }
    
    for case let (label?, value) in mirror.children {
      // unwrap optional values
      let value = SwiftCollection.unwrap(any: value)

      // process this value
      switch value {
      case let theValue as NSString:
        // store this string value
        willSerializeProperty(label, theValue)
      case let theValue as NSNumber:
        // store this numeric value
        willSerializeProperty(label, theValue)
      case let theValue as Date:
        // store this date
        willSerializeProperty(label, theValue.timeIntervalSince1970)
      case _ as NSArray:
        // store this array
        if let arrayValue = _jsonArray(array: value as! NSArray) {
          willSerializeProperty(label, arrayValue)
        }
      case _ as NSDictionary:
        // store this dictionary
        if let dictValue = _jsonDictionary(dict: value as! NSDictionary) {
          willSerializeProperty(label, dictValue)
        }
      case _ as NSSet:
        // store this set as an array
        if let arrayValue = _jsonArray(array: ((value as! NSSet).allObjects) as NSArray) {
          willSerializeProperty(label, arrayValue)
        }
      case _ as NSNull:
        willSerializeProperty(label, value)
      default:
        // handle objects conforming to this class
        if let value = value as? SCJsonObject {
          if let theValue = value.jsonObject() {
            willSerializeProperty(label, theValue)
            continue
          }
        }
        
        // otherwise reflect further on this value
        // includes: tuple, enum, struct, class, etc.
        if let theValue = _jsonObject(object: value) {
          willSerializeProperty(label, theValue)
        }
      }
    }
    
    return json as AnyObject?
  }
  
  /// Subclasses can modify the property for the serialized JSON object.  This function is called as
  /// a property is being processed.
  ///
  /// To prevent a property from being serialized, a `newValue` of `nil` should be returned.
  ///
  /// - Parameters:
  ///   - label: Optional label for property.
  ///   - value: Value for property.
  /// - Returns: `newLabel` is the original or replacement label, `newValue` is the original,
  ///            replacement value, or `nil`.
  open func jsonObject(willSerializeProperty label: String, value: Any) -> (newLabel: String, newValue : Any?) {
    return (label, value)
  }

  /// Returns a foundation object that can be used to serialize JSON.  Must meet required
  /// JSON properties.
  ///
  /// By default, `Mirror` is used to reflect on an object's properties and serialize them as a
  /// JSON object.
  ///
  /// To adjust the label and/or value for when serializing a property, subclasses can override
  /// `jsonObject(willSerializeProperty:value)`.
  ///
  /// See [JSONSerialization](apple-reference-documentation://hsVFr-345J) for more information.
  ///
  /// - Returns: A valid JSON object.
  open func jsonObject() -> AnyObject? {
    let json = _jsonObject(object: self)
    return json
  }
  
  /// Returns a JSON serialized string for this object.  The `jsonObject` is used for
  /// serialization.
  ///
  /// - Parameter options: JSON output options.  Default is `prettyPrinted`.  Pass `[]` for no
  ///   options.
  /// - Returns: String representation of the `jsonObject`.
  /// - Throws: `invalidJson` if the JSON object could not be serialized.
  open func jsonString(options: JSONSerialization.WritingOptions = .prettyPrinted) throws -> String {
    let json = jsonObject() as Any
    guard JSONSerialization.isValidJSONObject(json) else { throw SwiftCollection.Errors.invalidJson }
    let data = try JSONSerialization.data(withJSONObject: json, options: options)
    guard let str = String(data: data, encoding: .utf8) else { return "{}" }
    return str
  }
  
  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Save
   * -----------------------------------------------------------------------------------------------
   */

  fileprivate static let storageKeyRoot = "\(SwiftCollection.bundleId).SCJsonObject"

  /// Returns key to be used when reading or writing a JSON serialized object to persistent storage.
  ///
  /// The name of this class is returned by default.
  ///
  /// - Returns: A key.
  open func storageKey() -> String {
    let key = String(describing: type(of: self))
    return key
  }
  
  /// Returns a key path to store this object.
  ///
  /// - Returns: A key path.
  /// - Throws: `missingstorageKey` if there is no key to store the serialized object.  See `storageKey()`.
  fileprivate func storageKeyPath() throws -> String {
    // get the key
    let key = storageKey()
    guard key.characters.count > 0 else { throw SwiftCollection.Errors.missingStorageKey }
    
    // return the key with this framework's bundle id
    return "\(SCJsonObject.storageKeyRoot).\(key)"
  }

  /// Saves this object as a JSON serialized string to the specified persistent storage.
  ///
  /// - Parameters:
  ///   - storage: Persistent storage to be used.
  ///   - completion: Called after the object has been saved.
  /// - Throws:
  ///   - `missingstorageKey` if there is no key to retrieve the serialized object.  See `storageKey()`.
  ///   - `invalidJson` if the JSON object is not an `Array` or `Dictionary`.
  final public func save(jsonStorage storage: SwiftCollection.Storage, completion: ((_ success: Bool) -> Void)?) throws {
    var success = false
    
    // get the key
    let keyPath = try storageKeyPath()
    
    // get the JSON serialized string
    let json = try jsonString(options: [])

    // save to storage
    switch storage {
    case .userDefaults:
      let ud = UserDefaults.standard
      ud.set(json, forKey: keyPath)
      ud.synchronize()
      success = true
    }

    // done
    if let completion = completion {
      DispatchQueue.main.async {
        completion(success)
      }
    }
  }
  
  /// Removes saved object from persistent storage.
  ///
  /// - Parameters:
  ///   - storage: Persistent storage to be used.
  ///   - completion: Called after the object has been removed.
  /// - Throws: `missingstorageKey` if there is no key to retrieve the serialized object.  See `storageKey()`.
  final public func remove(jsonStorage storage: SwiftCollection.Storage, completion: ((_ success: Bool) -> Void)?) throws {
    var success = false
    
    // get the key
    let keyPath = try storageKeyPath()
    
    // remove from storage
    switch storage {
    case .userDefaults:
      let ud = UserDefaults.standard
      ud.removeObject(forKey: keyPath)
      ud.synchronize()
      success = true
    }
    
    // done
    if let completion = completion {
      DispatchQueue.main.async {
        completion(success)
      }
    }
  }

  /*
   * -----------------------------------------------------------------------------------------------
   * MARK: - Load
   * -----------------------------------------------------------------------------------------------
   */
  
  /// Loads this object from a JSON serialized string from the specified persistent storage.
  ///
  /// - Parameters:
  ///   - storage: Persistent storage to be used.
  ///   - completion: Called after the object has been loaded.
  /// - Throws: `invalidJson` if the JSON object is not an `Array` or `Dictionary`.
  final public func load(jsonStorage storage: SwiftCollection.Storage, completion: ((_ success: Bool, _ json: AnyObject?) -> Void)?) throws {
    // get the key
    let keyPath = try storageKeyPath()
    var success = false
    
    // load serialized JSON from storage
    let str: String?
    switch storage {
    case .userDefaults:
      let ud = UserDefaults.standard
      str = ud.string(forKey: keyPath)
    }
    
    // get JSON object
    var json: AnyObject?
    if let str = str {
      json = try load(jsonString: str)
      success = json != nil
    }
    
    // done
    if let completion = completion {
      DispatchQueue.main.async {
        completion(success, json)
      }
    }
  }

  /// Loads this object from a JSON serialized string.
  ///
  /// - Parameter json: JSON serialized string to be loaded.
  /// - Returns: JSON object.
  /// - Throws: `invalidJson` if the JSON object is not an Array or Dictionary.
  open func load(jsonString json: String) throws -> AnyObject? {
    if let data = json.data(using: .utf8) {
      let obj = try JSONSerialization.jsonObject(with: data) as AnyObject
      return try load(jsonObject: obj)
    }
    return nil
  }
  
  /// Loads data from this JSON object.
  ///
  /// * When JSON is an array, `load(arrayItem, atIndex, json)` is called for each item in the
  /// array.
  ///
  /// * When JSON is a dictionary, properties for this object will be processed using reflection.
  /// `load(propertyWithName, currentValue, json)` is called for each property of this object.
  ///
  /// Subclasses of `SCJsonObject` should add logic in the appropriate function to populate this 
  /// object.
  ///
  /// - Parameter json: JSON object to be loaded.
  /// - Returns: JSON object.
  /// - Throws: `invalidJson` if the JSON object is not an Array or Dictionary.
  open func load(jsonObject json: AnyObject) throws -> AnyObject? {
    if json is [AnyObject] || json is ArraySlice<AnyObject> {
      // get array
      var array: [AnyObject]?
      switch json {
      case let anArray as [AnyObject]: array = anArray
      case let anArraySlice as ArraySlice<AnyObject>: array = Array(anArraySlice)
      default: return json
      }
      // process each array item
      for (i, item) in array!.enumerated() {
        load(arrayItem: item, atIndex: i, json: json)
      }
    } else if json is [String: AnyObject] {
      // get dictionary
      let dict = json as! [String: AnyObject]
      
      // get mirror for reflection
      let mirror = Mirror(reflecting: self)
      
      // check that we have children to process
      guard mirror.children.count > 0 else { return json }
      
      // process each property
      for case let (label?, value) in mirror.children {
        let potentialValue = SwiftCollection.unwrap(any: dict[label] ?? NSNull())
        load(propertyWithName: label, currentValue: value, potentialValue: potentialValue, json: json)
      }
    } else {
      throw SwiftCollection.Errors.invalidJson
    }
    
    return json
  }
  
  /// Subclasses of `SCJsonObject` should add logic in this function to populate the properties of 
  /// this object from a dictionary.
  ///
  /// - Parameters:
  ///   - name: Name of property.
  ///   - currentValue: Current value of property.
  ///   - potentialValue: Possible value from JSON object.
  ///   - json: Complete JSON object with values to be loaded.
  open func load(propertyWithName name: String, currentValue: Any, potentialValue: Any, json: AnyObject) {
    // nothing to do
  }
  
  /// Subclasses of `SCJsonObject` should add logic in this function to populate this object from
  /// an array.
  ///
  /// - Parameters:
  ///   - item: Item in array.
  ///   - i: Index of item in array.
  ///   - json: Complete JSON object with values to be loaded.
  open func load(arrayItem item: AnyObject, atIndex i: Int, json: AnyObject) {
    // nothing to do
  }

}
