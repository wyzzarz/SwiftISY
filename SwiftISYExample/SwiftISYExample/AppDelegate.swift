//
//  AppDelegate.swift
//  SwiftISYExample
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

import UIKit
import SwiftISY

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
    print("Using \(SwiftISY.name).")

    // handle passwords
    SwiftISYHost.providePassword { (host) -> String in
      return "your password"
    }
    do {
      let host = SwiftISYHost(host: "your host", user: "your username")
      try SwiftISYController.sharedInstance.hosts.register(host)
      try SwiftISYController.sharedInstance.hosts.add(host)
    } catch let error {
      print(error)
    }

    return true
  }
  
}
