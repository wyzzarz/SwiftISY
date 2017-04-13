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

public class SwiftISYResponse: SCDocument, SwiftISYParserProtocol {
  
  /// Whether the command was successfuly executed.
  public var succeeded = false
  
  /// Status code for the command.
  public var status: SwiftISY.HttpStatusCodes?
  
  public required convenience init(elementName: String, attributes: [String: String]) {
    self.init()
    succeeded = attributes[SwiftISY.Attributes.succeeded] ?? "false" == "true"
  }
  
  public func update(elementName: String, attributes: [String : String], text: String = "") {
    switch elementName {
    case SwiftISY.Elements.status: status = SwiftISY.HttpStatusCodes(rawValue: Int(text) ?? 0)
    default: break
    }
  }
  
}
