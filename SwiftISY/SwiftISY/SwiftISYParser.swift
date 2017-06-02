//
//  SwiftISYParser.swift
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

///
/// Instances of `SwiftISYParser` parses the XML results returned by requests to ISY devices.
///
internal class SwiftISYParser: NSObject {
  
  // XML
  var parser: XMLParser
  var userInfo: SwiftISY.UserInfo
  var completion: ((_ objects: SwiftISYRequest.Objects) -> Void)?
  var texts: [String] = []
  var attributes: [[String: String]] = []
  var currentIndex: Int? { get { return texts.count > 0 && texts.count == attributes.count ? texts.count - 1 : nil } }

  // Objects
  var objects = SwiftISYRequest.Objects()
  
  // Group
  var isProcessingGroup = false
  var currentGroup: SwiftISYGroup?
  
  // Node
  var isProcessingNode = false
  var currentNode: SwiftISYNode?

  // Status
  var currentStatus: SwiftISYStatus?

  // Properties
  var isProcessingProperties = false
  
  // Response
  var isProcessingResponse = false
  var currentResponse: SwiftISYResponse?
  
  init(data: Data, userInfo: SwiftISY.UserInfo) {
    parser = XMLParser(data: data)
    self.userInfo = userInfo
    super.init()
    parser.delegate = self
  }
  
}

// -------------------------------------------------------------------------------------------------
// MARK: - XMLParser
// -------------------------------------------------------------------------------------------------

extension SwiftISYParser: XMLParserDelegate {

  func parse(completion: @escaping (_ objects: SwiftISYRequest.Objects) -> Void) -> SwiftISYParser {
    self.completion = completion
    parser.parse()
    return self
  }
  
  func parserDidEndDocument(_ parser: XMLParser) {
    if completion != nil { completion!(objects) }
  }

  func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributesDict: [String : String] = [:]) {
    // hold text for this element
    texts.append("")
    
    // hold attributes for this element
    attributes.append(attributesDict)
    
    // process this element
    if elementName == SwiftISY.Elements.group {
      // handle group
      currentGroup = SwiftISYGroup(elementName: elementName, attributes: attributesDict)
      objects.groups.append(currentGroup!)
      isProcessingGroup = true
    } else if elementName == SwiftISY.Elements.node {
      // handle node
      currentNode = SwiftISYNode(elementName: elementName, attributes: attributesDict)
      objects.nodes.append(currentNode!)
      isProcessingNode = true
    } else if elementName == SwiftISY.Elements.properties {
      // handle properties
      isProcessingProperties = true
    } else if isProcessingProperties && elementName == SwiftISY.Elements.property {
      // handle property
      if SwiftISYStatus.canHandle(elementName: elementName, attributes: attributesDict) {
        // handle status
        currentStatus = SwiftISYStatus(elementName: elementName, attributes: attributesDict)
      }
    } else if elementName == SwiftISY.Elements.restResponse {
      // handle rest response
      currentResponse = SwiftISYResponse(elementName: elementName, attributes: attributesDict)
      objects.responses.append(currentResponse!)
      isProcessingResponse = true
    }
  }

  func parser(_ parser: XMLParser, foundCharacters string: String) {
    // append text to the current element
    guard var text = texts.last else { return }
    guard let index = currentIndex else { return }
    text += string
    texts[index] = text
  }
  
  func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
    // remove text for this element
    let text = texts.removeLast()
    
    // remove attributes for this element
    let attributesDict = attributes.removeLast()
    
    // process this element including any text and attributes
    if elementName == SwiftISY.Elements.group {
      // process group
      currentGroup = nil
      isProcessingGroup = false
    } else if elementName == SwiftISY.Elements.node {
      // process node
      defer {
        currentNode = nil
        currentStatus = nil
        isProcessingNode = false
      }
      guard let node = currentNode else { return }
      guard let status = currentStatus else { return }
      status.address = node.address
      objects.statuses[node.address] = status
    } else if elementName == SwiftISY.Elements.restResponse {
      // process rest response
      currentResponse = nil
      isProcessingResponse = false
    } else if elementName == SwiftISY.Elements.properties {
      // process properties
      currentStatus = nil
      isProcessingProperties = false
    } else if isProcessingGroup {
      // handle group properties
      guard let group = currentGroup else { return }
      group.update(elementName: elementName, attributes: attributesDict, text: text)
    } else if isProcessingNode {
      // handle node properties
      if elementName == SwiftISY.Elements.property && SwiftISYStatus.canHandle(elementName: elementName, attributes: attributesDict) {
        currentStatus = SwiftISYStatus(elementName: elementName, attributes: attributesDict)
      } else {
        guard let node = currentNode else { return }
        node.update(elementName: elementName, attributes: attributesDict, text: text)
      }
    } else if isProcessingProperties {
      // handle property
      if elementName == SwiftISY.Elements.property && SwiftISYStatus.canHandle(elementName: elementName, attributes: attributesDict) {
        if let status = currentStatus {
          if let address = userInfo[SwiftISY.Elements.address] {
            status.address = address
            objects.statuses[address] = status
          }
        }
      }
    } else if isProcessingResponse {
      // handle rest response
      guard let response = currentResponse else { return }
      response.update(elementName: elementName, attributes: attributesDict, text: text)
    }
  }
  
}

// -------------------------------------------------------------------------------------------------
// MARK: - XMLParser
// -------------------------------------------------------------------------------------------------

public protocol SwiftISYParserProtocol {
  
  ///
  /// Creates an instance of this class from an XML parser when an element is encountered.
  ///
  /// - Parameter elementName: Name for this XML element.
  /// - Parameter attributes: Attributes for this XML element.
  ///
  init(elementName: String, attributes: [String: String])

  ///
  /// Updates this object once the XML parser completes processing an element.
  ///
  /// - Parameter elementName: Name for this XML element.
  /// - Parameter attributes: Attributes for this XML element.
  /// - Parameter text: Text for this XML element.  Maybe be an empty string.
  ///
  func update(elementName: String, attributes: [String: String], text: String)
  
}
