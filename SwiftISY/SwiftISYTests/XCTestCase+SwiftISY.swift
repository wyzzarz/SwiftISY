//
//  XCTestCase+ISY.swift
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

extension XCTestCase {

  func testResourceUrl(forResource name: String, withExtension ext: String?) -> URL? {
    let bundle = Bundle(for: type(of: self))
    guard let testBundleUrl = bundle.url(forResource: "SwiftISYTests", withExtension: "bundle") else { return nil }
    guard let testBundle = Bundle(url: testBundleUrl) else { return nil }
    return testBundle.url(forResource: name, withExtension: ext)
  }

  func testResourceData(forResource name: String, withExtension ext: String?) -> Data? {
    guard let url = testResourceUrl(forResource: name, withExtension: ext) else { return nil }
    return try? Data(contentsOf: url)
  }

  func testResourceJson(forResource name: String, withExtension ext: String?) -> AnyObject? {
    guard let data = testResourceData(forResource: name, withExtension: ext) else { return nil }
    return try? JSONSerialization.jsonObject(with: data, options: []) as AnyObject
  }

}
