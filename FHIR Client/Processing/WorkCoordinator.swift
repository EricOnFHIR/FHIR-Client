//
//  WorkCoordinator.swift
//  FHIR Client
//
//  Created by Eric Martin on 12/15/18.
//  Copyright © 2018 Eric Martin. All rights reserved.
//

import Cocoa

class WorkCoordinator: NSObject, CompletionDelegate {
  private var workers = [QueryWorker]()
  private let workersLock = NSLock.init()
  private var continueWorking = true
  private weak var completionDelegate : CompletionDelegate?
  
  init(completionDelegate: CompletionDelegate) {
    self.completionDelegate = completionDelegate
    
    super.init()
  }
  
  func doWork(endPoint: String) {
    var worker : QueryWorker? = nil
    
    print("Ready to start and make request")
    worker = findWorker()
    worker!.endPoint = endPoint
    
    if (worker!.isExecuting) {
      worker!.resumeWork.signal()
    }
    else {
      worker!.start()
    }
    workersLock.unlock()
    print("The request was made")
    
  }
  
  private func findWorker() -> QueryWorker? {
    var queryWorker : QueryWorker? = nil
    
    workersLock.lock()
    for worker in workers {
      if (!worker.isClaimed()) {
        worker.claim()
        queryWorker = worker
        break
      }
    }
    
    guard queryWorker != nil else {
      queryWorker = QueryWorker.init(identifier: "Query Thread #\(workers.count)", completionDelegate: self)
      workers.append(queryWorker!)
      workersLock.unlock()
      return queryWorker
    }
    workersLock.unlock()
    
    return queryWorker
  }
  
  func responseReceived(worker: QueryWorker, response: HTTPURLResponse, data: String) {
    worker.unclaim()
    print("Received Callback in Work Coordinator")
    completionDelegate!.responseReceived(worker: worker, response: response, data: data)
  }
  
}
