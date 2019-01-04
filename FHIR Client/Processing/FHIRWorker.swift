//
//  FHIRWorker.swift
//  FHIR Client
//
//  Created by Eric Martin on 12/16/18.
//  Copyright © 2018 Eric Martin. All rights reserved.
//

import Cocoa

class FHIRWorker: Thread {
  private var queryRequest : QueryRequest
  private let querySemaphore = DispatchSemaphore(value: 0)
  public var continueWork = true
  public let resumeWork = NSCondition.init()
  public var endPoint : String
  private var Claimed = false
  private weak var completionDelegate : CompletionDelegate?

  init(completionDelegate: CompletionDelegate) {
    endPoint = ""
    self.completionDelegate = completionDelegate
    
    print("Create worker")
    queryRequest  = QueryRequest.init(semaphore: querySemaphore)
    print("Created request")
    
    super.init();
  }

  override func main() {
    
    while (continueWork) {
      print("Ready to start and make request")
      queryRequest.MakeRequest(endPoint: "http://localhost:4343/FHIRServer/Patient/3341/Allergy?_include=AllergyIntolerance:patient")
      print("Waiting")
      querySemaphore.wait()
      print("Done waiting")
      Thread.sleep(forTimeInterval: 1.0)
//      completionDelegate?.responseReceived(worker: self, response: queryRequest.Response as! HTTPURLResponse, data: queryRequest.ResponseString)
      
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
