//
//  URLSession+Stub.swift
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

public class SwizzledURLSessionDataTask: URLSessionDataTask {
  
  public static var taskHandler: ((_ request: URLRequest) -> (Data?, URLResponse?, Error?))? {
    get { return _taskHandler }
    set { _taskHandler = newValue }
  }
  public static var _taskHandler: ((_ request: URLRequest) -> (Data?, URLResponse?, Error?))?
  
  fileprivate var _request: URLRequest
  fileprivate var _completionHandler: (Data?, URLResponse?, Error?) -> Void
  
  public init(request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
    _request = request
    _completionHandler = completionHandler
  }
  
  public override func resume() {
    guard let taskHandler = type(of: self).taskHandler else { return }
    let (data, response, error) = taskHandler(_request);
    DispatchQueue.main.async() {
      self._completionHandler(data, response, error)
    }
  }
  
  public override var originalRequest: URLRequest? {
    return _request
  }
  
}

extension URLSession {
  
  open override class func initialize() {
    guard self == URLSession.self else { return }
    let closure: () = {
      URLSession().swizzleDataTask()
    }()
    closure
  }
  
  private func swizzleDataTask() {
    let originalSelector = #selector((URLSession.dataTask(with:completionHandler:)) as (URLSession) -> (URLRequest, @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask)
    let swizzledSelector = #selector((URLSession.swizzledDataTask(with:completionHandler:)) as (URLSession) -> (URLRequest, @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask)
    let originalMethod = class_getInstanceMethod(URLSession.self, originalSelector)
    let swizzledMethod = class_getInstanceMethod(URLSession.self, swizzledSelector)
    let flag = class_addMethod(URLSession.self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
    if flag {
      class_replaceMethod(URLSession.self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
    } else {
      method_exchangeImplementations(originalMethod, swizzledMethod)
    }
  }
  
  @objc fileprivate func swizzledDataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask {
    return SwizzledURLSessionDataTask(request: request, completionHandler: completionHandler)
  }
  
}
