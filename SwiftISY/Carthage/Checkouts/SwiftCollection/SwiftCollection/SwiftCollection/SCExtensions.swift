//
//  SCExtensions.swift
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

extension UInt64 {
  
  /// Generates a random integer within the upper and lower bounds.
  ///
  /// - Parameters:
  ///   - upper: Upper bounds for the randomizer.  Defaults to max.
  ///   - lower: Lower bounds for the randomizer.  Defaults to min.
  /// - Returns: A random integer.
  public static func random(upper: UInt64 = max, lower: UInt64 = min) -> UInt64 {
    // calculate total random length
    let length: UInt64 = upper - lower
    // if the length is less than what the randomizer returns, then just make one call
    if length < UInt64(UInt32.max) { return UInt64(arc4random_uniform(UInt32(length))) + lower }
    // otherwise get a random number as the sum of two randomizer calls
    let remainder = UInt64(length - UInt64(UInt32.max)) >> 32
    let random1 = UInt64(arc4random_uniform(UInt32.max))
    let random2 = UInt64(arc4random_uniform(UInt32(remainder)))
    return random1 + random2 + lower
  }
  
}

extension UInt32 {
  
  /// Generates a random integer within the upper and lower bounds.
  ///
  /// - Parameters:
  ///   - upper: Upper bounds for the randomizer.  Defaults to max.
  ///   - lower: Lower bounds for the randomizer.  Defaults to min.
  /// - Returns: A random integer.
  public static func random(upper: UInt32 = max, lower: UInt32 = min) -> UInt32 {
    return arc4random_uniform(upper - lower) + lower
  }
  
}

extension String {
  
  /// Enlarges a string by padding it with a character.  If the string is equal to or greater than
  /// the specified length, then the string is unchanged.
  ///
  /// - Parameters:
  ///   - length: Length to pad the string to.
  ///   - c: Character to be inserted on the left.
  /// - Returns: A left padded string.  Or the original string if padding is unecessary.
  public func padding(toLength length: Int, withLeftPad c: Character) -> String {
    let diff = length - characters.count
    if diff <= 0 { return self }
    return String(repeating: String(c), count: diff) + self
  }
  
}
