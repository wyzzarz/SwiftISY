//
//  SwiftCollectionTests+Persistence.swift
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

import XCTest
@testable import SwiftCollection

class SwiftCollectionPersistenceTests: XCTestCase {

  typealias KeyValue = (key: String, value: Any?, jsonValue: Any?)

  enum AnotherEnum {
    case a
    case b
    case c
  }
  
  enum AnotherEnumString: String {
    case a
    case b
    case c
  }

  enum AnotherEnumNumber: Float {
    case a
    case b
    case c
  }

  struct AnotherOptionSet: OptionSet {
    let rawValue: Int
    static let first      = AnotherOptionSet(rawValue: 1 << 0)
    static let second     = AnotherOptionSet(rawValue: 1 << 1)
    static let third      = AnotherOptionSet(rawValue: 1 << 2)
    static let fourth     = AnotherOptionSet(rawValue: 1 << 3)
  }

  struct AnotherStruct {
    var a: String?
    var b: String?
    init(defaults: Bool = true) {
      if defaults {
        a = "1"
        b = "2"
      }
    }
    init(a: String?, b: String?) {
      self.a = a
      self.b = b
    }
    init(json: [String: Any]) {
      a = json["a"] as? String
      b = json["b"] as? String
    }
  }

  class AnotherClass {
    var c: Int?
    var d: String?
    var anotherStruct: AnotherStruct?
    init(defaults: Bool = true) {
      if defaults {
        c = 3
        d = "4"
        anotherStruct = AnotherStruct()
      }
    }
    init(c: Int?, d: String?, anotherStruct: [String: Any]?) {
      self.c = c
      self.d = d
      self.anotherStruct = anotherStruct != nil ? AnotherStruct(json: anotherStruct!) : nil
    }
  }

  struct KeyValues {
    
    static let str: KeyValue = ("str", "string", nil)
    static let dbl: KeyValue = ("dbl", Double(11.1), nil)
    static let int: KeyValue = ("int", Int(88), nil)
    static let num: KeyValue = ("num", NSNumber(value: 99), nil)
    static let bool: KeyValue = ("bool", true, nil)
    static let date: KeyValue = ("date", Date(timeIntervalSince1970: 123456789), TimeInterval(123456789))
    static let arr: KeyValue = ("arr", ["a", "b", "c"], nil)
    static let dict: KeyValue = ("dict", ["A": "a", "B": Double(10.1), "C": Int(99), "D": true, "E": false], nil)
    static let set: KeyValue = ("set", Set(["d", "e", "f"]), nil)
    static let tuple: KeyValue = ("tuple", ("g", "h", "i"), ["g", "h", "i"])
    static let null: KeyValue = ("null", NSNull(), nil)
    static let anotherEnum: KeyValue = ("anotherEnum", AnotherEnum.b, nil)
    static let anotherEnumString: KeyValue = ("anotherEnumString", AnotherEnumString.b, AnotherEnumString.b.rawValue)
    static let anotherEnumNumber: KeyValue = ("anotherEnumNumber", AnotherEnumNumber.b, AnotherEnumNumber.b.rawValue)
    static let anotherOptionSet: KeyValue = ("anotherOptionSet", AnotherOptionSet.first.union(.third), ["rawValue": 5])
    static let anotherStruct: KeyValue = ("anotherStruct", nil, ["a": "1", "b": "2"])
    static let anotherClass: KeyValue = ("anotherClass", nil, ["c": 3, "d": "4", "anotherStruct": ["a": "1", "b": "2"]])
    
  }

  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
}

/*
 * -----------------------------------------------------------------------------------------------
 * MARK: - Struct With Various Objects
 * -----------------------------------------------------------------------------------------------
 */

extension SwiftCollectionPersistenceTests {
  
  struct JsonStruct: SCJsonProtocol {
    
    var str: String?
    var dbl: Double?
    var int: Int?
    var num: NSNumber?
    var bool: Bool?
    var date: Date?
    var arr: [String]?
    var dict: [String: Any]?
    var set: Set<String>?
    var tuple: (String, String, String)?
    var null: Any?
    var anotherEnum: AnotherEnum?
    var anotherEnumString: AnotherEnumString?
    var anotherEnumNumber: AnotherEnumNumber?
    var anotherOptionSet: AnotherOptionSet?
    var anotherStruct: AnotherStruct?
    var anotherClass: AnotherClass?
    
    init() {
    }
    
    init(defaults: Bool = false) {
      if defaults {
        str = KeyValues.str.value as? String
        dbl = KeyValues.dbl.value as? Double
        int = KeyValues.int.value as? Int
        num = KeyValues.num.value as? NSNumber
        bool = KeyValues.bool.value as? Bool
        date = KeyValues.date.value as? Date
        arr = KeyValues.arr.value as? [String]
        dict = KeyValues.dict.value as? [String: Any]
        set = KeyValues.set.value as? Set<String>
        tuple = KeyValues.tuple.value as? (String, String, String)
        null = KeyValues.null.value as? NSNull
        anotherEnum = KeyValues.anotherEnum.value as? AnotherEnum
        anotherEnumString = KeyValues.anotherEnumString.value as? AnotherEnumString
        anotherEnumNumber = KeyValues.anotherEnumNumber.value as? AnotherEnumNumber
        anotherOptionSet = KeyValues.anotherOptionSet.value as? AnotherOptionSet
        anotherStruct = AnotherStruct()
        anotherClass = AnotherClass()
      }
    }
    
    func jsonObject(willSerializeProperty label: String, value: Any) -> (newLabel: String, newValue: AnyObject?) {
      switch label {
      case KeyValues.anotherEnumString.key:
        // reflection cannot be used to get the `rawValue` of an enum; special handling is required.
        return (label, anotherEnumString?.rawValue as AnyObject?)
      case KeyValues.anotherEnumNumber.key:
        // reflection cannot be used to get the `rawValue` of an enum; special handling is required.
        if let rawValue = anotherEnumNumber?.rawValue {
          return (label, NSNumber(value: rawValue))
        } else {
          return (label, nil)
        }
      default: break
      }
      return (label, value as AnyObject)
    }
    
    func jsonKey() -> String {
      return "JsonStructABC"
    }
    
    public mutating func load(propertyWithName name: String, currentValue: Any, potentialValue: Any, json: AnyObject) {
      switch name {
      case KeyValues.str.key: str = potentialValue as? String
      case KeyValues.dbl.key: dbl = (potentialValue as? NSNumber)?.doubleValue
      case KeyValues.int.key: int = (potentialValue as? NSNumber)?.intValue
      case KeyValues.num.key: num = potentialValue as? NSNumber
      case KeyValues.bool.key: bool = (potentialValue as? NSNumber)?.boolValue
      case KeyValues.date.key: date = potentialValue as? Date
      case KeyValues.arr.key: arr = potentialValue as? [String]
      case KeyValues.dict.key: dict = potentialValue as? [String: Any]
      case KeyValues.set.key: set = Set(potentialValue as! [String])
      case KeyValues.tuple.key: if let array = potentialValue as? [String] { tuple = (array[0], array[1], array[2]) }
      case KeyValues.anotherEnumString.key: anotherEnumString = AnotherEnumString(rawValue: potentialValue as! String)
      case KeyValues.anotherEnumNumber.key: anotherEnumNumber = AnotherEnumNumber(rawValue: potentialValue as! Float)
      case KeyValues.anotherOptionSet.key: if let dict = potentialValue as? [String: Int] { anotherOptionSet = AnotherOptionSet(rawValue: dict["rawValue"] ?? 0) }
      case KeyValues.anotherStruct.key: if let dict = potentialValue as? [String: String] { anotherStruct = AnotherStruct(a: dict["a"], b: dict["b"]) }
      case KeyValues.anotherClass.key: if let dict = potentialValue as? [String: Any] { anotherClass = AnotherClass(c: dict["c"] as? Int, d: dict["d"] as? String, anotherStruct: dict["anotherStruct"] as? [String: Any]) }
      default: break
      }
    }

  }
  
  func testJsonStruct() {
    // get struct to test
    let obj = JsonStruct(defaults: true)
    
    // get JSON object
    guard let json = obj.jsonObject() else { XCTAssert(false); return }
    
    // ensure JSON is a dictionary
    XCTAssertTrue(json is NSDictionary)
    
    // get dictionary and keys
    let dict = json as! [String: Any]
    let keys = Array(dict.keys)
    XCTAssertEqual(keys.count, 15)
    
    // test string
    XCTAssertTrue(keys.contains(KeyValues.str.key))
    XCTAssertEqual(dict[KeyValues.str.key] as? String, KeyValues.str.value as? String)
    
    // test double
    XCTAssertTrue(keys.contains(KeyValues.dbl.key))
    XCTAssertEqual(dict[KeyValues.dbl.key] as? Double, KeyValues.dbl.value as? Double)

    // test integer
    XCTAssertTrue(keys.contains(KeyValues.int.key))
    XCTAssertEqual(dict[KeyValues.int.key] as? Int, KeyValues.int.value as? Int)

    // test number
    XCTAssertTrue(keys.contains(KeyValues.num.key))
    XCTAssertEqual(dict[KeyValues.num.key] as? NSNumber, KeyValues.num.value as? NSNumber)

    // test bool
    XCTAssertTrue(keys.contains(KeyValues.bool.key))
    XCTAssertEqual(dict[KeyValues.bool.key] as? Bool, KeyValues.bool.value as? Bool)

    // test date
    XCTAssertTrue(keys.contains(KeyValues.date.key))
    XCTAssertEqual(dict[KeyValues.date.key] as? TimeInterval, KeyValues.date.jsonValue as? TimeInterval)

    // test array
    XCTAssertTrue(keys.contains(KeyValues.arr.key))
    XCTAssertEqual(dict[KeyValues.arr.key] as! [String], KeyValues.arr.value as! [String])
    
    // test dictionary
    XCTAssertTrue(keys.contains(KeyValues.dict.key))
    XCTAssertTrue((dict[KeyValues.dict.key] as! NSDictionary).isEqual(to: KeyValues.dict.value as! [AnyHashable: Any]))
    
    // test set
    XCTAssertTrue(keys.contains(KeyValues.set.key))
    XCTAssertTrue((dict[KeyValues.set.key] as! NSArray).isEqual(to: Array(KeyValues.set.value as! Set<String>)))
    
    // test tuple (as array)
    XCTAssertTrue(keys.contains(KeyValues.tuple.key))
    XCTAssertEqual(dict[KeyValues.tuple.key] as! [String], KeyValues.tuple.jsonValue as! [String])
    
    // test null
    XCTAssertFalse(keys.contains(KeyValues.null.key))
    
    // test enum
    XCTAssertFalse(keys.contains(KeyValues.anotherEnum.key))
    
    // test enum (string)
    XCTAssertTrue(keys.contains(KeyValues.anotherEnumString.key))
    XCTAssertEqual(dict[KeyValues.anotherEnumString.key] as? String, KeyValues.anotherEnumString.jsonValue as? String)
    
    // test enum (number)
    XCTAssertTrue(keys.contains(KeyValues.anotherEnumNumber.key))
    XCTAssertEqual(dict[KeyValues.anotherEnumNumber.key] as? Float, KeyValues.anotherEnumNumber.jsonValue as? Float)
    
    // test option set
    XCTAssertTrue(keys.contains(KeyValues.anotherOptionSet.key))
    XCTAssertTrue((dict[KeyValues.anotherOptionSet.key] as! NSDictionary).isEqual(to: KeyValues.anotherOptionSet.jsonValue as! [String: Any]))
    
    // test struct
    XCTAssertTrue(keys.contains(KeyValues.anotherStruct.key))
    XCTAssertTrue((dict[KeyValues.anotherStruct.key] as! NSDictionary).isEqual(to: KeyValues.anotherStruct.jsonValue as! [AnyHashable: Any]))
    
    // test class
    XCTAssertTrue(keys.contains(KeyValues.anotherClass.key))
    XCTAssertTrue((dict[KeyValues.anotherClass.key] as! NSDictionary).isEqual(to: KeyValues.anotherClass.jsonValue as! [AnyHashable: Any]))
  }
  
  func testKeys() {
    XCTAssertEqual(JsonStruct().jsonKey(), "JsonStructABC")
    XCTAssertEqual(Struct1().jsonKey(), "Struct1")
    XCTAssertEqual(Class1().jsonKey(), "Class1")
  }
  
  func testSaveJsonStruct() {
    // get struct to test
    let obj = JsonStruct(defaults: true)
    
    // create expectations
    let se = expectation(description: "Save Failed.")
    let le = self.expectation(description: "Load Failed.")
    
    // load object
    let load = {
      do {
        var loaded = JsonStruct()
        try loaded.load(jsonStorage: .userDefaults, completion: { (success, value) in
          le.fulfill()
          XCTAssertTrue(success)
          XCTAssertTrue(value is NSDictionary)
          XCTAssertEqual(loaded.str, KeyValues.str.value as? String)
          XCTAssertEqual(loaded.dbl, KeyValues.dbl.value as? Double)
          XCTAssertEqual(loaded.int, KeyValues.int.value as? Int)
          XCTAssertEqual(loaded.num, KeyValues.num.value as? NSNumber)
          XCTAssertEqual(loaded.arr!, KeyValues.arr.value as! [String])
          XCTAssertNotNil(loaded.dict)
          XCTAssertEqual(Set(loaded.dict!.keys), Set((KeyValues.dict.value as! [String: Any]).keys))
          XCTAssertEqual(loaded.set, KeyValues.set.value as? Set<String>)
          XCTAssertEqual(loaded.tuple?.0, (KeyValues.tuple.value as! (String, String, String)).0)
          XCTAssertEqual(loaded.tuple?.1, (KeyValues.tuple.value as! (String, String, String)).1)
          XCTAssertEqual(loaded.tuple?.2, (KeyValues.tuple.value as! (String, String, String)).2)
          XCTAssertEqual(loaded.anotherEnumString, KeyValues.anotherEnumString.value as? AnotherEnumString)
          XCTAssertEqual(loaded.anotherEnumNumber, KeyValues.anotherEnumNumber.value as? AnotherEnumNumber)
          XCTAssertEqual(loaded.anotherOptionSet, KeyValues.anotherOptionSet.value as? AnotherOptionSet)
          XCTAssertNotNil(loaded.anotherStruct)
          XCTAssertEqual(loaded.anotherStruct?.a, "1")
          XCTAssertEqual(loaded.anotherStruct?.b, "2")
          XCTAssertNotNil(loaded.anotherClass)
          XCTAssertEqual(loaded.anotherClass?.c, 3)
          XCTAssertEqual(loaded.anotherClass?.d, "4")
          XCTAssertNotNil(loaded.anotherClass?.anotherStruct)
          XCTAssertEqual(loaded.anotherClass?.anotherStruct?.a, "1")
          XCTAssertEqual(loaded.anotherClass?.anotherStruct?.b, "2")
        })
      } catch {
        XCTFail()
      }
    }
    
    // save object
    do {
      try obj.save(jsonStorage: .userDefaults) { (success) in
        se.fulfill()
        XCTAssertTrue(success)
        if (success) {
          load()
        }
      }
    } catch {
      XCTFail()
    }
    
    // wait for save and load
    waitForExpectations(timeout: 60) { (error) in
      if let error = error {
        XCTFail("Save Failed: \(error.localizedDescription)")
      }
    }
  }
  
}

/*
 * -----------------------------------------------------------------------------------------------
 * MARK: - Nested Objects
 * -----------------------------------------------------------------------------------------------
 */

extension SwiftCollectionPersistenceTests {
  
  struct Struct1: SCJsonProtocol {
    
    var a: Int?
    var b: Int?
    
    init() {
    }
    
    init(defaults: Bool = false) {
      if defaults {
        a = 1
      }
    }
    
    public mutating func load(propertyWithName name: String, currentValue: Any, potentialValue: Any, json: AnyObject) {
      guard !(potentialValue is NSNull) else { return }
      switch name {
      case "a": a = Int(potentialValue as! NSNumber)
      case "b": b = Int(potentialValue as! NSNumber)
      default: break
      }
    }
    
  }
  
  class Class1: SCJsonProtocol {
    
    var c: Int?
    var d: Int?
    var struct1: Struct1?
    
    required init() {
    }
    
    init(defaults: Bool = false) {
      if defaults {
        c = 3
        struct1 = Struct1(defaults: defaults)
      }
    }
    
    public func load(propertyWithName name: String, currentValue: Any, potentialValue: Any, json: AnyObject) {
      guard !(potentialValue is NSNull) else { return }
      switch name {
      case "c": c = Int(potentialValue as! NSNumber)
      case "d": d = Int(potentialValue as! NSNumber)
      case "struct1":
        struct1 = Struct1()
        _ = try! struct1!.load(jsonObject: potentialValue as AnyObject)
      default: break
      }
    }
    
  }
  
  func testJsonObjects() {
    // get object to test
    let obj = Class1(defaults: true)
    
    // get JSON object
    guard let json = obj.jsonObject() else { XCTAssert(false); return }
    
    // ensure JSON is a dictionary
    XCTAssertTrue(json is NSDictionary)
    
    // get dictionary and keys
    let dict = json as! [String: Any]
    let keys = Array(dict.keys)
    XCTAssertEqual(keys.count, 2)
    
    // check keys
    XCTAssertTrue(Set(keys) == Set(["c", "struct1"]))
    XCTAssertEqual(dict["c"] as! Int, 3)
    XCTAssertNil(dict["d"])
    
    // check serialized Struct1
    let struct1 = dict["struct1"]
    XCTAssertNotNil(struct1)
    XCTAssertTrue(struct1 is NSDictionary)
    
    // verify contents of Struct1
    let dict1 = struct1 as! [String: Int]
    XCTAssertEqual(dict1["a"], 1)
    XCTAssertNil(dict1["b"])
  }
  
  func testJsonObjectsSaveAndLoad() {
    // get object to test
    let obj = Class1(defaults: true)
    
    // create expectations
    let se = expectation(description: "Save Failed.")
    let le = self.expectation(description: "Load Failed.")
    
    // load object
    let load = {
      do {
        var loaded = Class1()
        try loaded.load(jsonStorage: .userDefaults, completion: { (success, value) in
          le.fulfill()
          XCTAssertTrue(success)
          XCTAssertTrue(value is NSDictionary)
          XCTAssertEqual(loaded.c, 3)
          XCTAssertNil(loaded.d)
          XCTAssertNotNil(loaded.struct1)
          XCTAssertEqual(loaded.struct1!.a, 1)
        })
      } catch {
        XCTFail()
      }
    }
    
    // save object
    do {
      try obj.save(jsonStorage: .userDefaults) { (success) in
        se.fulfill()
        XCTAssertTrue(success)
        if (success) {
          load()
        }
      }
    } catch {
      XCTFail()
    }
    
    // wait for save and load
    waitForExpectations(timeout: 60) { (error) in
      if let error = error {
        XCTFail("Save Failed: \(error.localizedDescription)")
      }
    }
    
  }

}

/*
 * -----------------------------------------------------------------------------------------------
 * MARK: - Collection
 * -----------------------------------------------------------------------------------------------
 */

fileprivate struct SimpleCollectionIndex<Element: Hashable>: Comparable {
  
  fileprivate let index: Int
  
  fileprivate init(_ index: Int) {
    self.index = index
  }
  
  public static func == (lhs: SimpleCollectionIndex, rhs: SimpleCollectionIndex) -> Bool {
    return lhs.index == rhs.index
  }
  
  public static func < (lhs: SimpleCollectionIndex, rhs: SimpleCollectionIndex) -> Bool {
    return lhs.index < rhs.index
  }
  
}

fileprivate class SimpleCollection<Element: Hashable>: Collection {
  
  public typealias Iterator = AnyIterator<Element>
  typealias Index = SimpleCollectionIndex<Element>

  var elements: [Element] = []
  
  required init() {
  }
  
  func add(element: Element) {
    elements.append(element)
  }
  
  func makeIterator() -> Iterator {
    var iterator = elements.makeIterator()
    return AnyIterator { return iterator.next() }
  }
  
  var startIndex: Index {
    return SimpleCollectionIndex(elements.startIndex)
  }

  var endIndex: Index {
    return SimpleCollectionIndex(elements.endIndex)
  }

  public func index(after i: Index) -> Index {
    return Index(elements.index(after: i.index))
  }

  public subscript (position: Index) -> Iterator.Element {
    return elements[position.index]
  }

}

extension SimpleCollection: SCJsonProtocol {
  
}

fileprivate class PersistenceCollection<Element: NSString>: SimpleCollection<Element>, SCJsonCollectionProtocol {
  
  public func jsonCollectionElements() -> [Any] {
    var elements: [Element] = []
    for (_, element) in self.enumerated() {
      elements.append(element)
    }
    return elements
  }
  
}

extension SwiftCollectionPersistenceTests {
  
  func testCollection() {
    // setup collection
    let sc = PersistenceCollection()
    sc.add(element: "A")
    sc.add(element: "B")
    sc.add(element: "C")

    // get JSON object
    guard let json = sc.jsonObject() else { XCTAssert(false); return }
    
    // ensure JSON is an array
    XCTAssertTrue(json is NSArray)
    
    // validate elements
    let array = json as! [String]
    XCTAssertEqual(array.first, "A")
    XCTAssertEqual(array[1], "B")
    XCTAssertEqual(array.last, "C")
  }
  
}
