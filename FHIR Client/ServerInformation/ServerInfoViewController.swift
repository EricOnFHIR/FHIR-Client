//
//  ServerInfoViewController.swift
//  FHIR Client
//
//  Created by Eric Martin on 1/26/19.
//  Copyright © 2019 Eric Martin. All rights reserved.
//

import Cocoa
import SystemConfiguration

class ServerInfoViewController: NSViewController {
  
  @IBOutlet weak var serverBaseUrlTextField: NSTextField!
  var serverBaseUrl = ""
  var oldServerBaseUrl = ""
  
  override func viewDidLoad() {
    super.viewDidLoad()    
  }

  override func viewWillAppear() {
    super.viewWillAppear()
    
    oldServerBaseUrl = serverBaseUrl
    serverBaseUrlTextField.stringValue = serverBaseUrl
  }
  
  @IBAction func SaveButtonClick(_ sender: Any) {
    let url = serverBaseUrlTextField.stringValue
    
    if (!checkValidUrl(url: url)) {
      let alert = NSAlert.init()
      alert.messageText = "URL is not valid"
      alert.informativeText = "The URL is not a valid URL"
      alert.addButton(withTitle: "OK")
      alert.runModal()
    }
    else {
      serverBaseUrl = url
      NSApplication.shared.stopModal()
    }
    
  }
  
  @IBAction func CancelButtonClick(_ sender: Any) {
    serverBaseUrl = oldServerBaseUrl
    NSApplication.shared.stopModal()
  }
  
  @IBAction func TestButtonClick(_ sender: Any) {
    let url = serverBaseUrlTextField.stringValue
    
    
    if (checkValidUrl(url: url)) {
      if (checkNetworkAccess()) {
        let alert = NSAlert.init()
        alert.messageText = "URL is valid"
        alert.informativeText = "The URL is a valid URL and is active"
        alert.addButton(withTitle: "OK")
        alert.runModal()
      }
      else {
        let alert = NSAlert.init()
        alert.messageText = "URL is valid"
        alert.informativeText = "The URL is a valid URL but does not appear to be active"
        alert.addButton(withTitle: "OK")
        alert.runModal()
      }
    }
    else {
      let alert = NSAlert.init()
      alert.messageText = "URL is not valid"
      alert.informativeText = "The URL is not a valid URL"
      alert.addButton(withTitle: "OK")
      alert.runModal()
    }

  }
  
  func checkValidUrl(url: String) -> Bool {
    var isValidUrl = false
    let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    if let match = detector.firstMatch(in: url, options: [], range: NSRange(location: 0, length: url.endIndex.encodedOffset)) {
      isValidUrl = match.range.length == url.endIndex.encodedOffset
    }
    
    return isValidUrl
  }
  
  func checkNetworkAccess() -> Bool {
    var reachable = false
    
    if let reachability = SCNetworkReachabilityCreateWithName(nil, "http://localhost:4343/FHIRServer/") {
      var flags = SCNetworkReachabilityFlags()
      SCNetworkReachabilityGetFlags(reachability, &flags)
      reachable = isNetworkReachable(with: flags)
    }
    
    return reachable
  }
  
  func isNetworkReachable(with flags: SCNetworkReachabilityFlags) -> Bool {
    let isReachable = flags.contains(.reachable)
    let needsConnection = flags.contains(.connectionRequired)
    let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
    let canConnectWithoutUserInteraction = canConnectAutomatically && !flags.contains(.interventionRequired)
    
    return isReachable && (!needsConnection || canConnectWithoutUserInteraction)
  }
  
}
