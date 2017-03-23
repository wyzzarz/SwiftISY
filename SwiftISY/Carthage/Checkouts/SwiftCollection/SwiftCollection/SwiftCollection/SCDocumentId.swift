//
//  SCDocumentId.swift
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

extension SwiftCollection {
  
  /// Primary key to be used for documents.
  public typealias Id = UInt
  
}

extension SwiftCollection.Id {
  
  /// Returns `true` if the current device has a 64-bit CPU; `false` otherwise.
  public static let is64Bit = MemoryLayout<UInt>.size == MemoryLayout<UInt64>.size
  
  /// Generates a random primary key within the upper and lower bounds.
  ///
  /// - Parameters:
  ///   - upper: Upper bounds for the randomizer.  Defaults to max.
  ///   - lower: Lower bounds for the randomizer.  Defaults to 1.
  /// - Returns: A random id.
  public static func random(upper: SwiftCollection.Id = max, lower: SwiftCollection.Id = 1) -> SwiftCollection.Id {
    if SwiftCollection.Id.is64Bit { return UInt(UInt64.random(upper: UInt64(upper), lower: UInt64(lower))) }
    return UInt(UInt32.random(upper: UInt32(upper), lower: UInt32(lower)))
  }
  
  /// Returns the id formatted as a hexadecimal string.
  ///
  /// - Parameters:
  ///   - numBytes: Number of bytes to group by.
  ///   - c: Character to separate each group of bytes.
  /// - Returns: A hexidecimal string.
  public func toHexString(groupEvery numBytes: Int = 0, separator c: Character = "-") -> String {
    let numCharacterBytes = numBytes * 2
    var hex = String(self, radix: 16, uppercase: true).padding(toLength: MemoryLayout<SwiftCollection.Id>.stride * 2, withLeftPad: "0")
    if numCharacterBytes > 0 && hex.characters.count > numCharacterBytes {
      var i = hex.index(hex.startIndex, offsetBy: numCharacterBytes)
      while true {
        hex.insert(c, at: i)
        if hex.distance(from: i, to: hex.endIndex) <= numCharacterBytes + 1 { break }
        i = hex.index(i, offsetBy: numCharacterBytes + 1)
      }
    }
    return hex
  }
  
}
