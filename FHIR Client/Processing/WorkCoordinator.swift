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
  private let dateFormatter: DateFormatter
  
  init(completionDelegate: CompletionDelegate) {
    self.completionDelegate = completionDelegate
    self.dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

    super.init()
  }
  
  func doWork(endPoint: String) {
    var worker : QueryWorker? = nil
    
    print("Ready to start and make request")
    workersLock.lock()
    worker = findWorker()
    print("Found worker: \(worker!.name!) and putting them to use at: \(dateFormatter.string(from: Date.init()))")
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
    
    for worker in workers {
      if (!worker.isClaimed()) {
        worker.claim()
        queryWorker = worker
        break
      }
    }
    
    guard queryWorker != nil else {
      let worker = QueryWorker.init(identifier: "Query Thread #\(workers.count)", completionDelegate: self)
      workers.append(worker)
      worker.claim()
      queryWorker = worker
      return queryWorker
    }
    
    return queryWorker
  }
  
  func responseReceived(worker: QueryWorker, duration: Double, response: HTTPURLResponse, data: String) {
    worker.unclaim()
    print("Received Callback in Work Coordinator")
    completionDelegate!.responseReceived(worker: worker, duration: duration, response: response, data: data)
  }
  
}
