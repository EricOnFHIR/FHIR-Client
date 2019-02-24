//
//  QueryWorker.swift
//  FHIR Client
//
//  Created by Eric Martin on 12/16/18.
//  Copyright © 2018 Eric Martin. All rights reserved.
//

import Cocoa

class QueryWorker: Thread {
  private var queryRequest : QueryRequest
  private let querySemaphore = DispatchSemaphore(value: 0)
  public var continueWork = true
  public let resumeWork = NSCondition.init()
  public var endPoint: String
  private var Claimed = false
  private weak var completionDelegate : CompletionDelegate?
  
  init(identifier: String, completionDelegate: CompletionDelegate) {
    endPoint = ""
    self.completionDelegate = completionDelegate

    print("Create worker: \(identifier)")
    queryRequest  = QueryRequest.init(semaphore: querySemaphore)
    print("Created request")
    
    super.init();
    self.name = identifier
  }
  
  override func main() {
    
    while (continueWork) {
      print("Ready to start and make request")
      let startTime = Date.init()
      queryRequest.MakeRequest(endPoint: self.endPoint)
      print("Waiting")
      querySemaphore.wait()
      let stopTime = Date.init()
      print("Done waiting")
      let duration = stopTime.timeIntervalSince(startTime)
      print("Duration: \(duration.magnitude)")
      completionDelegate?.responseReceived(worker: self, duration: duration, response: queryRequest.Response as! HTTPURLResponse, data: queryRequest.ResponseString)
      
      resumeWork.wait()
    }
    
  }
  
  func isClaimed() -> Bool {
    return Claimed
  }
  
  func claim() {
    Claimed = true
  }
  
  func unclaim() {
    Claimed = false
  }
  
}
