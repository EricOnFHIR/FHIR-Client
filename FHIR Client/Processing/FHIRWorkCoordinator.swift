//
//  FHIRWorkCoordinator.swift
//  FHIR Client
//
//  Created by Eric Martin on 12/15/18.
//  Copyright © 2018 Eric Martin. All rights reserved.
//

import Cocoa

class FHIRWorkCoordinator: NSObject, CompletionDelegate {
  private var workers = [FHIRWorker]()
  private let workersLock = NSLock.init()
  private var continueWorking = true
  private weak var completionDelegate : CompletionDelegate?
  
  init(completionDelegate: CompletionDelegate) {
    self.completionDelegate = completionDelegate

    super.init()
  }
  
  func doWork(endPoint: String) {
    var worker : FHIRWorker? = nil
    
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
  
  private func findWorker() -> FHIRWorker? {
    var worker : FHIRWorker? = nil
    
    workersLock.lock()
    for fhirWorker in workers {
      if (!fhirWorker.isClaimed()) {
        worker = fhirWorker
        worker!.claim()
        break
      }
    }
    
    guard worker != nil else {
      worker = FHIRWorker.init(completionDelegate: self)
      workers.append(worker!)
      worker?.name = "Query Thread #\(workers.count)"
      workersLock.unlock()
      return worker
    }
    workersLock.unlock()

    return worker
  }
  
  func responseReceived(worker: QueryWorker, response: HTTPURLResponse, data: String) {
    worker.unclaim()
    print("Received Callback in FHIR Work Coordinator")
    completionDelegate!.responseReceived(worker: worker, response: response, data: data)
  }

}
